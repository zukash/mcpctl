# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`mcpctl` is a bash-based MCP (Model Context Protocol) Configuration Controller that manages MCP server configurations across different AI clients like Claude Code and GitHub Copilot. The tool allows centralized configuration management through JSON config files that can be applied to multiple target applications.

## Key Commands

### Testing
```bash
# Run all tests (requires bats-core, jq, and gettext)
./tests/run_tests.sh

# Run individual test files
bats tests/test_basic.bats
bats tests/test_apply.bats
bats tests/test_diff.bats
bats tests/test_errors.bats
```

### Usage
```bash
# Make the script executable
chmod +x ./mcpctl

# Apply configuration from config file
./mcpctl apply -f example/mcp.json -e .env

# Show differences between config and target files
./mcpctl diff -f example/mcp.json

# Show help
./mcpctl -h
```

## Architecture

### Core Components
- **mcpctl**: Main bash script executable that handles command parsing, configuration loading, and file operations
- **Configuration Files**: JSON files defining MCP server configurations and target file mappings
- **Target System**: Maps MCP servers to different client configuration files (Claude Code, GitHub Copilot, etc.)

### Configuration Structure
Configuration files contain:
- `targets[]`: Array of target files to update with paths and keys
- `mcpServers`: MCP server definitions with commands, arguments, and environment variables

### Key Features
- Environment variable substitution using `envsubst`
- Multiple target file support with different JSON key mappings
- Path expansion (tilde `~` support)
- Unified diff and apply operations
- Dependency validation (jq, envsubst)

## Dependencies

Required system tools:
- `jq`: JSON processing
- `envsubst`: Environment variable substitution (from gettext package)
- `bats-core`: For running tests

Install on macOS:
```bash
brew install jq gettext bats-core
```

## File Structure

- `mcpctl`: Main executable bash script
- `example/mcp.json`: Example configuration file showing target mappings and MCP server definitions
- `tests/`: BATS test suite with fixtures
- `tests/fixtures/`: Test configuration files and targets

## Configuration Examples

The example configuration shows how to:
- Configure filesystem MCP server with environment variable paths
- Set up GitHub MCP server with token authentication
- Target multiple client configuration files with different JSON key structures
- Use environment variables for sensitive data like tokens and paths