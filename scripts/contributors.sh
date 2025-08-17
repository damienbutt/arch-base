#!/bin/bash
# Simple Contributors Management Script
# A lightweight alternative to all-contributors-cli for Go projects

set -e

REPO_OWNER="damienbutt"
REPO_NAME="arch-base"
README_FILE="README.md"

# Function to add a contributor
add_contributor() {
    local username="$1"
    local contribution="$2"

    if [ -z "$username" ] || [ -z "$contribution" ]; then
        echo "Usage: $0 add <username> <contribution>"
        echo "Example: $0 add johndoe code"
        echo "Valid contributions: code, docs, design, ideas, bug, maintenance, test, tool, review"
        exit 1
    fi

    echo "Adding contributor: $username ($contribution)"

    # Here you would update the README.md manually or use a simple template
    echo "Please manually add the contributor to README.md in the contributors section."
    echo "Username: $username"
    echo "Contribution: $contribution"
    echo "Avatar URL: https://avatars.githubusercontent.com/$username"
    echo "Profile URL: https://github.com/$username"
}

# Function to generate contributors section
generate() {
    echo "Generating contributors section..."
    echo "This would fetch contributors from GitHub API and update README.md"
    echo "For now, please update the contributors section manually."
}

# Function to check contributors
check() {
    echo "Checking contributors in README.md..."
    if grep -q "ALL-CONTRIBUTORS" "$README_FILE"; then
        echo "✅ Contributors section found in README.md"
    else
        echo "❌ Contributors section not found in README.md"
    fi
}

# Main script logic
case "${1:-help}" in
    "add")
        add_contributor "$2" "$3"
        ;;
    "generate")
        generate
        ;;
    "check")
        check
        ;;
    "help"|*)
        echo "Simple Contributors Management"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  add <username> <contribution>  Add a new contributor"
        echo "  generate                       Generate contributors section"
        echo "  check                         Check contributors section"
        echo "  help                          Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 add johndoe code"
        echo "  $0 add janedoe docs"
        echo "  $0 generate"
        echo "  $0 check"
        ;;
esac
