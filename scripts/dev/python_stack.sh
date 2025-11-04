#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Python AI Stack Module
# ================================================================

install_python_stack() {
    local desc="Installing Python AI stack"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Development" "install_python_stack" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Upgrade pip and install base packages
    run_cmd "pip3 install --upgrade pip wheel setuptools" \
        "Upgrading pip and base packages" || {
        log_error "Failed to upgrade pip"
        return 1
    }
    
    # Install core AI/ML packages
    local python_packages=(
        "torch"
        "torchvision"
        "transformers"
        "pandas"
        "numpy"
        "scipy"
        "scikit-learn"
        "matplotlib"
        "seaborn"
        "jupyterlab"
        "notebook"
        "ipython"
    )
    
    log_info "Installing Python packages (this may take a while)..."
    for pkg in "${python_packages[@]}"; do
        run_cmd "pip3 install $pkg" "Installing $pkg" "" "false" || {
            log_warn "Failed to install $pkg, continuing..."
        }
    done
    
    # Alternative: Install all at once (faster but less granular error handling)
    # run_cmd "pip3 install ${python_packages[*]}" "Installing Python AI packages"
    
    log_success "Python AI stack installation complete"
    mark_module_loaded "python_stack"
    return 0
}
