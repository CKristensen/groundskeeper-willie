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

# Create a timestamped backup of the config file
# Args: config_file path
backup_config() {
    local config_file="$1"

    # Only backup if the file exists
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${config_file}.backup.${timestamp}"

    # Copy with permissions preserved (-p flag)
    if cp -p "$config_file" "$backup_file"; then
        print_success "Created backup: $backup_file"
        return 0
    else
        print_error "Failed to create backup of $config_file"
        return 1
    fi
}

# Install the functions file to ~/.groundskeeper-willie/
# Args: shell_type
install_functions_file() {
    local shell_type="$1"
    local install_dir="$HOME/.groundskeeper-willie"
    local source_file=""
    local target_file=""

    # Determine which functions file to install
    if [[ "$shell_type" == "fish" ]]; then
        source_file="worktree-agent-functions.fish"
        target_file="$install_dir/worktree-agent-functions.fish"
    else
        source_file="worktree-agent-functions.sh"
        target_file="$install_dir/worktree-agent-functions.sh"
    fi

    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        print_error "Functions file not found: $source_file"
        print_info "Are you running this from the groundskeeper-willie repository directory?"
        return 1
    fi

    # Create installation directory if it doesn't exist
    if [[ ! -d "$install_dir" ]]; then
        if ! mkdir -p "$install_dir"; then
            print_error "Failed to create directory: $install_dir"
            return 1
        fi
    fi

    # Copy functions file
    if ! cp "$source_file" "$target_file"; then
        print_error "Failed to copy $source_file to $target_file"
        return 1
    fi

    # Make it executable
    if ! chmod +x "$target_file"; then
        print_error "Failed to make $target_file executable"
        return 1
    fi

    print_success "Installed: $target_file"
    return 0
}

# Update config file with source line for Groundskeeper Willie
# Args: config_file path, shell_type
update_config() {
    local config_file="$1"
    local shell_type="$2"
    local functions_path="$HOME/.groundskeeper-willie/worktree-agent-functions"

    # Determine the correct functions file extension
    if [[ "$shell_type" == "fish" ]]; then
        functions_path="${functions_path}.fish"
    else
        functions_path="${functions_path}.sh"
    fi

    # Markers for idempotence
    local marker_begin="# >>> groundskeeper-willie >>>"
    local marker_end="# <<< groundskeeper-willie <<<"
    local source_line="source \"${functions_path}\""

    # Fish uses a different syntax (no quotes needed)
    if [[ "$shell_type" == "fish" ]]; then
        source_line="source ${functions_path}"
    fi

    # Create config file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        # Create directory if needed (for fish)
        local config_dir
        config_dir=$(dirname "$config_file")
        if [[ ! -d "$config_dir" ]]; then
            mkdir -p "$config_dir" || {
                print_error "Failed to create config directory: $config_dir"
                return 1
            }
        fi
        touch "$config_file" || {
            print_error "Failed to create config file: $config_file"
            return 1
        }
    fi

    # Check if already installed (idempotent)
    if grep -q "$marker_begin" "$config_file" 2>/dev/null; then
        print_info "Groundskeeper Willie already configured in $config_file"
        return 0
    fi

    # Append the source line with markers
    {
        echo ""
        echo "$marker_begin"
        echo "$source_line"
        echo "$marker_end"
    } >> "$config_file" || {
        print_error "Failed to update config file: $config_file"
        return 1
    }

    print_success "Updated config file: $config_file"
    return 0
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

    # Get the appropriate config file
    echo ""
    print_info "Determining shell config file..."
    local config_file
    if ! config_file=$(get_config_file "$shell_type"); then
        print_error "Failed to determine config file for shell: $shell_type"
        exit 1
    fi
    print_success "Config file: $config_file"

    # Create backup of existing config
    echo ""
    print_info "Creating backup of config file..."
    if ! backup_config "$config_file"; then
        print_error "Failed to backup config file"
        exit 1
    fi

    # Install functions file
    echo ""
    print_info "Installing functions file..."
    if ! install_functions_file "$shell_type"; then
        print_error "Failed to install functions file"
        exit 1
    fi

    # Update config with source line
    echo ""
    print_info "Updating shell config..."
    if ! update_config "$config_file" "$shell_type"; then
        print_error "Failed to update config file"
        exit 1
    fi

    # TODO: Additional installation steps will be added in future user stories
    # - Verify installation (US-004)
    # - Print success message (US-004)

    echo ""
    print_success "Installation complete!"
    print_info "Restart your shell or run: source $config_file"
}

# Run main function
main "$@"
