defmodule PiiGuardWeb.Router do
  use PiiGuardWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PiiGuardWeb do
    pipe_through :api
  end
end
