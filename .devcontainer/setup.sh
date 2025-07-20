#!/bin/bash

# Install Ruby dependencies
bundle install

# Install dummy app dependencies  
cd spec/dummy && bundle install && cd ../..

# Pull official MCP Docker images
docker pull mcp/fetch
docker pull mcp/filesystem  
docker pull mcp/git
docker pull mcp/memory
docker pull mcp/time
docker pull mcp/sequentialthinking

# Install GitHub MCP server using Docker
docker pull ghcr.io/github/github-mcp-server:latest


echo "MCP servers installation completed!"