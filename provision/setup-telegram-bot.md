# Setting Up a Telegram Bot

Your OpenClaw agent needs a Telegram bot to communicate with you. Here's how to create one.

## Step 1: Create the Bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Choose a display name (e.g., "My Agent")
4. Choose a username (must end in `bot`, e.g., `my_agent_bot`)
5. BotFather will give you a **bot token** — save this!

## Step 2: Get Your Telegram User ID

You need your numeric Telegram user ID (not your username). To find it:

1. Search for **@userinfobot** on Telegram
2. Send it any message
3. It will reply with your user ID (a number like `123456789`)

## Step 3: Configure OpenClaw

SSH into your VPS and edit the OpenClaw config:

```bash
ssh openclaw@<your-vps-ip>
nano ~/.openclaw/openclaw.json
```

Add/update the Telegram channel configuration:

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN_HERE",
      "allowedUsers": ["YOUR_USER_ID"]
    }
  }
}
```

## Step 4: Restart the Gateway

```bash
openclaw gateway restart
```

## Step 5: Start Chatting

Open Telegram, find your bot by its username, and send `/start`. Your agent should respond!

## Tips

- **`allowedUsers`** restricts who can talk to your bot. Add user IDs of people you want to have access.
- You can add the bot to group chats — it will receive all messages in groups where it's a member.
- The bot token is a secret — never share it publicly or commit it to git.
- To change the bot's profile picture: go to @BotFather → `/setuserpic`
- To add a description: @BotFather → `/setdescription`

## Group Chat Setup

To add your agent to a group:
1. Create a Telegram group (or use an existing one)
2. Add your bot as a member
3. **Important:** Go to @BotFather → `/setprivacy` → select your bot → **Disable**
   - This lets your bot see all messages in the group (not just /commands)
4. The group chat ID will be a negative number (e.g., `-1001234567890`)
   - Your agent will auto-detect it when it receives a message from the group
