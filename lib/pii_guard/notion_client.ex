defmodule PiiGuard.NotionClient do
  @moduledoc """
  Client for interacting with the Notion API.
  """

  require Logger

  @notion_api_url "https://api.notion.com/v1"
  @notion_version "2022-06-28"

  @doc """
  Retrieves information about a specific database.

  ## Parameters
    - database_id: The ID of the Notion database to retrieve

  ## Returns
    - `{:ok, database}` on success
    - `{:error, reason}` on failure
  """
  def get_database(database_id) do
    headers = [
      {"Authorization", "Bearer #{notion_api_key()}"},
      {"Notion-Version", @notion_version},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get("#{@notion_api_url}/databases/#{database_id}", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, database} ->
            Logger.info("Retrieved database: #{database_id}")
            {:ok, database}

          {:error, reason} ->
            Logger.error("Failed to decode Notion API response: #{inspect(reason)}")
            {:error, :decode_error}
        end

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Notion API error: #{status_code} - #{body}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Failed to call Notion API: #{inspect(reason)}")
        {:error, :request_error}
    end
  end

  @doc """
  Retrieves information about a specific page.

  ## Parameters
    - page_id: The ID of the Notion page to retrieve

  ## Returns
    - `{:ok, page}` on success
    - `{:error, reason}` on failure
  """
  def get_page(page_id) do
    headers = [
      {"Authorization", "Bearer #{notion_api_key()}"},
      {"Notion-Version", @notion_version},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get("#{@notion_api_url}/pages/#{page_id}", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, page} ->
            Logger.info("Retrieved page: #{page_id}")
            {:ok, page}

          {:error, reason} ->
            Logger.error("Failed to decode Notion API response: #{inspect(reason)}")
            {:error, :decode_error}
        end

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Notion API error: #{status_code} - #{body}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Failed to call Notion API: #{inspect(reason)}")
        {:error, :request_error}
    end
  end

  @doc """
  Updates a page to remove content containing PII.

  ## Parameters
    - page_id: The ID of the Notion page to update
    - properties: The properties to update

  ## Returns
    - `{:ok, page}` on success
    - `{:error, reason}` on failure
  """
  def update_page(page_id, properties) do
    headers = [
      {"Authorization", "Bearer #{notion_api_key()}"},
      {"Notion-Version", @notion_version},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        "properties" => properties
      })

    case HTTPoison.patch("#{@notion_api_url}/pages/#{page_id}", body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, page} ->
            Logger.info("Updated page: #{page_id}")
            {:ok, page}

          {:error, reason} ->
            Logger.error("Failed to decode Notion API response: #{inspect(reason)}")
            {:error, :decode_error}
        end

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Notion API error: #{status_code} - #{body}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Failed to call Notion API: #{inspect(reason)}")
        {:error, :request_error}
    end
  end

  @doc """
  Retrieves information about a specific user.

  ## Parameters
    - user_id: The ID of the Notion user to retrieve

  ## Returns
    - `{:ok, user}` on success
    - `{:error, reason}` on failure
  """
  def get_user(user_id) do
    headers = [
      {"Authorization", "Bearer #{notion_api_key()}"},
      {"Notion-Version", @notion_version},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get("#{@notion_api_url}/users/#{user_id}", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, user} ->
            Logger.info("Retrieved user: #{user_id}")
            {:ok, user}

          {:error, reason} ->
            Logger.error("Failed to decode Notion API response: #{inspect(reason)}")
            {:error, :decode_error}
        end

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("Notion API error: #{status_code} - #{body}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Failed to call Notion API: #{inspect(reason)}")
        {:error, :request_error}
    end
  end

  defp notion_api_key do
    case Application.get_env(:pii_guard, :notion_api_key) do
      nil ->
        raise "NOTION_API_KEY environment variable is not set"

      token ->
        token
    end
  end
end
