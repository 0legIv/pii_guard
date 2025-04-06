defmodule PiiGuard.SlackBot do
  @moduledoc """
  Slack bot for monitoring messages and detecting PII.
  """

  require Logger

  # Check if a channel is in the list of monitored channels.
  def is_monitored_channel?(channel_name) do
    # Get the list of monitored channels from config
    monitored_channels =
      Application.get_env(:pii_guard, PiiGuard.SlackBot)[:monitored_channels]
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    # If no channels are specified, monitor all channels
    if Enum.empty?(monitored_channels) do
      true
    else
      # Check if the channel name is in the list of monitored channels
      channel_name in monitored_channels
    end
  end

  # Get channel name from channel ID
  def get_channel_name(channel_id) do
    case Slack.API.get(
           "conversations.info",
           Application.get_env(:pii_guard, PiiGuard.SlackBot)[:bot_token],
           %{
             channel: channel_id
           }
         ) do
      {:ok, %{"channel" => %{"name" => name}}} ->
        name

      {:ok, _} ->
        "Unknown Channel"

      {:error, error} ->
        Logger.error("Failed to get channel name: #{inspect(error)}")
        "Unknown Channel"
    end
  end

  # Handle edited message events from Slack.
  def handle_event(
        "message",
        %{
          "subtype" => "message_changed",
          "message" => %{"text" => text, "user" => user} = message,
          "channel" => channel
        },
        _slack
      ) do
    channel_name = get_channel_name(channel)

    if is_monitored_channel?(channel_name) do
      Logger.info(
        "Received edited message in monitored channel #{channel_name} (#{channel}): #{text}"
      )

      case PiiGuard.PiiDetector.contains_pii?(text) do
        {:ok, true} ->
          Logger.info("PII detected in edited message: #{text}")

          # Delete the message using Slack.API
          case Slack.API.post(
                 "chat.delete",
                 Application.get_env(:pii_guard, PiiGuard.SlackBot)[:user_token],
                 %{
                   channel: channel,
                   ts: message["ts"]
                 }
               ) do
            {:ok, _} ->
              Logger.info("Edited message deleted successfully")
              # Send notification to the user
              send_pii_notification(user, text, channel_name)

            {:error, error} ->
              Logger.error("Failed to delete edited message: #{inspect(error)}")
          end

        {:ok, false} ->
          Logger.info("No PII detected in edited message")

        {:error, reason} ->
          Logger.error("Error checking for PII: #{inspect(reason)}")
      end
    else
      channel_name = get_channel_name(channel)

      Logger.debug(
        "Ignoring edited message from non-monitored channel: #{channel_name} (#{channel})"
      )
    end
  end

  # Handle message events from Slack.
  def handle_event(
        "message",
        %{"text" => text, "channel" => channel, "user" => user} = event,
        _slack
      ) do
    channel_name = get_channel_name(channel)

    if is_monitored_channel?(channel_name) do
      Logger.info("Received message in monitored channel #{channel_name} (#{channel}): #{text}")

      case PiiGuard.PiiDetector.contains_pii?(text) do
        {:ok, true} ->
          Logger.info("PII detected in message: #{text}")

          # Delete the message using Slack.API
          case Slack.API.post(
                 "chat.delete",
                 Application.get_env(:pii_guard, PiiGuard.SlackBot)[:user_token],
                 %{
                   channel: channel,
                   ts: event["ts"]
                 }
               ) do
            {:ok, _} ->
              Logger.info("Message deleted successfully")
              # Send notification to the user
              send_pii_notification(user, text, channel_name)

            {:error, error} ->
              Logger.error("Failed to delete message: #{inspect(error)}")
          end

        {:ok, false} ->
          Logger.info("No PII detected in message")

        {:error, reason} ->
          Logger.error("Error checking for PII: #{inspect(reason)}")
      end
    else
      channel_name = get_channel_name(channel)
      Logger.debug("Ignoring message from non-monitored channel: #{channel_name} (#{channel})")
    end
  end

  # Handle thread reply events from Slack.
  def handle_event(
        "message",
        %{"text" => text, "channel" => channel, "user" => user, "thread_ts" => _thread_ts} =
          event,
        _slack
      ) do
    channel_name = get_channel_name(channel)

    if is_monitored_channel?(channel_name) do
      Logger.info(
        "Received thread reply in monitored channel #{channel_name} (#{channel}): #{text}"
      )

      case PiiGuard.PiiDetector.contains_pii?(text) do
        {:ok, true} ->
          Logger.info("PII detected in thread reply: #{text}")

          # Delete the message using Slack.API
          case Slack.API.post(
                 "chat.delete",
                 Application.get_env(:pii_guard, PiiGuard.SlackBot)[:user_token],
                 %{
                   channel: channel,
                   ts: event["ts"]
                 }
               ) do
            {:ok, _} ->
              Logger.info("Thread reply deleted successfully")
              # Send notification to the user
              send_pii_notification(user, text, channel_name)

            {:error, error} ->
              Logger.error("Failed to delete thread reply: #{inspect(error)}")
          end

        {:ok, false} ->
          Logger.info("No PII detected in thread reply")

        {:error, reason} ->
          Logger.error("Error checking for PII: #{inspect(reason)}")
      end
    else
      channel_name = get_channel_name(channel)

      Logger.debug(
        "Ignoring thread reply from non-monitored channel: #{channel_name} (#{channel})"
      )
    end
  end

  # Handle any other event types.
  def handle_event(type, payload, _slack) do
    Logger.debug("Unhandled event type: #{type}")
    Logger.debug("Payload: #{inspect(payload)}")
  end

  # Send a notification to a user about PII in their message.
  def send_pii_notification(user, message, channel_name) do
    notification = """
    Your message in channel *#{channel_name}* contained Personally Identifiable Information (PII) and has been deleted:

    > #{message}

    Please recreate your message without any PII.
    """

    # Send a direct message to the user using Slack.API
    case Slack.API.post(
           "chat.postMessage",
           Application.get_env(:pii_guard, PiiGuard.SlackBot)[:bot_token],
           %{
             channel: user,
             text: notification
           }
         ) do
      {:ok, _} ->
        Logger.info("Notification sent to user #{user}")

      {:error, error} ->
        Logger.error("Failed to send notification: #{inspect(error)}")
    end
  end
end
