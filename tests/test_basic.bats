#!/usr/bin/env bats

# Basic functionality tests for mcpctl

setup() {
    # Change to project root directory
    cd "$BATS_TEST_DIRNAME/.."
}

@test "mcpctl shows help when called without arguments" {
    run ./mcpctl
    [ "$status" -eq 1 ]
    [[ "$output" =~ "mcpctl - MCP Configuration Controller" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "mcpctl shows help with -h flag" {
    run ./mcpctl -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mcpctl - MCP Configuration Controller" ]]
    [[ "$output" =~ "COMMANDS:" ]]
    [[ "$output" =~ "apply" ]]
    [[ "$output" =~ "diff" ]]
}

@test "mcpctl shows help with --help flag" {
    run ./mcpctl --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mcpctl - MCP Configuration Controller" ]]
}

@test "mcpctl fails with invalid command" {
    run ./mcpctl invalid-command
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Invalid command: invalid-command" ]]
}

@test "mcpctl apply fails without -f option" {
    run ./mcpctl apply
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Configuration file (-f) is required" ]]
}

@test "mcpctl diff fails without -f option" {
    run ./mcpctl diff
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Configuration file (-f) is required" ]]
}

@test "mcpctl fails with non-existent config file" {
    run ./mcpctl apply -f non-existent.json
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Configuration file 'non-existent.json' not found" ]]
}

@test "mcpctl fails with non-existent env file" {
    run ./mcpctl apply -f tests/fixtures/sample-config.json -e non-existent.env
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: Environment file 'non-existent.env' not found" ]]
}