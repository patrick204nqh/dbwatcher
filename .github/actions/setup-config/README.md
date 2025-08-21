# Setup Configuration Action

This composite action loads and parses the central configuration from `.github/config.yml` and makes all configuration values available as action outputs.

## Usage

```yaml
- name: Load Configuration
  id: config
  uses: ./.github/actions/setup-config

- name: Use configuration values
  run: |
    echo "Ruby version: ${{ steps.config.outputs.ruby-default }}"
    echo "Test timeout: ${{ steps.config.outputs.timeout-test }}"
```

## Inputs

| Input         | Description         | Required | Default              |
| ------------- | ------------------- | -------- | -------------------- |
| `config-path` | Path to config file | false    | `.github/config.yml` |

## Outputs

| Output                        | Description                             |
| ----------------------------- | --------------------------------------- |
| `ruby-versions`               | Available Ruby versions as JSON array   |
| `ruby-default`                | Default Ruby version                    |
| `timeout-test`                | Test timeout in seconds                 |
| `timeout-security`            | Security scan timeout in seconds        |
| `timeout-quality`             | Quality check timeout in seconds        |
| `timeout-compatibility`       | Compatibility check timeout in seconds  |
| `coverage-threshold`          | Coverage percentage threshold           |
| `slack-channel-ci`            | Slack channel for CI notifications      |
| `slack-channel-releases`      | Slack channel for release notifications |
| `slack-bot-token-secret`      | Secret name for Slack bot token         |
| `github-app-id-secret`        | Secret name for GitHub app ID           |
| `github-private-key-secret`   | Secret name for GitHub private key      |
| `feature-coverage-upload`     | Whether to upload coverage reports      |
| `feature-security-scan`       | Whether to run security scans           |
| `feature-quality-check`       | Whether to run quality checks           |
| `feature-slack-notifications` | Whether to send Slack notifications     |
