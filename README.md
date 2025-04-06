# PiiGuard

PiiGuard is an Elixir application that monitors Slack channels for Personally Identifiable Information (PII) and automatically deletes messages containing PII.

## Features

- Monitors specified Slack channels for PII
- Automatically deletes messages containing PII
- Notifies users when their messages are deleted
- Handles data updates from external services (e.g., Notion)
- Processes Notion webhooks for database changes
- Provides basic health check endpoint for monitoring

## Setup

1. Clone the repository
2. Install dependencies with `mix deps.get`
3. Create a `.env` file with the following variables:
   ```
   SLACK_BOT_TOKEN=xoxb-your-bot-token
   SLACK_USER_TOKEN=xoxp-your-user-token
   SLACK_SIGNING_SECRET=your-signing-secret
   MONITORED_CHANNELS=channel1,channel2,channel3
   ```
4. Start the application with `mix phx.server`

## Configuration

### Slack Configuration

- `SLACK_BOT_TOKEN`: The bot token for the Slack bot
- `SLACK_USER_TOKEN`: The user token for the Slack bot
- `SLACK_SIGNING_SECRET`: The signing secret for verifying Slack requests
- `MONITORED_CHANNELS`: A comma-separated list of channels to monitor

### Notion Configuration

- `NOTION_API_KEY`: The API key for the Notion integration

## API Endpoints

### Health Check

- `GET /api/health`: Returns basic health status of the application

### Data Updates

- `POST /api/data-updates`: Webhook endpoint for receiving data updates from external services

## How It Works

1. The application monitors specified Slack channels for new messages
2. When a new message is detected, it checks if the message contains PII
3. If PII is detected, the message is deleted and the user is notified
4. The application also handles data updates from external services (e.g., Notion)
5. When a Notion webhook is received, it processes the update and checks for PII
6. If PII is detected, the content is deleted and the user is notified

## Troubleshooting

- If the application is not monitoring channels, check that the `MONITORED_CHANNELS` environment variable is set correctly
- If the application is not receiving Notion webhooks, check that the webhook URL is correctly configured in your Notion database
- If the health check endpoint returns an error, check the logs for more information

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
