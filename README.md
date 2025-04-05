# PiiGuard

PiiGuard is an Elixir Phoenix application that monitors Slack channels for messages containing Personally Identifiable Information (PII). When PII is detected, the application automatically deletes the message and notifies the author to recreate it without PII.

## Features

- Real-time monitoring of Slack messages
- Automatic PII detection using OpenAI
- Automatic deletion of messages containing PII
- User notifications about deleted messages
- Configurable channel monitoring

## Setup

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- Slack workspace with admin access
- OpenAI API key

### Installation

1. Clone the repository
2. Install dependencies:
   ```
   mix deps.get
   ```
3. Set up environment variables:
   ```
   export SLACK_BOT_TOKEN=xoxb-your-bot-token
   export SLACK_APP_TOKEN=xapp-your-app-token
   export SLACK_USER_TOKEN=xoxp-your-user-token
   export OPENAI_API_KEY=your-openai-api-key
   export MONITORED_CHANNELS=general,random,announcements
   ```

### Slack App Configuration

1. Create a new Slack app at https://api.slack.com/apps
2. Add the following OAuth scopes:
   - `chat:write` - To send notifications
   - `chat:write.customize` - To delete messages (required for message deletion)
   - `channels:history` - To read channel messages
   - `groups:history` - To read private channel messages
   - `im:history` - To read direct messages
   - `mpim:history` - To read group direct messages
3. Install the app to your workspace
4. Copy the Bot User OAuth Token to your `SLACK_BOT_TOKEN` environment variable
5. Copy the User OAuth Token to your `SLACK_USER_TOKEN` environment variable (this token is used for deleting messages)
6. Enable Socket Mode in your Slack app settings
7. Copy the App-Level Token to your `SLACK_APP_TOKEN` environment variable
8. Add Event Subscriptions and subscribe to the following bot events:
   - `message.channels`
   - `message.groups`
   - `message.im`
   - `message.mpim`

### Channel Configuration

The `MONITORED_CHANNELS` environment variable allows you to specify which channels should be monitored for PII. It should be a comma-separated list of channel names (not IDs).

For example:
```
export MONITORED_CHANNELS=general,random,announcements
```

If `MONITORED_CHANNELS` is not set or is empty, all channels will be monitored.

### Running the Application

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## How It Works

PiiGuard uses the `slack_elixir` library to establish a WebSocket connection to Slack's Real Time Messaging API via Socket Mode. This allows the application to receive events in real-time without the need for webhooks.

When a message is sent in a channel where the bot is present, the application:
1. Receives the message event via the WebSocket connection
2. Checks if the channel name is in the list of monitored channels
3. If the channel is monitored, checks the message content for PII using OpenAI
4. If PII is detected, deletes the message and notifies the user
5. If no PII is detected, the message is left unchanged

## Troubleshooting

### Message Deletion Issues

If you see errors like `"error" => "cant_delete_message"` in the logs, it means the bot doesn't have the necessary permissions to delete messages. To fix this:

1. Go to your Slack app settings at https://api.slack.com/apps
2. Select your app
3. Go to "OAuth & Permissions"
4. Add the `chat:write.customize` scope
5. Reinstall the app to your workspace
6. Make sure you're using the User OAuth Token (starts with `xoxp-`) for the `SLACK_USER_TOKEN` environment variable

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
