#!/usr/bin/env bats

# Apply functionality tests for mcpctl

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

@test "mcpctl apply successfully modifies configuration" {
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
      "command": "new-command",
      "args": ["arg1", "arg2"]
    }
  }
}
EOF

    # Apply the configuration
    run ./mcpctl apply -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Applying configuration" ]]
    [[ "$output" =~ "Processing target: test-target" ]]
    [[ "$output" =~ "✓ Applied configuration" ]]
    
    # Verify the file was modified correctly
    run jq -r '.mcpServers."new-server".command' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "new-command" ]
    
    # Verify other settings are preserved
    run jq -r '.otherSettings.theme' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "dark" ]
}

@test "mcpctl apply with environment variables" {
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
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "\${ROOT}"],
      "env": {
        "TOKEN": "\${TOKEN}"
      }
    }
  }
}
EOF

    # Apply with environment file
    run ./mcpctl apply -f tests/fixtures/temp-config.json -e tests/fixtures/.env
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Loading environment variables" ]]
    [[ "$output" =~ "✓ Applied configuration" ]]
    
    # Verify environment variables were substituted
    run jq -r '.mcpServers.filesystem.args[2]' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "/home/test" ]
    
    run jq -r '.mcpServers.filesystem.env.TOKEN' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "ghp_test_token_123" ]
}

@test "mcpctl apply preserves existing non-target keys" {
    # Create a config that only modifies mcpServers
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
    "completely-new": {
      "command": "different"
    }
  }
}
EOF

    # Apply the configuration
    run ./mcpctl apply -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    
    # Verify mcpServers was replaced
    run jq -r '.mcpServers."completely-new".command' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "different" ]
    
    # Verify old mcpServers key is gone
    run jq -r '.mcpServers."old-server"' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "null" ]
    
    # Verify other keys are preserved
    run jq -r '.version' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "1.0" ]
    
    run jq -r '.otherSettings.theme' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "dark" ]
}

@test "mcpctl apply with different target key" {
    # Modify the target file to have a different structure
    cat > tests/fixtures/target-temp.json << EOF
{
  "version": "1.0",
  "servers": {
    "old-server": {
      "command": "old-command"
    }
  },
  "otherSettings": {
    "theme": "dark"
  }
}
EOF

    # Create a config that targets the "servers" key instead of "mcpServers"
    cat > tests/fixtures/temp-config.json << EOF
{
  "targets": [
    {
      "name": "test-target",
      "path": "tests/fixtures/target-temp.json",
      "key": "servers"
    }
  ],
  "mcpServers": {
    "new-server": {
      "command": "new-command"
    }
  }
}
EOF

    # Apply the configuration
    run ./mcpctl apply -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Processing target: test-target (key: servers)" ]]
    
    # Verify the "servers" key was modified
    run jq -r '.servers."new-server".command' tests/fixtures/target-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "new-command" ]
}

@test "mcpctl apply warns about missing target files" {
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

    run ./mcpctl apply -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Warning: Target file" ]]
    [[ "$output" =~ "not found, skipping" ]]
}

@test "mcpctl apply and diff produce identical results" {
    # Create a config
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
    "consistency-test": {
      "command": "test-command",
      "args": ["arg1"]
    }
  }
}
EOF

    # First, run diff to see what would change
    run ./mcpctl diff -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    diff_output="$output"

    # Apply the configuration
    run ./mcpctl apply -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    
    # Now diff should show no changes
    run ./mcpctl diff -f tests/fixtures/temp-config.json
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No differences found" ]]
}