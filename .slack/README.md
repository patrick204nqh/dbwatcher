# Slack Integration Setup

Slack bot integration for DB Watcher CI/CD pipeline notifications.

## Quick Setup

### Option 1: Using App Manifest (Recommended)

1. Go to https://api.slack.com/apps
2. Click **"Create New App"** → **"From an app manifest"**
3. Select your workspace
4. Copy the contents of `.slack/app-manifest.json` and paste it
5. Click **"Next"** → **"Create"**
6. Go to **"Install App"** → **"Install to Workspace"**
7. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)

**Optional: Add Custom App Icon**
8. Go to **"Basic Information"** → **"Display Information"**
9. Click **"Add App Icon"** and upload a 512x512px PNG icon

### Option 2: Manual Setup

1. Go to https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. Name: "DB Watcher CICD"
4. Select your workspace
5. Go to **"OAuth & Permissions"** in sidebar
6. Under **"Bot Token Scopes"**, add:
   - `chat:write` (send messages)
   - `chat:write.public` (write to public channels)
7. Click **"Install to Workspace"**
8. Copy the **"Bot User OAuth Token"**

## Channel Setup

1. Create or use existing channel: `#cicd-notifications`
2. Invite the bot to the channel:
   ```
   /invite @DB Watcher CICD
   ```
3. Get the channel ID:
   - Right-click channel → View channel details → Copy channel ID
   - Should look like: `C1234567890`

## GitHub Repository Setup

### Add Required Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions**

1. **SLACK_BOT_TOKEN**
   - Name: `SLACK_BOT_TOKEN`
   - Value: Your bot token from step 7/8 above (`xoxb-...`)

2. **SLACK_CHANNEL_ID**
   - Name: `SLACK_CHANNEL_ID`
   - Value: Your channel ID (`C1234567890`)

## Testing

### Test CI Notifications

```bash
# Create a test branch
git checkout -b test-slack
git push origin test-slack
```

This will trigger CI and send a Slack notification.

### Manual Test

Go to **Actions** → **CI** → **Run workflow** to test manually.

## What You'll Get

- ✅ Success/failure notifications for CI runs
- 🚀 Release notifications
- 📊 Status information with links to GitHub Actions
- 🔗 Interactive buttons to view details

## Configuration

The Slack integration is configured through:

- **`.slack/app-manifest.json`** - Slack app configuration for easy setup
- **GitHub workflow files** - `.github/workflows/ci.yml` and `.github/workflows/release.yml`
- **GitHub repository secrets** - `SLACK_BOT_TOKEN` and `SLACK_CHANNEL_ID`

## Workflow Integration

The existing GitHub workflows in `.github/workflows/` are already configured to send notifications:

- **CI Workflow** (`ci.yml`) - Sends notifications on push and pull request events
- **Release Workflow** (`release.yml`) - Sends notifications for releases

No additional workflow changes are needed.

## Troubleshooting

### No messages received
- Check bot is invited to channel: `/invite @DB Watcher CICD`
- Verify channel ID is correct (use ID like `C1234567890`, not channel name)
- Ensure bot token is valid and saved in GitHub secrets

### Permission errors
- Verify bot has `chat:write` and `chat:write.public` scopes
- Re-install the app if scopes were added after installation

### Messages look wrong
- Check GitHub Actions logs for errors
- Verify both secrets are configured correctly
- Test with the manual workflow trigger first

### Quick Debug

Add this to a workflow to debug:

```yaml
- name: Debug Slack Setup
  run: |
    echo "Channel ID exists: ${{ secrets.SLACK_CHANNEL_ID != '' }}"
    echo "Bot token exists: ${{ secrets.SLACK_BOT_TOKEN != '' }}"

- name: Test Slack Message
  uses: slackapi/slack-github-action@v2.0.0
  with:
    token: ${{ secrets.SLACK_BOT_TOKEN }}
    payload: |
      {
        "channel": "${{ secrets.SLACK_CHANNEL_ID }}",
        "text": "Test message from DB Watcher"
      }
```

## Security Notes

- Never commit bot tokens to the repository
- Use GitHub repository secrets for sensitive data
- Regularly rotate bot tokens following security best practices
- Bot permissions are limited to minimum required scopes (`chat:write`, `chat:write.public`)
- `.github/workflows/release.yml`
