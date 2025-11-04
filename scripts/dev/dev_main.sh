#!/bin/bash
# dev_main.sh - Main development stack orchestrator for BrainVault Elite

setup_dev_stack() {
    log_section "🛠️ DEVELOPMENT STACK INSTALLATION"
    
    if [[ "${SKIP_DEV:-0}" == "1" ]]; then
        log_warn "Skipping development stack (--skip-dev flag)"
        return 0
    fi
    
    # Install essential development tools
    install_essential_dev_tools
    install_cli_tools
    install_development_libraries
    install_modern_cli_tools
    
    # Configure git
    configure_git
    
    # Install programming languages
    install_python
    install_python_dev_tools
    
    # Install AI/ML stack
    if [[ "${SKIP_AI:-0}" != "1" ]]; then
        install_python_ml_stack
        create_ml_venv
    fi
    
    # Install additional languages (optional)
    if [[ "${INSTALL_ALL_LANGS:-0}" == "1" ]]; then
        install_nodejs
        install_rust
        install_golang
    fi
    
    # Install container tools
    if [[ "${SKIP_DOCKER:-0}" != "1" ]]; then
        install_docker
        test_docker
        install_container_security_tools
    fi
    
    log_success "Development stack installation completed"
}

# Quick dev setup (minimal)
quick_dev_setup() {
    log_section "⚡ QUICK DEVELOPMENT SETUP"
    
    log_info "Installing minimal development environment..."
    
    # Only essentials
    install_essential_dev_tools
    install_python
    configure_git
    
    log_success "Quick development setup completed"
}

# Full dev setup (everything)
full_dev_setup() {
    log_section "🚀 FULL DEVELOPMENT SETUP"
    
    log_info "Installing complete development environment..."
    
    # Everything
    install_essential_dev_tools
    install_cli_tools
    install_development_libraries
    install_modern_cli_tools
    
    configure_git
    
    install_python
    install_python_dev_tools
    install_python_ml_stack
    install_popular_python_libraries
    create_ml_venv
    
    install_nodejs
    install_rust
    install_golang
    
    install_docker
    test_docker
    install_podman
    install_container_security_tools
    
    log_success "Full development setup completed"
}

# AI-focused setup
ai_focused_setup() {
    log_section "🤖 AI-FOCUSED DEVELOPMENT SETUP"
    
    log_info "Installing AI/ML development environment..."
    
    # Essentials
    install_essential_dev_tools
    install_development_libraries
    
    # Python stack
    install_python
    install_python_dev_tools
    
    # AI/ML packages
    install_python_ml_stack
    create_ml_venv
    
    # Docker for containerized deployments
    install_docker
    test_docker
    
    log_success "AI-focused setup completed"
}

# Show development environment status
show_dev_status() {
    log_section "🛠️ DEVELOPMENT ENVIRONMENT STATUS"
    
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║       DEVELOPMENT TOOLS STATUS                 ║"
    echo "╠════════════════════════════════════════════════╣"
    
    # Essential tools
    if command_exists git; then
        echo "║ ✓ Git                       [$(git --version | cut -d' ' -f3)] ║"
    else
        echo "║ ✗ Git                       [NOT INSTALLED]   ║"
    fi
    
    if command_exists python3; then
        echo "║ ✓ Python                    [$(python3 --version | cut -d' ' -f2)] ║"
    else
        echo "║ ✗ Python                    [NOT INSTALLED]   ║"
    fi
    
    if command_exists node; then
        echo "║ ✓ Node.js                   [$(node --version)]     ║"
    else
        echo "║ ✗ Node.js                   [NOT INSTALLED]   ║"
    fi
    
    if command_exists docker; then
        echo "║ ✓ Docker                    [INSTALLED]       ║"
    else
        echo "║ ✗ Docker                    [NOT INSTALLED]   ║"
    fi
    
    if command_exists rustc; then
        echo "║ ✓ Rust                      [INSTALLED]       ║"
    else
        echo "║ ✗ Rust                      [NOT INSTALLED]   ║"
    fi
    
    if command_exists go; then
        echo "║ ✓ Go                        [INSTALLED]       ║"
    else
        echo "║ ✗ Go                        [NOT INSTALLED]   ║"
    fi
    
    echo "╠════════════════════════════════════════════════╣"
    echo "║       AI/ML LIBRARIES STATUS                   ║"
    echo "╠════════════════════════════════════════════════╣"
    
    if python3 -c "import torch" 2>/dev/null; then
        echo "║ ✓ PyTorch                   [INSTALLED]       ║"
    else
        echo "║ ✗ PyTorch                   [NOT INSTALLED]   ║"
    fi
    
    if python3 -c "import transformers" 2>/dev/null; then
        echo "║ ✓ Transformers              [INSTALLED]       ║"
    else
        echo "║ ✗ Transformers              [NOT INSTALLED]   ║"
    fi
    
    if command_exists jupyter; then
        echo "║ ✓ Jupyter                   [INSTALLED]       ║"
    else
        echo "║ ✗ Jupyter                   [NOT INSTALLED]   ║"
    fi
    
    echo "╚════════════════════════════════════════════════╝"
    echo ""
}

# Verify development environment
verify_dev_environment() {
    log_section "✅ VERIFYING DEVELOPMENT ENVIRONMENT"
    
    local errors=0
    
    # Check essential tools
    local essential_tools=("git" "python3" "pip3" "curl" "wget")
    
    for tool in "${essential_tools[@]}"; do
        if command_exists "$tool"; then
            log_success "$tool is available"
        else
            log_error "$tool is NOT available"
            ((errors++))
        fi
    done
    
    # Check Python packages
    if python3 -c "import pip" 2>/dev/null; then
        log_success "pip module is available"
    else
        log_error "pip module is NOT available"
        ((errors++))
    fi
    
    # Summary
    if [[ $errors -eq 0 ]]; then
        log_success "Development environment verification passed"
        return 0
    else
        log_error "Development environment verification failed with $errors error(s)"
        return 1
    fi
}

# Update all development tools
update_dev_tools() {
    log_section "🔄 UPDATING DEVELOPMENT TOOLS"
    
    if is_dryrun; then
        add_dryrun_operation "DEV" "Update all development tools"
        return 0
    fi
    
    log_info "Updating system packages..."
    safe_exec "Updating packages" apt-get update
    safe_exec "Upgrading packages" apt-get upgrade -y
    
    log_info "Updating Python packages..."
    pip3 list --outdated 2>/dev/null || true
    
    if command_exists docker; then
        log_info "Pulling latest Docker images..."
        docker pull hello-world || true
    fi
    
    if command_exists rustup; then
        log_info "Updating Rust..."
        rustup update || true
    fi
    
    log_success "Development tools updated"
}

# Export functions
export -f setup_dev_stack
export -f quick_dev_setup
export -f full_dev_setup
export -f ai_focused_setup
export -f show_dev_status
export -f verify_dev_environment
export -f update_dev_tools
