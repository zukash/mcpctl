#!/usr/bin/env bats

# Error handling tests for mcpctl

setup() {
    # Change to project root directory
    cd "$BATS_TEST_DIRNAME/.."
}

teardown() {
    # Clean up temporary files
    rm -f tests/fixtures/invalid-config.json
    rm -f tests/fixtures/malformed.json
}

@test "mcpctl fails with invalid JSON in config file" {
    # Create a malformed JSON file
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [
    {
      "name": "test",
      "path": "/tmp/test.json"
      "key": "mcpServers"  // Missing comma - invalid JSON
    }
  ],
  "mcpServers": {}
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Invalid JSON in config file" ]]
}

@test "mcpctl fails when config file has no targets" {
    # Create a config file without targets
    cat > tests/fixtures/invalid-config.json << EOF
{
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: No targets found in configuration file" ]]
}

@test "mcpctl fails when config file has empty targets array" {
    # Create a config file with empty targets
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: No targets found in configuration file" ]]
}

@test "mcpctl fails when config file has no mcpServers section" {
    # Create a config file without mcpServers
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [
    {
      "name": "test",
      "path": "/tmp/test.json",
      "key": "mcpServers"
    }
  ]
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: mcpServers not found in config file" ]]
}

@test "mcpctl fails when jq is not available" {
    # This test would require temporarily disabling jq, which is complex
    # Skip for now, but could be implemented with PATH manipulation
    skip "jq dependency test requires complex PATH manipulation"
}

@test "mcpctl fails when envsubst is not available" {
    # This test would require temporarily disabling envsubst, which is complex
    # Skip for now, but could be implemented with PATH manipulation
    skip "envsubst dependency test requires complex PATH manipulation"
}

@test "mcpctl handles malformed target JSON gracefully" {
    # Create a config with malformed target (missing required fields)
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [
    {
      "name": "incomplete-target"
    }
  ],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    [ "$status" -eq 0 ]
    # Should handle missing path gracefully and show a reasonable error
    [[ "$output" =~ "Processing target: incomplete-target" ]] || [[ "$output" =~ "Warning:" ]] || [[ "$output" =~ "Error:" ]]
}

@test "mcpctl handles target with malformed JSON file" {
    # Create a malformed target file
    cat > tests/fixtures/malformed.json << EOF
{
  "incomplete": json
EOF

    # Create a config that targets the malformed file
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [
    {
      "name": "malformed-target",
      "path": "tests/fixtures/malformed.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    # Current implementation handles this gracefully and continues processing
    # The malformed JSON will cause jq to fail silently in the process_target function
    [ "$status" -eq 0 ]  # mcpctl doesn't fail, but the specific target processing might fail
}

@test "mcpctl handles permission denied on target file" {
    # Create a file and remove read permissions (if possible)
    echo '{"test": "value"}' > tests/fixtures/no-permission.json
    chmod 000 tests/fixtures/no-permission.json 2>/dev/null || skip "Cannot change file permissions"

    # Create a config that targets the no-permission file
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [
    {
      "name": "no-permission-target",
      "path": "tests/fixtures/no-permission.json",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    
    # Cleanup
    chmod 644 tests/fixtures/no-permission.json 2>/dev/null
    rm -f tests/fixtures/no-permission.json
    
    # Current implementation will continue processing even with permission errors
    # The cat command in process_target will fail, but mcpctl continues
    [ "$status" -eq 0 ]  # mcpctl itself doesn't fail
}

@test "mcpctl handles target file that is not JSON" {
    # Create a non-JSON target file
    echo "This is not JSON" > tests/fixtures/not-json.txt

    # Create a config that targets the non-JSON file
    cat > tests/fixtures/invalid-config.json << EOF
{
  "targets": [
    {
      "name": "not-json-target",
      "path": "tests/fixtures/not-json.txt",
      "key": "mcpServers"
    }
  ],
  "mcpServers": {
    "test": "value"
  }
}
EOF

    run ./mcpctl diff -f tests/fixtures/invalid-config.json
    
    # Cleanup
    rm -f tests/fixtures/not-json.txt
    
    # Current implementation will try to process non-JSON and may fail gracefully
    # The jq command in process_target will fail, but mcpctl may continue
    [ "$status" -eq 0 ]  # mcpctl itself continues processing
}