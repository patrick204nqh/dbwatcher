#!/bin/bash

# Install Ruby dependencies
bundle install

# Install dummy app dependencies  
cd spec/dummy && bundle install && cd ../..

# Install Python dependencies for MCP servers
pip3 install --user mcp

# Clone MCP servers from modelcontextprotocol repo
git clone https://github.com/modelcontextprotocol/servers.git /tmp/mcp-servers

# Install filesystem MCP server
cd /tmp/mcp-servers/src/filesystem && pip3 install --user -e .

# Install fetch MCP server  
cd /tmp/mcp-servers/src/fetch && pip3 install --user -e .

# Install git MCP server
cd /tmp/mcp-servers/src/git && pip3 install --user -e .

# Install memory MCP server
cd /tmp/mcp-servers/src/memory && pip3 install --user -e .

# Install sequential-thinking MCP server
cd /tmp/mcp-servers/src/sequential-thinking && pip3 install --user -e .

# Install time MCP server
cd /tmp/mcp-servers/src/time && pip3 install --user -e .

# Install GitHub MCP server using Docker
docker pull ghcr.io/github/github-mcp-server:latest

# Install Rails MCP server  
gem install rails-mcp-server

# Create Rails MCP config directory and projects.yml
mkdir -p ~/.config/rails-mcp
echo "dbwatcher: \"/workspaces/dbwatcher\"" > ~/.config/rails-mcp/projects.yml

echo "MCP servers installation completed!"