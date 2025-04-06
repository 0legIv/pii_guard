defmodule PiiGuard.DataUpdateHandler do
  @moduledoc """
  Handles data updates from external services.
  When data is updated, this module checks for PII in the changes,
  deletes any content containing PII, and notifies the user via Slack.
  """

  require Logger

  @doc """
  Handles a data update request.

  ## Parameters
    - payload: The update payload from the external service

  ## Returns
    - `{:ok, :processed}` on success
    - `{:error, reason}` on failure
  """
  def handle_update(payload) do
    Logger.info("Received data update: #{inspect(payload)}")

    # Check if this is a Notion webhook
    if is_notion_webhook?(payload) do
      process_notion_webhook(payload)
    else
      Logger.warning("Unsupported data update format")
      {:error, :unsupported_format}
    end
  end

  @doc """
  Checks if the payload is a Notion webhook.

  ## Parameters
    - payload: The update payload

  ## Returns
    - `true` if the payload is a Notion webhook
    - `false` otherwise
  """
  def is_notion_webhook?(payload) do
    case payload do
      %{"type" => type, "data" => %{"parent" => %{"type" => "database"}}} ->
        String.starts_with?(type, "page.")

      _ ->
        false
    end
  end

  @doc """
  Processes a Notion webhook.

  ## Parameters
    - payload: The Notion webhook payload

  ## Returns
    - `{:ok, :processed}` on success
    - `{:error, reason}` on failure
  """
  def process_notion_webhook(payload) do
    Logger.info("Processing Notion webhook: #{inspect(payload)}")

    # Extract the database ID and page ID from the payload
    case extract_notion_ids(payload) do
      {:ok, database_id, page_id, user_id} ->
        process_notion_page(database_id, page_id, user_id)

      {:error, reason} ->
        Logger.error("Failed to extract Notion IDs: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Extracts database ID, page ID, and user ID from a Notion webhook.

  ## Parameters
    - payload: The Notion webhook payload

  ## Returns
    - `{:ok, database_id, page_id, user_id}` on success
    - `{:error, reason}` on failure
  """
  def extract_notion_ids(payload) do
    case payload do
      %{
        "data" => %{"parent" => %{"id" => database_id}},
        "entity" => %{"id" => page_id},
        "authors" => [%{"id" => user_id} | _]
      } ->
        {:ok, database_id, page_id, user_id}

      _ ->
        {:error, :invalid_notion_payload}
    end
  end

  @doc """
  Processes a Notion page.

  ## Parameters
    - database_id: The ID of the database
    - page_id: The ID of the page
    - user_id: The ID of the user who created/edited the page

  ## Returns
    - `{:ok, :processed}` on success
    - `{:error, reason}` on failure
  """
  def process_notion_page(database_id, page_id, user_id) do
    with {:ok, database} <- PiiGuard.NotionClient.get_database(database_id),
         {:ok, page} <- PiiGuard.NotionClient.get_page(page_id),
         {:ok, content} <- extract_page_content(page),
         {:ok, has_pii?} <- PiiGuard.PiiDetector.contains_pii?(content) do
      case has_pii? do
        true ->
          Logger.info("PII detected in Notion page: #{page_id}")
          # Delete the content containing PII
          delete_notion_content(page_id, database)
          # Notify the user via Slack
          notify_user_via_slack(user_id, content)

        false ->
          Logger.info("No PII detected in Notion page: #{page_id}")
      end

      {:ok, :processed}
    else
      {:error, reason} ->
        Logger.error("Error processing Notion page: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Extracts content from a Notion page.

  ## Parameters
    - page: The Notion page

  ## Returns
    - `{:ok, content}` on success
    - `{:error, reason}` on failure
  """
  def extract_page_content(page) do
    case page do
      %{"properties" => properties} ->
        # Extract content from properties
        content = extract_content_from_properties(properties)
        {:ok, content}

      _ ->
        {:error, :invalid_page_structure}
    end
  end

  @doc """
  Extracts content from Notion page properties.

  ## Parameters
    - properties: The properties of the Notion page

  ## Returns
    - The extracted content
  """
  def extract_content_from_properties(properties) do
    # This is a placeholder implementation that needs to be adjusted
    # based on the actual properties structure
    Enum.reduce(properties, "", fn {_key, value}, acc ->
      case value do
        %{"title" => title} ->
          title_text = extract_text_from_rich_text(title)
          acc <> title_text <> "\n"

        %{"rich_text" => rich_text} ->
          rich_text_text = extract_text_from_rich_text(rich_text)
          acc <> rich_text_text <> "\n"

        _ ->
          acc
      end
    end)
  end

  @doc """
  Extracts text from Notion rich text.

  ## Parameters
    - rich_text: The rich text from Notion

  ## Returns
    - The extracted text
  """
  def extract_text_from_rich_text(rich_text) do
    # This is a placeholder implementation that needs to be adjusted
    # based on the actual rich text structure
    Enum.reduce(rich_text, "", fn text_block, acc ->
      case text_block do
        %{"text" => %{"content" => content}} ->
          acc <> content

        _ ->
          acc
      end
    end)
  end

  @doc """
  Deletes content containing PII from a Notion page.

  ## Parameters
    - page_id: The ID of the page to delete content from
    - database: The database object

  ## Returns
    - `{:ok, :deleted}` on success
    - `{:error, reason}` on failure
  """
  def delete_notion_content(page_id, database) do
    # Create a map of properties to update
    properties = create_empty_properties(database["properties"])

    # Update the page to remove the content
    case PiiGuard.NotionClient.update_page(page_id, properties) do
      {:ok, _} ->
        Logger.info("Deleted content from Notion page: #{page_id}")
        {:ok, :deleted}

      {:error, reason} ->
        Logger.error("Failed to delete content: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Creates empty properties for a Notion page.

  ## Parameters
    - database_properties: The properties of the database

  ## Returns
    - A map of empty properties
  """
  def create_empty_properties(database_properties) do
    # This is a placeholder implementation that needs to be adjusted
    # based on the actual database structure
    Enum.reduce(database_properties, %{}, fn {key, value}, acc ->
      # Create an empty property based on the type
      empty_property =
        case value["type"] do
          "title" -> %{"title" => []}
          "rich_text" -> %{"rich_text" => []}
          "number" -> %{"number" => nil}
          "select" -> %{"select" => nil}
          "multi_select" -> %{"multi_select" => []}
          "date" -> %{"date" => nil}
          "people" -> %{"people" => []}
          "files" -> %{"files" => []}
          "checkbox" -> %{"checkbox" => false}
          "url" -> %{"url" => nil}
          "email" -> %{"email" => nil}
          "phone_number" -> %{"phone_number" => nil}
          "formula" -> %{"formula" => nil}
          "relation" -> %{"relation" => []}
          "rollup" -> %{"rollup" => nil}
          "created_time" -> %{"created_time" => nil}
          "created_by" -> %{"created_by" => nil}
          "last_edited_time" -> %{"last_edited_time" => nil}
          "last_edited_by" -> %{"last_edited_by" => nil}
          _ -> %{}
        end

      Map.put(acc, key, empty_property)
    end)
  end

  @doc """
  Notifies a user via Slack about PII in their content.

  ## Parameters
    - user_id: The user ID from the external service
    - content: The content containing PII

  ## Returns
    - `{:ok, :notified}` on success
    - `{:error, reason}` on failure
  """
  def notify_user_via_slack(user_id, content) do
    # Get the user's email from the external service
    case get_user_email(user_id) do
      {:ok, email} ->
        # Find the Slack user ID by email
        case find_slack_user_by_email(email) do
          {:ok, slack_user_id} ->
            # Send a notification to the user via Slack
            send_slack_notification(slack_user_id, content)

          {:error, reason} ->
            Logger.error("Failed to find Slack user: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Failed to get user email: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Gets a user's email from the external service.

  ## Parameters
    - user_id: The user ID from the external service

  ## Returns
    - `{:ok, email}` on success
    - `{:error, reason}` on failure
  """
  def get_user_email(user_id) do
    case PiiGuard.NotionClient.get_user(user_id) do
      {:ok, user} ->
        # Extract the email from the user object
        # This is a placeholder implementation that needs to be adjusted
        # based on the actual user object structure
        case user do
          %{"person" => %{"email" => email}} ->
            {:ok, email}

          _ ->
            {:error, :email_not_found}
        end

      {:error, reason} ->
        Logger.error("Failed to get user: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Finds a Slack user ID by email.

  ## Parameters
    - email: The user's email

  ## Returns
    - `{:ok, slack_user_id}` on success
    - `{:error, reason}` on failure
  """
  def find_slack_user_by_email(email) do
    # Use the Slack API to find a user by email
    case Slack.API.get(
           "users.lookupByEmail",
           Application.get_env(:pii_guard, PiiGuard.SlackBot)[:bot_token],
           %{
             email: email
           }
         ) do
      {:ok, %{"user" => %{"id" => user_id}}} ->
        {:ok, user_id}

      {:ok, _} ->
        {:error, :user_not_found}

      {:error, error} ->
        Logger.error("Failed to find Slack user: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Sends a notification to a user via Slack.

  ## Parameters
    - slack_user_id: The Slack user ID
    - content: The content containing PII

  ## Returns
    - `{:ok, :notified}` on success
    - `{:error, reason}` on failure
  """
  def send_slack_notification(slack_user_id, content) do
    notification = """
    Your content contained Personally Identifiable Information (PII) and has been deleted:

    > #{content}

    Please recreate your content without any PII.
    """

    # Send a direct message to the user using Slack.API
    case Slack.API.post(
           "chat.postMessage",
           Application.get_env(:pii_guard, PiiGuard.SlackBot)[:bot_token],
           %{
             channel: slack_user_id,
             text: notification
           }
         ) do
      {:ok, _} ->
        Logger.info("Notification sent to Slack user #{slack_user_id}")
        {:ok, :notified}

      {:error, error} ->
        Logger.error("Failed to send notification: #{inspect(error)}")
        {:error, error}
    end
  end
end
