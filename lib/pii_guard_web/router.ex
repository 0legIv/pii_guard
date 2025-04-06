defmodule PiiGuardWeb.Router do
  use PiiGuardWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PiiGuardWeb do
    pipe_through :api

    # Health check endpoint
    get "/health", HealthController, :check

    # Data update webhook endpoint
    post "/data-updates", DataUpdateController, :handle_update
  end
end
