#!/usr/bin/env bash
#
# Groundskeeper Willie Uninstaller
#
# Removes Groundskeeper Willie from your system
#
# Usage:
#   ./uninstall.sh              # Interactive uninstall with confirmations
#   ./uninstall.sh --force      # Skip all confirmation prompts
#   ./uninstall.sh --keep-worktrees  # Preserve active worktrees
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
FORCE_MODE=false
KEEP_WORKTREES=false

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

print_warning() {
    echo -e "${BLUE}! $1${NC}"
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                FORCE_MODE=true
                shift
                ;;
            --keep-worktrees)
                KEEP_WORKTREES=true
                shift
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Print help message
print_help() {
    cat << 'EOF'
Groundskeeper Willie Uninstaller

Usage:
  ./uninstall.sh [OPTIONS]

Options:
  --force              Skip all confirmation prompts
  --keep-worktrees     Preserve active worktrees (don't clean them up)
  --help, -h           Show this help message

Examples:
  ./uninstall.sh                    # Interactive uninstall
  ./uninstall.sh --force            # Uninstall without prompts
  ./uninstall.sh --keep-worktrees   # Uninstall but keep worktrees

What will be removed:
  - Source line from shell config file (~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish)
  - ~/.groundskeeper-willie/ directory and all its contents
  - Optionally: active worktrees (unless --keep-worktrees is used)

Your backup files and git repository will NOT be affected.
EOF
}

# Detect the user's shell (same logic as install.sh)
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

# Get the appropriate shell config file based on shell type and OS
# Args: shell_type (bash, zsh, or fish)
# Returns: path to config file
get_config_file() {
    local shell_type="$1"
    local config_file=""

    case "$shell_type" in
        bash)
            # macOS uses ~/.bash_profile, Linux uses ~/.bashrc
            if [[ "$OSTYPE" == "darwin"* ]]; then
                config_file="$HOME/.bash_profile"
            else
                config_file="$HOME/.bashrc"
            fi
            ;;
        zsh)
            config_file="$HOME/.zshrc"
            ;;
        fish)
            config_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            return 1
            ;;
    esac

    echo "$config_file"
    return 0
}

# Check if Groundskeeper Willie is installed
# Returns: 0 if installed, 1 if not
is_installed() {
    local config_file="$1"
    local install_dir="$HOME/.groundskeeper-willie"

    # Check if config file has the markers
    local has_config=false
    if [[ -f "$config_file" ]] && grep -q "# >>> groundskeeper-willie >>>" "$config_file" 2>/dev/null; then
        has_config=true
    fi

    # Check if install directory exists
    local has_dir=false
    if [[ -d "$install_dir" ]]; then
        has_dir=true
    fi

    # Return true if either exists
    if [[ "$has_config" == "true" || "$has_dir" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# List active worktrees in current repository
# Returns: 0 if worktrees found, 1 if none or not in git repo
list_worktrees() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    local worktree_list
    worktree_list=$(git worktree list 2>/dev/null | tail -n +2)

    if [[ -n "$worktree_list" ]]; then
        echo "$worktree_list"
        return 0
    else
        return 1
    fi
}

# Remove source lines from config file (between markers)
# Args: config_file path
# Returns: 0 if successful, 1 if failed
remove_from_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 0  # Nothing to remove
    fi

    # Check if markers exist
    if ! grep -q "# >>> groundskeeper-willie >>>" "$config_file" 2>/dev/null; then
        return 0  # Nothing to remove
    fi

    # Create a temporary file
    local temp_file
    temp_file=$(mktemp)

    # Remove lines between markers (inclusive)
    # Using sed to delete from start marker to end marker
    if sed '/# >>> groundskeeper-willie >>>/,/# <<< groundskeeper-willie <<</d' "$config_file" > "$temp_file"; then
        # Replace original file with cleaned version
        if mv "$temp_file" "$config_file"; then
            return 0
        else
            rm -f "$temp_file"
            return 1
        fi
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Find most recent backup file for config
# Args: config_file path
# Returns: path to backup file if found
find_backup() {
    local config_file="$1"
    local backup_file=""
    local latest_time=0

    # Iterate through backup files to find the most recent
    for file in "${config_file}.backup."*; do
        # Check if glob expanded (file exists)
        if [[ -f "$file" ]]; then
            # Get modification time (platform independent)
            local mtime
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS stat syntax
                mtime=$(stat -f %m "$file" 2>/dev/null || echo "0")
            else
                # Linux stat syntax
                mtime=$(stat -c %Y "$file" 2>/dev/null || echo "0")
            fi

            if [[ $mtime -gt $latest_time ]]; then
                latest_time=$mtime
                backup_file="$file"
            fi
        fi
    done

    if [[ -n "$backup_file" ]]; then
        echo "$backup_file"
        return 0
    else
        return 1
    fi
}

# Prompt user for confirmation
# Args: prompt message
# Returns: 0 if yes, 1 if no
confirm() {
    local prompt="$1"

    if [[ "$FORCE_MODE" == "true" ]]; then
        return 0
    fi

    local response
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Display what will be removed (dry-run summary)
# Args: config_file, install_dir
show_removal_summary() {
    local config_file="$1"
    local install_dir="$2"
    local has_config=false
    local has_dir=false
    local has_worktrees=false

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Uninstall Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_info "The following will be removed:"
    echo ""

    # Check config file
    if [[ -f "$config_file" ]] && grep -q "# >>> groundskeeper-willie >>>" "$config_file" 2>/dev/null; then
        echo "  ✗ Source line from: $config_file"
        has_config=true
    fi

    # Check install directory
    if [[ -d "$install_dir" ]]; then
        echo "  ✗ Installation directory: $install_dir"
        has_dir=true
    fi

    # Check worktrees
    if [[ "$KEEP_WORKTREES" == "false" ]]; then
        if list_worktrees >/dev/null 2>&1; then
            echo "  ✗ Active worktrees (listed below):"
            list_worktrees | while IFS= read -r line; do
                echo "      $line"
            done
            has_worktrees=true
        fi
    fi

    echo ""

    # Check if anything to remove
    if [[ "$has_config" == "false" && "$has_dir" == "false" && "$has_worktrees" == "false" ]]; then
        print_warning "Nothing to remove (Groundskeeper Willie not installed)"
        return 1
    fi

    # Show what will be preserved
    print_info "The following will be preserved:"
    echo ""
    echo "  ✓ Backup files (${config_file}.backup.*)"
    echo "  ✓ Git repository and branches"

    if [[ "$KEEP_WORKTREES" == "true" ]]; then
        echo "  ✓ Active worktrees (--keep-worktrees flag)"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    return 0
}

# Clean up worktrees
# Returns: count of cleaned worktrees
cleanup_worktrees() {
    if [[ "$KEEP_WORKTREES" == "true" ]]; then
        return 0
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 0  # Not in a git repo, nothing to clean
    fi

    local count=0

    # Get list of worktree paths (excluding main worktree)
    local worktree_paths
    worktree_paths=$(git worktree list --porcelain | grep '^worktree ' | cut -d' ' -f2 | tail -n +2)

    if [[ -n "$worktree_paths" ]]; then
        while IFS= read -r worktree_path; do
            if [[ -d "$worktree_path" ]]; then
                print_info "Removing worktree: $worktree_path"
                if git worktree remove "$worktree_path" --force 2>/dev/null; then
                    ((count++))
                fi
            fi
        done <<< "$worktree_paths"
    fi

    # Clean up .worktrees directory if it exists and is empty
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$repo_root" && -d "$repo_root/.worktrees" ]]; then
        # Only remove if empty
        if ! ls -A "$repo_root/.worktrees" >/dev/null 2>&1; then
            rmdir "$repo_root/.worktrees" 2>/dev/null || true
        fi
    fi

    return "$count"
}

# Main uninstall flow
main() {
    # Parse command-line arguments
    parse_args "$@"

    print_info "Groundskeeper Willie Uninstaller"
    echo ""

    # Detect shell
    print_info "Detecting shell..."
    local shell_type
    if shell_type=$(detect_shell); then
        print_success "Detected shell: $shell_type"
    else
        print_warning "Could not detect shell, will try all common shells"
        shell_type="bash"  # Default to bash for config file detection
    fi

    # Get config file
    echo ""
    print_info "Determining shell config file..."
    local config_file
    if ! config_file=$(get_config_file "$shell_type"); then
        print_error "Failed to determine config file for shell: $shell_type"
        exit 1
    fi
    print_success "Config file: $config_file"

    # Check if installed
    local install_dir="$HOME/.groundskeeper-willie"

    if ! is_installed "$config_file"; then
        echo ""
        print_warning "Groundskeeper Willie does not appear to be installed"
        print_info "Nothing to uninstall"
        exit 0
    fi

    # Show what will be removed
    if ! show_removal_summary "$config_file" "$install_dir"; then
        exit 0
    fi

    # Confirm uninstall
    if ! confirm "Do you want to proceed with uninstallation?"; then
        echo ""
        print_info "Uninstallation cancelled"
        exit 0
    fi

    echo ""

    # Remove from config file
    if [[ -f "$config_file" ]] && grep -q "# >>> groundskeeper-willie >>>" "$config_file" 2>/dev/null; then
        print_info "Removing source line from $config_file..."
        if remove_from_config "$config_file"; then
            print_success "Removed source line from config file"

            # Offer to restore from backup
            if find_backup "$config_file" >/dev/null 2>&1; then
                local backup_file
                backup_file=$(find_backup "$config_file")
                echo ""
                print_info "Backup file found: $backup_file"
                if confirm "Would you like to restore from this backup instead?"; then
                    if cp "$backup_file" "$config_file"; then
                        print_success "Restored config from backup"
                    else
                        print_error "Failed to restore from backup"
                    fi
                fi
            fi
        else
            print_error "Failed to remove source line from config file"
        fi
    fi

    # Remove installation directory
    echo ""
    if [[ -d "$install_dir" ]]; then
        print_info "Removing installation directory..."
        if rm -rf "$install_dir"; then
            print_success "Removed $install_dir"
        else
            print_error "Failed to remove $install_dir"
        fi
    fi

    # Clean up worktrees
    echo ""
    if [[ "$KEEP_WORKTREES" == "false" ]]; then
        if list_worktrees >/dev/null 2>&1; then
            print_info "Cleaning up worktrees..."
            local cleaned_count
            cleanup_worktrees
            cleaned_count=$?
            if [[ $cleaned_count -gt 0 ]]; then
                print_success "Removed $cleaned_count worktree(s)"
            else
                print_info "No worktrees to clean up"
            fi
        fi
    else
        print_info "Skipping worktree cleanup (--keep-worktrees flag)"
    fi

    # Print success message
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "Groundskeeper Willie has been uninstalled"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_info "What was removed:"
    echo ""
    echo "  ✓ Source line from shell config"
    if [[ -d "$install_dir" ]]; then
        echo "  ✓ Installation directory: $install_dir"
    fi
    if [[ "$KEEP_WORKTREES" == "false" ]]; then
        echo "  ✓ Active worktrees (if any)"
    fi
    echo ""

    print_info "What remains:"
    echo ""
    echo "  - Backup files: ${config_file}.backup.*"
    echo "  - Git repository and branches"
    if [[ "$KEEP_WORKTREES" == "true" ]]; then
        echo "  - Active worktrees (preserved with --keep-worktrees)"
    fi
    echo ""

    print_info "Next steps:"
    echo ""
    echo "  1. Restart your shell or run: source $config_file"
    echo "  2. Verify uninstall: type willie (should show 'not found')"
    echo ""

    if find_backup "$config_file" >/dev/null 2>&1; then
        print_info "To restore from backup:"
        echo ""
        echo "  cp ${config_file}.backup.TIMESTAMP $config_file"
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_success "Thank you for using Groundskeeper Willie!"
    echo ""
}

# Run main function
main "$@"
