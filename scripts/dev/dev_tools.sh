#!/bin/bash
# Development tools installation script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_dev_tools() {
    log_section "Installing Development Tools"
    
    local packages=(
        "build-essential"
        "git"
        "curl"
        "wget"
        "vim"
        "nano"
        "htop"
        "tree"
        "unzip"
        "zip"
        "jq"
        "tmux"
        "screen"
    )
    
    local missing_packages=()
    
    # Check dependencies
    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "Installing development tools..."
        for pkg in "${missing_packages[@]}"; do
            dryrun_install "$pkg" "Dev tool: $pkg"
        done
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y "${missing_packages[@]}"
        fi
    else
        log_success "Development tools already installed"
    fi
    
    # Verify critical tools
    local critical_tools=("git" "curl" "gcc" "make")
    for tool in "${critical_tools[@]}"; do
        if [[ "$DRY_RUN" != "1" ]] && ! command_exists "$tool"; then
            log_error "$tool installation failed"
            return 1
        fi
    done
    
    log_success "Development tools installation completed"
}

setup_dev_tools() {
    log_section "Configuring Development Tools"
    
    # Check if dev tools are installed
    if ! command_exists git || ! command_exists gcc; then
        log_error "Development tools not installed. Run install_dev_tools first."
        return 1
    fi
    
    log_step "Configuring Git defaults"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would configure Git defaults"
    else
        # Only set if not already configured
        if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
            git config --global init.defaultBranch main
            log_info "Git default branch set to 'main'"
        fi
    fi
    
    log_step "Setting up development directories"
    local dev_dirs=("$HOME/projects" "$HOME/dev" "$HOME/code")
    for dir in "${dev_dirs[@]}"; do
        if [[ "$DRY_RUN" == "1" ]]; then
            log_warn "[DRY-RUN] Would create directory: $dir"
        else
            mkdir -p "$dir"
        fi
    done
    
    log_success "Development tools configuration completed"
}

check_dev_tools_status() {
    log_info "Development Tools Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        local tools=("git" "curl" "wget" "vim" "gcc" "make" "python3")
        for tool in "${tools[@]}"; do
            if command_exists "$tool"; then
                local version=$($tool --version 2>/dev/null | head -n1 || echo "installed")
                log_success "$tool: $version"
            else
                log_warn "$tool: not installed"
            fi
        done
    else
        log_warn "[DRY-RUN] Would check development tools status"
    fi
}
