defmodule PiiGuardWeb.HealthController do
  use PiiGuardWeb, :controller

  @doc """
  Returns the health status of the application.
  """
  def check(conn, _params) do
    # Get the health status from the health module
    status = PiiGuard.Health.check()

    # Return the status as JSON
    json(conn, status)
  end
end
