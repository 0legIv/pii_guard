# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pii_guard,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :pii_guard, PiiGuardWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: PiiGuardWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PiiGuard.PubSub,
  live_view: [signing_salt: "N+7k5Ry+"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Slack
config :pii_guard, PiiGuard.SlackBot,
  app_token: System.get_env("SLACK_APP_TOKEN"),
  bot_token: System.get_env("SLACK_BOT_TOKEN"),
  user_token: System.get_env("SLACK_USER_TOKEN"),
  bot: PiiGuard.SlackBot,
  channels: [
    types: ["public_channel"]
  ],
  # List of channels to monitor for PII (comma-separated)
  monitored_channels: System.get_env("MONITORED_CHANNELS", "")

config :openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: System.get_env("OPENAI_API_KEY"),
  # find it at https://platform.openai.com/account/org-settings under "Organization ID"
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
  # optional, use when required by an OpenAI API beta, e.g.:
  beta: "assistants=v1",
  # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
  http_options: [recv_timeout: 30_000]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
