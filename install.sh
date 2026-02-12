#!/usr/bin/env bash
#
# Groundskeeper Willie Installer
#
# One-line installation:
#   curl -fsSL https://raw.githubusercontent.com/CKristensen/groundskeeper-willie/master/install.sh | bash
#
# Or run locally from repository:
#   ./install.sh
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

# Download a file using curl or wget (fallback)
# Args: url, output_path
download_file() {
    local url="$1"
    local output_path="$2"

    # Try curl first (more common in one-line installations)
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$url" -o "$output_path"; then
            return 0
        else
            return 1
        fi
    # Fallback to wget
    elif command -v wget >/dev/null 2>&1; then
        if wget -q -O "$output_path" "$url"; then
            return 0
        else
            return 1
        fi
    else
        print_error "Neither curl nor wget is available. Please install one of them."
        return 1
    fi
}

# Verify downloaded file is valid shell code
# Args: file_path
verify_shell_file() {
    local file_path="$1"

    # Check file exists and is not empty
    if [[ ! -f "$file_path" ]]; then
        print_error "Downloaded file not found: $file_path"
        return 1
    fi

    if [[ ! -s "$file_path" ]]; then
        print_error "Downloaded file is empty: $file_path"
        return 1
    fi

    # Basic validation: check for shell shebang or function keyword
    # This catches obvious download failures (HTML error pages, etc.)
    if head -n 20 "$file_path" | grep -qE '(^#!|function |^function)'; then
        return 0
    else
        print_error "Downloaded file does not appear to be valid shell code: $file_path"
        print_info "This may indicate a network issue or incorrect URL."
        return 1
    fi
}

# Install the functions file to ~/.groundskeeper-willie/
# Downloads from GitHub or copies from local repo if available
# Args: shell_type
install_functions_file() {
    local shell_type="$1"
    local install_dir="$HOME/.groundskeeper-willie"
    local functions_file=""
    local target_file=""

    # GitHub repository information
    local github_user="CKristensen"
    local github_repo="groundskeeper-willie"
    local github_ref="master"  # Use master branch by default
    local base_url="https://raw.githubusercontent.com/${github_user}/${github_repo}/${github_ref}"

    # Determine which functions file to install
    if [[ "$shell_type" == "fish" ]]; then
        functions_file="worktree-agent-functions.fish"
    else
        functions_file="worktree-agent-functions.sh"
    fi

    target_file="$install_dir/$functions_file"

    # Create installation directory if it doesn't exist
    if [[ ! -d "$install_dir" ]]; then
        if ! mkdir -p "$install_dir"; then
            print_error "Failed to create directory: $install_dir"
            return 1
        fi
    fi

    # Try to download from GitHub
    print_info "Downloading $functions_file from GitHub..."
    local download_url="${base_url}/${functions_file}"

    if download_file "$download_url" "$target_file"; then
        # Verify the downloaded file
        if verify_shell_file "$target_file"; then
            # Make it executable
            if ! chmod +x "$target_file"; then
                print_error "Failed to make $target_file executable"
                return 1
            fi
            print_success "Downloaded and installed: $target_file"
            return 0
        else
            # Verification failed, remove invalid file
            rm -f "$target_file"
            print_error "Downloaded file failed validation"
            return 1
        fi
    else
        print_error "Failed to download from $download_url"
        print_info "Please check your internet connection and try again."

        # Fallback: try local copy if we're in a git repo
        if [[ -f "$functions_file" ]]; then
            print_info "Attempting to install from local repository..."
            if cp "$functions_file" "$target_file" && chmod +x "$target_file"; then
                print_success "Installed from local copy: $target_file"
                return 0
            fi
        fi

        return 1
    fi
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

# Verify that installation succeeded by testing if willie function is loadable
# Args: shell_type
# Returns: 0 if verification succeeds, 1 if it fails
verify_installation() {
    local shell_type="$1"
    local functions_path="$HOME/.groundskeeper-willie/worktree-agent-functions"

    # Determine the correct functions file extension
    if [[ "$shell_type" == "fish" ]]; then
        functions_path="${functions_path}.fish"
    else
        functions_path="${functions_path}.sh"
    fi

    # Try to source the functions file in a subshell and check if willie exists
    if [[ "$shell_type" == "fish" ]]; then
        # For fish shell, test if the function file is valid
        if fish -c "source $functions_path; functions -q willie" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    else
        # For bash/zsh, source and test in a subshell
        if bash -c "source '$functions_path' && type willie" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi
}

# Print success message with next steps and usage guidance
# Args: shell_type, config_file
print_success_message() {
    local shell_type="$1"
    local config_file="$2"
    local github_repo_url="https://github.com/CKristensen/groundskeeper-willie"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "Groundskeeper Willie is installed and ready!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    print_info "Next Steps:"
    echo ""

    echo "1. Activate the installation:"
    echo ""
    if [[ "$shell_type" == "fish" ]]; then
        echo "   Restart your fish shell, or run:"
        echo "   ${YELLOW}source $config_file${NC}"
    else
        echo "   Restart your shell, or run:"
        echo "   ${YELLOW}source $config_file${NC}"
    fi
    echo ""

    echo "2. Verify installation:"
    echo ""
    echo "   ${YELLOW}type willie${NC}"
    echo ""
    echo "   You should see: \"willie is a function\""
    echo ""

    echo "3. Try your first command:"
    echo ""
    echo "   ${YELLOW}willie PCT-123${NC}"
    echo ""
    echo "   Or for autonomous development:"
    echo "   ${YELLOW}willie --next${NC}"
    echo ""

    print_info "Quick Start:"
    echo ""
    echo "  ${YELLOW}willie <task-id>${NC}     Create worktree and launch Claude Code"
    echo "  ${YELLOW}willie --next${NC}        Auto-launch next ticket from prd.json"
    echo "  ${YELLOW}willie --status${NC}      List all active worktrees"
    echo "  ${YELLOW}willie --clean <id>${NC}  Remove a worktree"
    echo "  ${YELLOW}willie --help${NC}        Show detailed help"
    echo ""

    print_info "Documentation:"
    echo ""
    echo "  ${github_repo_url}#quick-start"
    echo ""

    print_info "Uninstall Instructions:"
    echo ""
    echo "  1. Remove the source line from: $config_file"
    echo "     (Look for lines between '# >>> groundskeeper-willie >>>')"
    echo ""
    echo "  2. If needed, restore from backup:"
    echo "     ${YELLOW}cp ${config_file}.backup.* $config_file${NC}"
    echo ""
    echo "  3. Remove installed files:"
    echo "     ${YELLOW}rm -rf ~/.groundskeeper-willie${NC}"
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_success "Happy coding with Groundskeeper Willie!"
    echo ""
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

    # Verify installation
    echo ""
    print_info "Verifying installation..."
    if verify_installation "$shell_type"; then
        print_success "Installation verified successfully"
    else
        print_error "Installation verification failed"
        print_info "The functions file was installed but couldn't be loaded."
        print_info "This may be a shell compatibility issue."
        print_info "Try manually sourcing: source $config_file"
        exit 1
    fi

    # Print success message with next steps
    print_success_message "$shell_type" "$config_file"
}

# Run main function
main "$@"
