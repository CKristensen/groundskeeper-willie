#!/usr/bin/env bash
#
# Groundskeeper Willie Installer
# One-line installation: curl -sSL <url> | bash
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Detect the user's shell
# Returns: bash, zsh, fish, or unknown
detect_shell() {
    local detected_shell=""

    # First, try the $SHELL environment variable
    if [[ -n "$SHELL" ]]; then
        case "$SHELL" in
            */bash)
                detected_shell="bash"
                ;;
            */zsh)
                detected_shell="zsh"
                ;;
            */fish)
                detected_shell="fish"
                ;;
            *)
                detected_shell="unknown"
                ;;
        esac
    fi

    # If SHELL is not set or unknown, fallback to parent process inspection
    if [[ -z "$detected_shell" || "$detected_shell" == "unknown" ]]; then
        # Try to detect from parent process
        if [[ -f /proc/$$/comm ]]; then
            local parent_proc
            parent_proc=$(cat /proc/$$/comm 2>/dev/null || echo "")
            case "$parent_proc" in
                bash)
                    detected_shell="bash"
                    ;;
                zsh)
                    detected_shell="zsh"
                    ;;
                fish)
                    detected_shell="fish"
                    ;;
                *)
                    detected_shell="unknown"
                    ;;
            esac
        fi

        # Another fallback: check ps command
        if [[ -z "$detected_shell" || "$detected_shell" == "unknown" ]]; then
            local parent_name
            parent_name=$(ps -p $$ -o comm= 2>/dev/null || echo "")
            case "$parent_name" in
                bash)
                    detected_shell="bash"
                    ;;
                zsh)
                    detected_shell="zsh"
                    ;;
                fish)
                    detected_shell="fish"
                    ;;
                *)
                    detected_shell="unknown"
                    ;;
            esac
        fi
    fi

    # Final validation
    if [[ "$detected_shell" == "bash" || "$detected_shell" == "zsh" || "$detected_shell" == "fish" ]]; then
        echo "$detected_shell"
        return 0
    else
        echo "unknown"
        return 1
    fi
}

# Main installation flow
main() {
    print_info "Groundskeeper Willie Installer"
    echo ""

    # Detect shell
    print_info "Detecting shell..."
    local shell_type
    if shell_type=$(detect_shell); then
        print_success "Detected shell: $shell_type"
    else
        print_error "Unsupported shell detected."
        echo ""
        echo "Groundskeeper Willie supports the following shells:"
        echo "  - bash"
        echo "  - zsh"
        echo "  - fish"
        echo ""
        echo "Your current shell could not be identified or is not supported."
        echo "Please switch to a supported shell and try again."
        exit 1
    fi

    # TODO: Additional installation steps will be added in future user stories
    # - Backup and modify config
    # - Download functions file
    # - Verify installation
    # - Print success message

    echo ""
    print_info "Installation script is in progress (US-001 completed)"
    print_info "Additional features coming in US-002 through US-009"
}

# Run main function
main "$@"
