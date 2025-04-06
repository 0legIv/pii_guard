defmodule PiiGuardWeb.DataUpdateController do
  use PiiGuardWeb, :controller

  require Logger

  @doc """
  Handles data update requests from external services.
  """
  def handle_update(conn, params) do
    Logger.info("Received data update request")

    # Process the update
    case PiiGuard.DataUpdateHandler.handle_update(params) do
      {:ok, :processed} ->
        send_resp(conn, :ok, "")

      {:error, reason} ->
        Logger.error("Failed to process update: #{inspect(reason)}")
        send_resp(conn, :unprocessable_entity, "Failed to process update")
    end
  end
end
