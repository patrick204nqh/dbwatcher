# Custom Bot Setup: `dbwatcher-ci`

Setup guide for creating a custom GitHub App bot to replace `github-actions[bot]` in workflows.

## Quick Start

Replace generic bot with branded `dbwatcher-ci[bot]` for professional CI/CD interactions.

## 🔧 Setup Steps

### 1. Create GitHub App

1. **Go to:** [github.com/settings/apps](https://github.com/settings/apps)
2. **Click:** "New GitHub App"
3. **Configure:**

   ```
   Name: dbwatcher-ci
   Homepage: https://github.com/patrick204nqh/dbwatcher
   Description: Automated CI/CD bot for **dbwatcher**
   Webhook: Uncheck "Active"
   ```

### 2. Set Permissions

| Permission    | Level      |
| ------------- | ---------- |
| Contents      | Read/Write |
| Pull requests | Read/Write |
| Metadata      | Read       |
| Actions       | Read       |

### 3. Install & Configure

1. **Create app** → Copy App ID
2. **Generate private key** → Download `.pem`
3. **Install app** → Select this repository
4. **Add secrets:**
   - `DBWATCHER_CI_APP_ID`: Your App ID
   - `DBWATCHER_CI_PRIVATE_KEY`: Contents of `.pem` file

## 💻 Workflow Integration

### Standard Pattern

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Get bot token
    id: bot
    uses: actions/create-github-app-token@v1
    with:
      app-id: ${{ secrets.DBWATCHER_CI_APP_ID }}
      private-key: ${{ secrets.DBWATCHER_CI_PRIVATE_KEY }}

  - name: Bot actions
    env:
      GITHUB_TOKEN: ${{ steps.bot.outputs.token }}
    run: |
      gh pr comment $PR --body "Custom bot message"
      gh pr review $PR --approve
```

### Auto-merge Example

```yaml
name: Auto-merge
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Get bot token
        id: bot
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.DBWATCHER_CI_APP_ID }}
          private-key: ${{ secrets.DBWATCHER_CI_PRIVATE_KEY }}

      - name: Auto-approve
        env:
          GITHUB_TOKEN: ${{ steps.bot.outputs.token }}
        run: |
          gh pr review ${{ github.event.pull_request.number }} \
            --approve --body "Auto-approved dependency update"

      - name: Auto-merge
        env:
          GITHUB_TOKEN: ${{ steps.bot.outputs.token }}
        run: |
          gh pr merge ${{ github.event.pull_request.number }} \
            --auto --squash --delete-branch
```

## 🐛 Troubleshooting

### Token Issues

- **Error:** App token generation fails
- **Fix:** Check App ID and private key in secrets

### Permission Issues

- **Error:** Bot can't comment/approve
- **Fix:** Verify app permissions and installation

### Bot Not Showing

- **Error:** Still shows `github-actions[bot]`
- **Fix:** Ensure using `steps.bot.outputs.token`, not `secrets.GITHUB_TOKEN`

## ✅ Verification

After setup, you should see:

- `dbwatcher-ci[bot]` in PR comments
- Custom avatar in bot interactions
- Professional branded automation

## 🔐 Security Notes

- Keep `.pem` file secure
- Only grant minimal required permissions
- Regular audit of app access
- Store secrets properly in GitHub

---

**Result:** All workflow GitHub operations will use `dbwatcher-ci[bot]` instead of generic `github-actions[bot]`.
