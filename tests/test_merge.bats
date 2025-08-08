#!/usr/bin/env bats

# Merge functionality tests for mcpctl

setup() {
    # Change to project root directory
    cd "$BATS_TEST_DIRNAME/.."
    
    # Create a temporary copy of the target file for each test
    cp tests/fixtures/target.json tests/fixtures/target-merge-temp.json
}

teardown() {
    # Clean up temporary files
    rm -f tests/fixtures/target-merge-temp.json
    rm -f tests/fixtures/merge-temp-config.json
}

@test "mcpctl apply --merge merges with existing configuration" {
    # Create a config that adds new servers
    cat > tests/fixtures/merge-temp-config.json << EOF
{
  "targets": [
    {
      "name": "merge-test",
      "path": "tests/fixtures/target-merge-temp.json",
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

    # Apply with merge mode
    run ./mcpctl apply -f tests/fixtures/merge-temp-config.json --merge
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Applied configuration" ]]
    
    # Verify existing server is preserved
    run jq -r '.mcpServers."old-server".command' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "old-command" ]
    
    # Verify new server is added
    run jq -r '.mcpServers."new-server".command' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "new-command" ]
    
    # Verify other settings are preserved
    run jq -r '.otherSettings.theme' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "dark" ]
}

@test "mcpctl apply without --merge replaces configuration (default behavior)" {
    # Create a config that replaces servers
    cat > tests/fixtures/merge-temp-config.json << EOF
{
  "targets": [
    {
      "name": "replace-test",
      "path": "tests/fixtures/target-merge-temp.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "replacement-server": {
      "command": "replacement-command"
    }
  }
}
EOF

    # Apply without merge mode (default replace)
    run ./mcpctl apply -f tests/fixtures/merge-temp-config.json
    [ "$status" -eq 0 ]
    
    # Verify old server is gone
    run jq -r '.mcpServers."old-server"' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "null" ]
    
    # Verify only replacement server remains
    run jq -r '.mcpServers."replacement-server".command' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "replacement-command" ]
    
    # Verify other settings are preserved
    run jq -r '.otherSettings.theme' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "dark" ]
}

@test "mcpctl diff --merge shows merge preview" {
    # Create a config that adds new servers
    cat > tests/fixtures/merge-temp-config.json << EOF
{
  "targets": [
    {
      "name": "merge-diff-test",
      "path": "tests/fixtures/target-merge-temp.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "preview-server": {
      "command": "preview-command"
    }
  }
}
EOF

    # Run diff with merge mode
    run ./mcpctl diff -f tests/fixtures/merge-temp-config.json --merge
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Diff for target: merge-diff-test" ]]
    [[ "$output" =~ "preview-server" ]]
    [[ "$output" =~ "old-server" ]]  # Should show existing server being preserved
}

@test "mcpctl apply --merge overwrites duplicate server names" {
    # Create a config that has a server with same name as existing one
    cat > tests/fixtures/merge-temp-config.json << EOF
{
  "targets": [
    {
      "name": "overwrite-test",
      "path": "tests/fixtures/target-merge-temp.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "old-server": {
      "command": "updated-command",
      "args": ["new-arg"]
    }
  }
}
EOF

    # Apply with merge mode
    run ./mcpctl apply -f tests/fixtures/merge-temp-config.json --merge
    [ "$status" -eq 0 ]
    
    # Verify the server was updated (merge behavior: new overwrites existing)
    run jq -r '.mcpServers."old-server".command' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "updated-command" ]
    
    # Verify new args were added
    run jq -r '.mcpServers."old-server".args[0]' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "new-arg" ]
}

@test "mcpctl apply --merge works with empty target key" {
    # Modify target to have no mcpServers initially
    echo '{"version": "1.0", "otherSettings": {"theme": "dark"}}' > tests/fixtures/target-merge-temp.json
    
    # Create a config that adds servers
    cat > tests/fixtures/merge-temp-config.json << EOF
{
  "targets": [
    {
      "name": "empty-merge-test",
      "path": "tests/fixtures/target-merge-temp.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "first-server": {
      "command": "first-command"
    }
  }
}
EOF

    # Apply with merge mode on empty target key
    run ./mcpctl apply -f tests/fixtures/merge-temp-config.json --merge
    [ "$status" -eq 0 ]
    
    # Verify the server was added
    run jq -r '.mcpServers."first-server".command' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "first-command" ]
    
    # Verify other settings are preserved
    run jq -r '.otherSettings.theme' tests/fixtures/target-merge-temp.json
    [ "$status" -eq 0 ]
    [ "$output" = "dark" ]
}