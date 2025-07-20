# DevContainer

Development container for **dbwatcher** with Ruby, Node, Python and MCP servers.

## What's Included

- **Ruby 3.3** with bundler
- **Node 22** for frontend tooling
- **Python 3.11** for MCP servers
- **Git & GitHub CLI**
- **VS Code extensions**: Ruby LSP, Copilot, YAML support

## MCP Servers

Pre-configured Docker-based MCP servers:
- `mcp/fetch` - Web content retrieval
- `mcp/filesystem` - File operations
- `mcp/git` - Git repository management
- `mcp/memory` - Knowledge graph
- `mcp/time` - Time/timezone utilities
- `mcp/sequentialthinking` - Sequential reasoning
- `ghcr.io/github/github-mcp-server` - GitHub integration

## Usage

1. Open in VS Code
2. "Reopen in Container" when prompted
3. Setup script runs automatically
4. MCP servers available in Claude/Copilot chat

## Manual Setup

If needed, run setup manually from project root:
```bash
bash .devcontainer/setup.sh
```

## Ports

- `3000` - Rails development server
- `3001` - Test/dummy app server
