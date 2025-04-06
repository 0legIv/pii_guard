defmodule PiiGuard.SlackBotTest do
  use ExUnit.Case, async: true
  import Mock

  alias PiiGuard.SlackBot

  describe "handle_event/3 - new message" do
    test "deletes message and notifies user when PII is detected in a monitored channel" do
      # Mock application config
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot ->
            [bot_token: "bot-token", user_token: "user-token", monitored_channels: "general"]
        end do
        # Mock Slack.API and PiiDetector
        with_mocks([
          {Slack.API, [],
           [
             get: fn "conversations.info", "bot-token", %{channel: "C123"} ->
               {:ok, %{"channel" => %{"name" => "general"}}}
             end,
             post: fn
               "chat.delete", "user-token", %{channel: "C123", ts: "123.456"} -> {:ok, %{}}
               "chat.postMessage", "bot-token", %{channel: "U123", text: _} -> {:ok, %{}}
             end
           ]},
          {PiiGuard.PiiDetector, [], [contains_pii?: fn "sensitive data" -> {:ok, true} end]}
        ]) do
          # Test event
          event = %{
            "text" => "sensitive data",
            "channel" => "C123",
            "user" => "U123",
            "ts" => "123.456"
          }

          SlackBot.handle_event("message", event, nil)

          # Assertions (via log capture or direct function calls could be added if needed)
          assert called(
                   Slack.API.post("chat.delete", "user-token", %{channel: "C123", ts: "123.456"})
                 )

          assert called(Slack.API.post("chat.postMessage", "bot-token", :_))
        end
      end
    end

    test "ignores message from non-monitored channel" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot ->
            [bot_token: "bot-token", user_token: "user-token", monitored_channels: "general"]
        end do
        with_mock Slack.API, [],
          get: fn "conversations.info", "bot-token", %{channel: "C456"} ->
            {:ok, %{"channel" => %{"name" => "random"}}}
          end do
          event = %{"text" => "hello", "channel" => "C456", "user" => "U123", "ts" => "123.456"}
          SlackBot.handle_event("message", event, nil)
          # Ensure no deletion or notification happens
          refute called(Slack.API.post("chat.delete", :_, :_))
          refute called(Slack.API.post("chat.postMessage", :_, :_))
        end
      end
    end
  end

  describe "handle_event/3 - edited message" do
    test "deletes edited message with PII in monitored channel" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot ->
            [bot_token: "bot-token", user_token: "user-token", monitored_channels: "general"]
        end do
        with_mocks([
          {Slack.API, [],
           [
             get: fn "conversations.info", "bot-token", %{channel: "C123"} ->
               {:ok, %{"channel" => %{"name" => "general"}}}
             end,
             post: fn
               "chat.delete", "user-token", %{channel: "C123", ts: "123.456"} ->
                 {:ok, %{}}

               "chat.postMessage", "bot-token", %{channel: "U123", text: _text} ->
                 {:ok, %{}}
             end
           ]},
          {PiiGuard.PiiDetector, [],
           [contains_pii?: fn "edited sensitive data" -> {:ok, true} end]}
        ]) do
          event = %{
            "subtype" => "message_changed",
            "message" => %{"text" => "edited sensitive data", "user" => "U123", "ts" => "123.456"},
            "channel" => "C123"
          }

          SlackBot.handle_event("message", event, nil)

          assert called(
                   Slack.API.post("chat.delete", "user-token", %{channel: "C123", ts: "123.456"})
                 )
        end
      end
    end
  end

  describe "handle_event/3 - thread reply" do
    test "deletes thread reply with PII in monitored channel" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot ->
            [bot_token: "bot-token", user_token: "user-token", monitored_channels: "general"]
        end do
        with_mocks([
          {Slack.API, [],
           [
             get: fn "conversations.info", "bot-token", %{channel: "C123"} ->
               {:ok, %{"channel" => %{"name" => "general"}}}
             end,
             post: fn
               "chat.delete", "user-token", %{channel: "C123", ts: "123.456"} ->
                 {:ok, %{}}

               "chat.postMessage", "bot-token", %{channel: "U123", text: _text} ->
                 {:ok, %{}}
             end
           ]},
          {PiiGuard.PiiDetector, [],
           [contains_pii?: fn "thread sensitive data" -> {:ok, true} end]}
        ]) do
          event = %{
            "text" => "thread sensitive data",
            "channel" => "C123",
            "user" => "U123",
            "thread_ts" => "123.000",
            "ts" => "123.456"
          }

          SlackBot.handle_event("message", event, nil)

          assert called(
                   Slack.API.post("chat.delete", "user-token", %{channel: "C123", ts: "123.456"})
                 )
        end
      end
    end
  end

  describe "send_pii_notification/3" do
    test "sends notification to user about PII deletion" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot -> [bot_token: "bot-token", user_token: "user-token"]
        end do
        with_mock Slack.API, [],
          post: fn "chat.postMessage", "bot-token", %{channel: "U123", text: text} ->
            assert text =~
                     "Your message in channel *general* contained Personally Identifiable Information"

            {:ok, %{}}
          end do
          SlackBot.send_pii_notification("U123", "sensitive data", "general")
          assert called(Slack.API.post("chat.postMessage", "bot-token", :_))
        end
      end
    end
  end

  describe "is_monitored_channel?/1" do
    test "returns true when channel is in monitored list" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot -> [monitored_channels: "general, random"]
        end do
        assert SlackBot.is_monitored_channel?("general") == true
      end
    end

    test "returns false when channel is not in monitored list" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot -> [monitored_channels: "general"]
        end do
        assert SlackBot.is_monitored_channel?("random") == false
      end
    end

    test "returns true for all channels when monitored_channels is empty" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot -> [monitored_channels: ""]
        end do
        assert SlackBot.is_monitored_channel?("any_channel") == true
      end
    end
  end

  describe "get_channel_name/1" do
    test "returns channel name on successful API call" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot -> [bot_token: "bot-token"]
        end do
        with_mock Slack.API, [],
          get: fn "conversations.info", "bot-token", %{channel: "C123"} ->
            {:ok, %{"channel" => %{"name" => "general"}}}
          end do
          assert SlackBot.get_channel_name("C123") == "general"
        end
      end
    end

    test "returns 'Unknown Channel' on API failure" do
      with_mock Application, [:passthrough],
        get_env: fn
          :pii_guard, PiiGuard.SlackBot -> [bot_token: "bot-token"]
        end do
        with_mock Slack.API, [],
          get: fn "conversations.info", "bot-token", %{channel: "C123"} ->
            {:error, "api_error"}
          end do
          assert SlackBot.get_channel_name("C123") == "Unknown Channel"
        end
      end
    end
  end
end
