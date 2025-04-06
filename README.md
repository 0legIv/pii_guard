# PiiGuard

PiiGuard is an Elixir application that monitors Slack channels for Personally Identifiable Information (PII) and automatically deletes messages containing PII.

## Features

- Monitors specified Slack channels for PII
- Automatically deletes messages containing PII
- Notifies users when their messages are deleted
- Handles data updates from external services (e.g., Notion)
- Processes Notion webhooks for database changes
- Provides health check endpoint for monitoring Notion API and Slack API status

## Setup

1. Clone the repository
2. Install dependencies with `mix deps.get`
3. Create a `.env` file with the following variables:
   ```
   SLACK_BOT_TOKEN=xoxb-your-bot-token
   SLACK_USER_TOKEN=xoxp-your-user-token
   SLACK_APP_TOKEN=xapp-your-app-token
   MONITORED_CHANNELS=channel1,channel2,channel3
   NOTION_API_KEY=your-notion-api-key
   OPENAI_API_KEY=your-openai-api-key
   OPENAI_ORGANIZATION_KEY=your-openai-organization-key
   ```
4. Start the application with `mix phx.server`

## Configuration

### Slack Configuration

- `SLACK_BOT_TOKEN`: The bot token for the Slack bot (required for sending notifications)
- `SLACK_USER_TOKEN`: The user token for the Slack bot (required for deleting messages)
- `SLACK_APP_TOKEN`: The app token for the Slack app (required for socket mode)
- `MONITORED_CHANNELS`: A comma-separated list of channels to monitor (leave empty to monitor all channels)

### Notion Configuration

- `NOTION_API_KEY`: The API key for the Notion integration

### OpenAI Configuration

- `OPENAI_API_KEY`: The API key for OpenAI (required for PII detection)
- `OPENAI_ORGANIZATION_KEY`: The organization key for OpenAI (required for API access)

## API Endpoints

### Health Check

- `GET /health`: Returns health status of the Notion API and Slack API components
  - Response format:
    ```json
    {
      "status": "ok",
      "components": {
        "notion_api": {
          "status": "ok",
          "message": "Notion API is working"
        },
        "slack_api": {
          "status": "ok",
          "message": "Slack API is working"
        }
      },
      "timestamp": "2023-06-01T12:00:00Z"
    }
    ```

### Data Updates

- `POST /api/data-updates`: Webhook endpoint for receiving data updates from external services

## How It Works

1. The application monitors specified Slack channels for new messages
2. When a new message is detected, it checks if the message contains PII using OpenAI
3. If PII is detected, the message is deleted and the user is notified
4. The application also handles data updates from external services (e.g., Notion)
5. When a Notion webhook is received, it processes the update and checks for PII
6. If PII is detected, the content is deleted and the user is notified
7. The health check endpoint verifies the connection to both Notion API and Slack API

## Troubleshooting

- If the application is not monitoring channels, check that the `MONITORED_CHANNELS` environment variable is set correctly
- If the application is not receiving Notion webhooks, check that the webhook URL is correctly configured in your Notion database
- If the health check endpoint returns an error for Notion API, verify your `NOTION_API_KEY`
- If the health check endpoint returns an error for Slack API, verify your `SLACK_BOT_TOKEN`, `SLACK_USER_TOKEN`, and `SLACK_APP_TOKEN`
- If PII detection is not working, verify your `OPENAI_API_KEY` and `OPENAI_ORGANIZATION_KEY`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
