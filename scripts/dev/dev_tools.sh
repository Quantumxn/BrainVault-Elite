#!/bin/bash
# dev_tools.sh - Development tools installation for BrainVault Elite

install_essential_dev_tools() {
    log_section "🛠️ Installing Essential Development Tools"
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install build-essential, git, curl, wget"
        add_dryrun_operation "DEV TOOLS" "Install vim, htop, tmux"
        add_dryrun_operation "DEV TOOLS" "Install development libraries"
        return 0
    fi
    
    # Update package list
    safe_exec "Updating package list" apt-get update
    
    # Essential build tools
    local essential_packages=(
        "build-essential"
        "git"
        "curl"
        "wget"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    
    log_info "Installing essential packages..."
    for package in "${essential_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            safe_exec "Installing $package" apt-get install -y "$package"
        else
            log_debug "$package already installed"
        fi
    done
    
    log_success "Essential development tools installed"
}

install_cli_tools() {
    log_info "Installing CLI productivity tools..."
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install vim, tmux, htop, tree"
        return 0
    fi
    
    local cli_tools=(
        "vim"
        "tmux"
        "htop"
        "tree"
        "jq"
        "ripgrep"
        "fd-find"
        "silversearcher-ag"
        "ncdu"
        "unzip"
        "zip"
    )
    
    for tool in "${cli_tools[@]}"; do
        if ! command_exists "${tool%%-*}"; then
            safe_exec "Installing $tool" apt-get install -y "$tool" || log_warn "Failed to install $tool"
        else
            log_debug "$tool already installed"
        fi
    done
    
    log_success "CLI tools installed"
}

install_development_libraries() {
    log_info "Installing development libraries..."
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install development libraries"
        return 0
    fi
    
    local dev_libs=(
        "libssl-dev"
        "libffi-dev"
        "libxml2-dev"
        "libxslt1-dev"
        "zlib1g-dev"
        "libbz2-dev"
        "libreadline-dev"
        "libsqlite3-dev"
        "llvm"
        "libncurses5-dev"
        "libncursesw5-dev"
        "xz-utils"
        "tk-dev"
        "liblzma-dev"
    )
    
    for lib in "${dev_libs[@]}"; do
        safe_exec "Installing $lib" apt-get install -y "$lib" || log_warn "Failed to install $lib"
    done
    
    log_success "Development libraries installed"
}

# Install Node.js via nvm (for user)
install_nodejs() {
    log_info "Installing Node.js..."
    
    if command_exists node; then
        log_info "Node.js is already installed: $(node --version)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install Node.js LTS via NodeSource"
        return 0
    fi
    
    # Install via NodeSource repository
    log_info "Adding NodeSource repository..."
    
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - || {
        log_error "Failed to add NodeSource repository"
        return 1
    }
    
    safe_exec "Installing Node.js" apt-get install -y nodejs
    
    if command_exists node; then
        log_success "Node.js installed: $(node --version)"
        log_info "npm version: $(npm --version)"
    else
        log_error "Node.js installation failed"
        return 1
    fi
}

# Install Rust
install_rust() {
    log_info "Installing Rust..."
    
    if command_exists rustc; then
        log_info "Rust is already installed: $(rustc --version)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install Rust via rustup"
        return 0
    fi
    
    # Install Rust via rustup
    log_info "Downloading and installing Rust..."
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || {
        log_error "Failed to install Rust"
        return 1
    }
    
    # Source cargo env
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    if command_exists rustc; then
        log_success "Rust installed: $(rustc --version)"
    else
        log_warn "Rust installed but not in PATH. Run: source ~/.cargo/env"
    fi
}

# Install Go
install_golang() {
    log_info "Installing Go..."
    
    if command_exists go; then
        log_info "Go is already installed: $(go version)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install Go programming language"
        return 0
    fi
    
    local go_version="1.21.5"
    local go_archive="go${go_version}.linux-amd64.tar.gz"
    local go_url="https://go.dev/dl/${go_archive}"
    
    log_info "Downloading Go ${go_version}..."
    
    cd /tmp || return 1
    wget -q "$go_url" || {
        log_error "Failed to download Go"
        return 1
    }
    
    # Remove old installation
    rm -rf /usr/local/go
    
    # Extract new version
    tar -C /usr/local -xzf "$go_archive"
    
    # Add to PATH
    if ! grep -q '/usr/local/go/bin' /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    
    # Cleanup
    rm -f "$go_archive"
    
    if command_exists go; then
        log_success "Go installed: $(go version)"
    else
        log_warn "Go installed but not in PATH. Run: export PATH=\$PATH:/usr/local/go/bin"
    fi
}

# Configure git
configure_git() {
    log_info "Configuring git..."
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Configure git with sensible defaults"
        return 0
    fi
    
    # Set sensible defaults
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.autocrlf input 2>/dev/null || true
    
    log_success "Git configured with sensible defaults"
}

# Install modern CLI tools
install_modern_cli_tools() {
    log_info "Installing modern CLI tools..."
    
    if is_dryrun; then
        add_dryrun_operation "DEV TOOLS" "Install bat, exa, fzf"
        return 0
    fi
    
    # bat (better cat)
    if ! command_exists bat; then
        safe_exec "Installing bat" apt-get install -y bat || log_warn "Failed to install bat"
        # Create symlink if batcat is installed instead
        if command_exists batcat && ! command_exists bat; then
            ln -sf "$(which batcat)" /usr/local/bin/bat 2>/dev/null || true
        fi
    fi
    
    # exa (better ls)
    if ! command_exists exa; then
        safe_exec "Installing exa" apt-get install -y exa || log_warn "Failed to install exa"
    fi
    
    # fzf (fuzzy finder)
    if ! command_exists fzf; then
        safe_exec "Installing fzf" apt-get install -y fzf || {
            log_info "Installing fzf from git..."
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
            ~/.fzf/install --all 2>/dev/null || true
        }
    fi
    
    log_success "Modern CLI tools installed"
}

# Export functions
export -f install_essential_dev_tools
export -f install_cli_tools
export -f install_development_libraries
export -f install_nodejs
export -f install_rust
export -f install_golang
export -f configure_git
export -f install_modern_cli_tools
