import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/pii_guard start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :pii_guard, PiiGuardWeb.Endpoint, server: true
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :pii_guard, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :pii_guard, PiiGuardWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end

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
  monitored_channels: System.get_env("MONITORED_SLACK_CHANNELS", "")

config :pii_guard, :notion_api_key, System.get_env("NOTION_API_KEY")
config :pii_guard, :notion_verification_token, System.get_env("NOTION_VERIFICATION_TOKEN")

config :openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: System.get_env("OPENAI_API_KEY"),
  # find it at https://platform.openai.com/account/org-settings under "Organization ID"
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
  # optional, use when required by an OpenAI API beta, e.g.:
  beta: "assistants=v1",
  # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
  http_options: [recv_timeout: 30_000]
