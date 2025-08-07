#!/usr/bin/env bash

# Test runner for mcpctl
# Usage: ./tests/run_tests.sh

set -e

echo "🧪 Running mcpctl test suite..."
echo

# Check if bats is available
if ! command -v bats &> /dev/null; then
    echo "❌ Error: bats is not installed."
    echo "Install with: brew install bats-core"
    echo "Or visit: https://github.com/bats-core/bats-core"
    exit 1
fi

# Check if jq is available (required by mcpctl)
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed."
    echo "Install with: brew install jq"
    exit 1
fi

# Check if envsubst is available (required by mcpctl)
if ! command -v envsubst &> /dev/null; then
    echo "❌ Error: envsubst is not installed."
    echo "Install with: brew install gettext"
    exit 1
fi

# Change to project root
cd "$(dirname "$0")/.."

# Make sure mcpctl is executable
chmod +x ./mcpctl

echo "📋 Running tests..."
echo

# Run all test files
bats tests/test_*.bats

echo
echo "🎉 All tests completed!"