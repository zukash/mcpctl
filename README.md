# mcpctl - MCP Configuration Controller

[![Tests](https://img.shields.io/badge/tests-passing-green)](./tests/)
[![Shell](https://img.shields.io/badge/shell-bash-blue)](./mcpctl)
[![License](https://img.shields.io/badge/license-MIT-blue)](#license)

**[日本語版 README はこちら](./README-ja.md)**

A simple and powerful tool to manage MCP (Model Context Protocol) server configurations across different AI clients like Claude Code and GitHub Copilot.

## Features

- **Centralized Configuration**: Manage MCP servers from a single JSON configuration file
- **Multiple Targets**: Apply configurations to different AI client config files simultaneously
- **Two Operation Modes**:
  - **Replace Mode** (default): Completely replace existing server configurations
  - **Merge Mode**: Preserve existing servers while adding new ones
- **Environment Variables**: Support for sensitive data through environment variable substitution
- **Cross-Platform**: Works on macOS, Linux, and Windows (via WSL/Git Bash)
- **Preview Changes**: See what will change before applying with diff command

## Quick Start

### Installation

1. **Prerequisites**: Install required tools
   ```bash
   # macOS
   brew install jq gettext
   
   # Ubuntu/Debian
   apt-get install jq gettext-base
   
   # Other systems: Install jq and envsubst
   ```

2. **Download mcpctl**
   ```bash
   curl -O https://raw.githubusercontent.com/zukash/mcpctl/main/mcpctl
   chmod +x mcpctl
   ```

### Basic Usage

1. **Create a configuration file** (e.g., `mcp.json`):
   ```json
   {
     "targets": [
       {
         "name": "claude-code",
         "path": "~/.claude.json",
         "key": "mcpServers"
       }
     ],
     "mcpServers": {
       "filesystem": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
       },
       "github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
         }
       }
     }
   }
   ```

2. **Apply configuration**:
   ```bash
   # Replace existing servers (default)
   ./mcpctl apply -f mcp.json
   
   # Merge with existing servers
   ./mcpctl apply -f mcp.json --merge
   
   # Preview changes first
   ./mcpctl diff -f mcp.json --merge
   ```

## Commands

### apply
Apply configuration to target files.

```bash
mcpctl apply -f <config-file> [-e <env-file>] [--merge]
```

**Options:**
- `-f <file>`: Configuration file (required)
- `-e <file>`: Environment variables file (optional)
- `--merge`: Merge with existing configuration instead of replacing

**Examples:**
```bash
# Replace mode (removes existing servers)
mcpctl apply -f team-config.json

# Merge mode (preserves existing servers)
mcpctl apply -f additional-servers.json --merge

# With environment variables
mcpctl apply -f mcp.json -e .env --merge
```

### diff
Show differences between configuration and target files.

```bash
mcpctl diff -f <config-file> [-e <env-file>] [--merge]
```

**Examples:**
```bash
# Preview replace operation
mcpctl diff -f mcp.json

# Preview merge operation
mcpctl diff -f mcp.json --merge
```

## Configuration Format

### Basic Structure
```json
{
  "targets": [
    {
      "name": "display-name",
      "path": "/path/to/target/file.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "server-name": {
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "VAR_NAME": "value"
      }
    }
  }
}
```

### Target Configuration
- **name**: Display name for the target (used in output messages)
- **path**: File path to update (supports tilde `~` expansion)
- **key**: JSON key to update in the target file (default: "mcpServers")

### Supported Clients

| Client | Config Path | Key |
|--------|-------------|-----|
| Claude Code | `~/.claude.json` | `mcpServers` |
| GitHub Copilot | `~/Library/Application Support/Code/User/mcp.json` | `servers` |
| Custom | Any JSON file | Any key |

## Environment Variables

Use environment variables for sensitive data like API tokens:

1. **Create `.env` file**:
   ```bash
   GITHUB_TOKEN=ghp_your_token_here
   WORKSPACE_PATH=/Users/username/projects
   ```

2. **Reference in config**:
   ```json
   {
     "mcpServers": {
       "github": {
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
         }
       },
       "filesystem": {
         "args": ["-y", "@modelcontextprotocol/server-filesystem", "${WORKSPACE_PATH}"]
       }
     }
   }
   ```

3. **Apply with env file**:
   ```bash
   mcpctl apply -f mcp.json -e .env
   ```

## Operation Modes

### Replace Mode (Default)
Completely replaces the target configuration section with new servers.

**Before:**
```json
{
  "mcpServers": {
    "old-server": { "command": "old-cmd" }
  }
}
```

**After applying config with `new-server`:**
```json
{
  "mcpServers": {
    "new-server": { "command": "new-cmd" }
  }
}
```

### Merge Mode
Preserves existing servers and adds new ones. Duplicate server names are overwritten.

**Before:**
```json
{
  "mcpServers": {
    "old-server": { "command": "old-cmd" }
  }
}
```

**After applying config with `new-server` using `--merge`:**
```json
{
  "mcpServers": {
    "old-server": { "command": "old-cmd" },
    "new-server": { "command": "new-cmd" }
  }
}
```

## Examples

### Team Configuration Management
```bash
# Base team configuration
mcpctl apply -f team-base.json

# Individual developer additions
mcpctl apply -f personal-servers.json --merge

# Preview what personal config would add
mcpctl diff -f personal-servers.json --merge
```

### Multi-Client Setup
```json
{
  "targets": [
    {
      "name": "claude-code",
      "path": "~/.claude.json",
      "key": "mcpServers"
    },
    {
      "name": "github-copilot",
      "path": "~/Library/Application Support/Code/User/mcp.json",
      "key": "servers"
    }
  ],
  "mcpServers": {
    "shared-filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${PROJECT_ROOT}"]
    }
  }
}
```

### Development Workflow
```bash
# 1. Create base configuration for team
mcpctl apply -f base-config.json

# 2. Add project-specific servers
mcpctl apply -f project-servers.json --merge

# 3. Add personal development servers
mcpctl apply -f dev-servers.json --merge

# 4. Check final configuration
mcpctl diff -f complete-config.json
```

## Testing

Run the test suite to verify functionality:

```bash
# Install bats-core for testing
brew install bats-core  # macOS
apt-get install bats    # Ubuntu

# Run all tests
./tests/run_tests.sh

# Run specific test suites
bats tests/test_basic.bats
bats tests/test_apply.bats
bats tests/test_merge.bats
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass: `./tests/run_tests.sh`
6. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

- **Issues**: Report bugs and feature requests on [GitHub Issues](https://github.com/zukash/mcpctl/issues)
- **Documentation**: See [CLAUDE.md](./CLAUDE.md) for developer documentation
- **Examples**: Check the [example/](./example/) directory for sample configurations