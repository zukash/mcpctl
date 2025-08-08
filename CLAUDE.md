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
bats tests/test_merge.bats
```

### Usage
```bash
# Make the script executable
chmod +x ./mcpctl

# Apply configuration from config file (replace mode - default)
./mcpctl apply -f example/mcp.json -e .env

# Apply configuration with merge mode (preserves existing servers)
./mcpctl apply -f example/mcp.json --merge

# Show differences between config and target files
./mcpctl diff -f example/mcp.json

# Preview merge results
./mcpctl diff -f example/mcp.json --merge

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
- **Two Operation Modes**: Replace (default) and merge configurations
- Environment variable substitution using `envsubst`
- Multiple target file support with different JSON key mappings
- Path expansion (tilde `~` support)
- Unified diff and apply operations for both modes
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

## Operation Modes

### Replace Mode (Default)
```bash
./mcpctl apply -f config.json
```
Completely replaces the target configuration key with new servers. Existing servers are removed.

### Merge Mode
```bash
./mcpctl apply -f config.json --merge  
```
Merges new servers with existing ones. Existing servers are preserved, and duplicate server names are overwritten with new definitions.

## README Maintenance

**IMPORTANT**: When making any changes to functionality, commands, or features, you MUST update the documentation files:

### Required Updates
1. **README.md** (English): Update command examples, feature descriptions, and usage instructions
2. **README-ja.md** (Japanese): Keep in sync with English version, translate new content
3. **CLAUDE.md** (This file): Update developer-focused information

### Update Checklist
- [ ] Add new command examples to both README files
- [ ] Update feature lists if new functionality is added
- [ ] Modify configuration examples if format changes
- [ ] Add/update test instructions if new test files are created
- [ ] Ensure cross-links between README.md and README-ja.md remain valid
- [ ] Update version numbers or badges if applicable

### When to Update
- Adding new CLI options or commands
- Changing existing command behavior
- Adding new configuration file features
- Modifying installation or setup procedures
- Adding new dependencies or requirements
- Fixing bugs that affect documented behavior

This ensures that both users and developers have accurate, up-to-date information about mcpctl functionality.