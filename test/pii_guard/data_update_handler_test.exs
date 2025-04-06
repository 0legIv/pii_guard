defmodule PiiGuard.DataUpdateHandlerTest do
  use ExUnit.Case
  import Mock

  alias PiiGuard.DataUpdateHandler
  alias PiiGuard.PiiDetector
  alias PiiGuard.NotionClient
  alias PiiGuard.SlackBot

  describe "handle_update/1" do
    test "processes Notion webhook with PII" do
      # Create a mock Notion webhook payload with PII
      payload = %{
        "type" => "page.updated",
        "data" => %{
          "parent" => %{
            "type" => "database",
            "id" => "456"
          }
        },
        "entity" => %{
          "id" => "123"
        },
        "authors" => [
          %{"id" => "789"}
        ]
      }

      # Mock the NotionClient and PiiDetector modules
      with_mocks([
        {NotionClient, [],
         [
           get_database: fn _database_id ->
             {:ok, %{"properties" => %{"Name" => %{"title" => %{}}}}}
           end,
           get_page: fn _page_id ->
             {:ok,
              %{
                "properties" => %{
                  "Name" => %{"title" => [%{"text" => %{"content" => "Test content with PII"}}]}
                }
              }}
           end,
           update_page: fn _page_id, _properties ->
             {:ok, %{"id" => "123", "properties" => %{}}}
           end,
           get_user: fn _user_id ->
             {:ok, %{"person" => %{"email" => "test@example.com"}}}
           end
         ]},
        {PiiDetector, [],
         [
           contains_pii?: fn _text -> {:ok, true} end
         ]},
        {SlackBot, [],
         [
           send_pii_notification: fn _user, _message, _channel_name ->
             {:ok, "Notification sent"}
           end
         ]}
      ]) do
        # Call the handle_update function
        result = DataUpdateHandler.handle_update(payload)

        # Check that the result is {:ok, _}
        assert {:ok, _} = result
      end
    end

    test "processes Notion webhook without PII" do
      # Create a mock Notion webhook payload without PII
      payload = %{
        "type" => "page.updated",
        "data" => %{
          "parent" => %{
            "type" => "database",
            "id" => "456"
          }
        },
        "entity" => %{
          "id" => "123"
        },
        "authors" => [
          %{"id" => "789"}
        ]
      }

      # Mock the NotionClient and PiiDetector modules
      with_mocks([
        {NotionClient, [],
         [
           get_database: fn _database_id ->
             {:ok, %{"properties" => %{"Name" => %{"title" => %{}}}}}
           end,
           get_page: fn _page_id ->
             {:ok,
              %{
                "properties" => %{
                  "Name" => %{
                    "title" => [%{"text" => %{"content" => "Test content without PII"}}]
                  }
                }
              }}
           end
         ]},
        {PiiDetector, [],
         [
           contains_pii?: fn _text -> {:ok, false} end
         ]}
      ]) do
        # Call the handle_update function
        result = DataUpdateHandler.handle_update(payload)

        # Check that the result is {:ok, _}
        assert {:ok, _} = result
      end
    end

    test "handles non-Notion webhook" do
      # Create a mock non-Notion webhook payload
      payload = %{
        "type" => "other_type",
        "id" => "123"
      }

      # Call the handle_update function
      result = DataUpdateHandler.handle_update(payload)

      # Check that the result is {:error, :unsupported_format}
      assert {:error, :unsupported_format} = result
    end
  end

  describe "is_notion_webhook?/1" do
    test "returns true for Notion webhook" do
      # Create a mock Notion webhook payload
      payload = %{
        "type" => "page.updated",
        "data" => %{
          "parent" => %{
            "type" => "database"
          }
        }
      }

      # Call the is_notion_webhook? function
      result = :erlang.apply(DataUpdateHandler, :is_notion_webhook?, [payload])

      # Check that the result is true
      assert result == true
    end

    test "returns false for non-Notion webhook" do
      # Create a mock non-Notion webhook payload
      payload = %{
        "type" => "other_type"
      }

      # Call the is_notion_webhook? function
      result = :erlang.apply(DataUpdateHandler, :is_notion_webhook?, [payload])

      # Check that the result is false
      assert result == false
    end
  end

  describe "extract_notion_ids/1" do
    test "extracts IDs from Notion webhook" do
      # Create a mock Notion webhook payload
      payload = %{
        "data" => %{
          "parent" => %{
            "id" => "456"
          }
        },
        "entity" => %{
          "id" => "123"
        },
        "authors" => [
          %{"id" => "789"}
        ]
      }

      # Call the extract_notion_ids function
      result = :erlang.apply(DataUpdateHandler, :extract_notion_ids, [payload])

      # Check that the result has the expected structure
      assert {:ok, database_id, page_id, user_id} = result
      assert database_id == "456"
      assert page_id == "123"
      assert user_id == "789"
    end
  end
end
