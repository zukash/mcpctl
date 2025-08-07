#!/usr/bin/env bats

# Diff functionality tests for mcpctl

setup() {
    # Change to project root directory
    cd "$BATS_TEST_DIRNAME/.."
    
    # Create a temporary copy of the target file for each test
    cp tests/fixtures/target.json tests/fixtures/target-temp.json
}

teardown() {
    # Clean up temporary files
    rm -f tests/fixtures/target-temp.json
    rm -f tests/fixtures/temp-config.json
}

@test "mcpctl diff shows differences when configuration differs" {
    # Create a config that targets the temp file
    cat > tests/fixtures/temp-config.json << EOF
{
  "targets": [
    {
      "name": "test-target",
      "path": "tests/fixtures/target-temp.json", 
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "new-server": {
      "command": "new-command"
    }
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Showing differences for configuration" ]]
    [[ "$output" =~ "=== Diff for target:" ]]
    [[ "$output" =~ "new-server" ]]
    [[ "$output" =~ "new-command" ]]
    [[ "$output" =~ "-    \"old-server\"" ]]
}

@test "mcpctl diff shows no differences when configuration matches" {
    # Create a config that matches the current target
    cat > tests/fixtures/temp-config.json << EOF
{
  "targets": [
    {
      "name": "test-target",
      "path": "tests/fixtures/target-temp.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "old-server": {
      "command": "old-command"
    }
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No differences found" ]]
}

@test "mcpctl diff with environment variables" {
    # Create a config with environment variables
    cat > tests/fixtures/temp-config.json << EOF
{
  "targets": [
    {
      "name": "test-target",
      "path": "tests/fixtures/target-temp.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "\${ROOT}"]
    }
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/temp-config.json -e tests/fixtures/.env
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Loading environment variables" ]]
    [[ "$output" =~ "/home/test" ]]  # Environment variable should be substituted
}

@test "mcpctl diff warns about missing target file" {
    # Create a config that targets a non-existent file
    cat > tests/fixtures/temp-config.json << EOF
{
  "targets": [
    {
      "name": "missing-target",
      "path": "tests/fixtures/non-existent.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Warning: Target file" ]]
    [[ "$output" =~ "not found, skipping" ]]
}

@test "mcpctl diff handles tilde path expansion" {
    # Create a config with tilde in path (won't actually exist, but tests path expansion)
    cat > tests/fixtures/temp-config.json << EOF
{
  "targets": [
    {
      "name": "home-target",
      "path": "~/non-existent.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    # Should show expanded home directory path in warning
    [[ "$output" =~ "$HOME" ]]
}