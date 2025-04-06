defmodule PiiGuard.Health do
  @moduledoc """
  Provides health check functionality for the application.
  """

  require Logger

  @doc """
  Checks the health of the application and its dependencies.

  ## Returns
    - A map with the health status of the application and its dependencies
  """
  def check do
    # Check the Notion API connection
    notion_status = check_notion_api()

    # Check the Slack API connection
    slack_status = check_slack_api()

    # Combine all statuses
    %{
      status: determine_overall_status([notion_status, slack_status]),
      components: %{
        notion_api: notion_status,
        slack_api: slack_status
      },
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Checks the health of the Notion API connection.

  ## Returns
    - A map with the health status of the Notion API
  """
  def check_notion_api do
    case PiiGuard.NotionClient.get_user("me") do
      {:ok, _} ->
        %{
          status: "ok",
          message: "Notion API connection is working"
        }

      {:error, reason} ->
        %{
          status: "error",
          message: "Notion API connection failed: #{inspect(reason)}"
        }
    end
  end

  @doc """
  Checks the health of the Slack API connection.

  ## Returns
    - A map with the health status of the Slack API
  """
  def check_slack_api do
    bot_token = Application.get_env(:pii_guard, PiiGuard.SlackBot)[:bot_token]

    case Slack.API.get(
           "auth.test",
           bot_token,
           %{}
         ) do
      {:ok, _} ->
        %{
          status: "ok",
          message: "Slack API connection is working"
        }

      {:error, reason} ->
        %{
          status: "error",
          message: "Slack API connection failed: #{inspect(reason)}"
        }
    end
  end

  @doc """
  Determines the overall health status based on the status of individual components.

  ## Parameters
    - component_statuses: A list of component status maps

  ## Returns
    - The overall health status
  """
  def determine_overall_status(component_statuses) do
    # Check if any component has an error status
    if Enum.any?(component_statuses, &(&1.status == "error")) do
      "error"
    else
      "ok"
    end
  end
end
