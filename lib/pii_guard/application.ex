defmodule PiiGuard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PiiGuardWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:pii_guard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PiiGuard.PubSub},
      # Start a worker by calling: PiiGuard.Worker.start_link(arg)
      # {PiiGuard.Worker, arg},
      # Start to serve requests, typically the last entry
      PiiGuardWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PiiGuard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PiiGuardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
