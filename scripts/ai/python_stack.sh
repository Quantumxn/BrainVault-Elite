#!/bin/bash
# ================================================================
# BrainVault Elite - Python AI Stack Installation
# PyTorch, TensorFlow, Transformers, and ML tools
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Python Development Tools =============

install_python_dev() {
    log_section "Installing Python Development Tools"
    
    local python_packages=(
        python3
        python3-pip
        python3-venv
        python3-dev
        python-is-python3
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "AI Stack" "Install Python development tools: ${python_packages[*]}"
        return 0
    fi
    
    install_pkg "${python_packages[@]}"
    
    # Upgrade pip
    log_info "Upgrading pip, wheel, and setuptools..."
    run_cmd "python3 -m pip install --upgrade pip wheel setuptools" "Upgrade Python build tools" false
    
    log_success "Python development tools installed"
}

# ============= Machine Learning Libraries =============

install_ml_libraries() {
    log_section "Installing Machine Learning Libraries"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "AI Stack" "Install PyTorch, transformers, scikit-learn, pandas, numpy"
        return 0
    fi
    
    log_warn "This may take several minutes..."
    
    # Core ML libraries
    local ml_packages=(
        "torch"
        "torchvision"
        "torchaudio"
        "transformers"
        "accelerate"
        "datasets"
        "scikit-learn"
        "pandas"
        "numpy"
        "scipy"
        "matplotlib"
        "seaborn"
        "jupyter"
        "jupyterlab"
        "ipython"
        "notebook"
    )
    
    log_info "Installing ML packages: ${ml_packages[*]}"
    
    # Install with timeout and error handling
    if python3 -m pip install --no-cache-dir "${ml_packages[@]}" >>"$LOGFILE" 2>&1; then
        log_success "Machine learning libraries installed successfully"
    else
        log_error "Some ML packages failed to install"
        log_info "Attempting to install packages individually..."
        
        for package in "${ml_packages[@]}"; do
            log_info "Installing $package..."
            if python3 -m pip install --no-cache-dir "$package" >>"$LOGFILE" 2>&1; then
                log_success "  ✓ $package"
            else
                log_warn "  ✗ $package (failed)"
            fi
        done
    fi
}

# ============= AI Development Tools =============

install_ai_tools() {
    log_section "Installing AI Development Tools"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "AI Stack" "Install ollama, huggingface-cli, tensorboard"
        return 0
    fi
    
    # Install additional AI tools
    local ai_tools=(
        "huggingface-hub"
        "tensorboard"
        "gradio"
        "streamlit"
        "opencv-python"
        "pillow"
        "wandb"
        "mlflow"
    )
    
    log_info "Installing AI development tools..."
    python3 -m pip install --no-cache-dir "${ai_tools[@]}" >>"$LOGFILE" 2>&1 || \
        log_warn "Some AI tools failed to install"
    
    # Install Ollama (local LLM runtime)
    if ! check_command ollama; then
        log_info "Installing Ollama..."
        if curl -fsSL https://ollama.ai/install.sh | sh >>"$LOGFILE" 2>&1; then
            log_success "Ollama installed successfully"
        else
            log_warn "Ollama installation failed (optional)"
        fi
    else
        log_info "Ollama already installed"
    fi
    
    log_success "AI development tools installed"
}

# ============= GPU Support =============

install_gpu_support() {
    log_section "Checking GPU Support"
    
    # Check if NVIDIA GPU is present
    if ! lspci | grep -i nvidia &>/dev/null; then
        log_info "No NVIDIA GPU detected, skipping CUDA installation"
        return 0
    fi
    
    log_info "NVIDIA GPU detected"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "AI Stack" "Install NVIDIA CUDA drivers and toolkit"
        return 0
    fi
    
    log_warn "GPU support installation requires manual configuration"
    log_info "To install NVIDIA drivers, run:"
    log_info "  sudo ubuntu-drivers autoinstall"
    log_info "  sudo apt install nvidia-cuda-toolkit"
}

# ============= Jupyter Configuration =============

setup_jupyter() {
    log_section "Configuring Jupyter"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "AI Stack" "Generate Jupyter configuration"
        return 0
    fi
    
    log_info "Generating Jupyter configuration..."
    
    # Generate config for the current user (or root if running as root)
    local jupyter_user="${SUDO_USER:-$USER}"
    local jupyter_home
    
    if [[ "$jupyter_user" == "root" ]]; then
        jupyter_home="/root"
    else
        jupyter_home="/home/$jupyter_user"
    fi
    
    log_info "Setting up Jupyter for user: $jupyter_user"
    
    # Run as the target user
    if [[ "$jupyter_user" != "root" ]] && [[ -n "$SUDO_USER" ]]; then
        sudo -u "$jupyter_user" jupyter lab --generate-config 2>/dev/null || \
            log_warn "Could not generate Jupyter config"
    else
        jupyter lab --generate-config 2>/dev/null || \
            log_warn "Could not generate Jupyter config"
    fi
    
    log_info "To start Jupyter Lab, run: jupyter lab"
    log_success "Jupyter configured"
}

# ============= Python AI Stack Summary =============

show_python_stack_info() {
    log_section "Python AI Stack Information"
    
    log_info "Python version: $(python3 --version 2>&1)"
    log_info "Pip version: $(python3 -m pip --version 2>&1 | cut -d' ' -f2)"
    
    local key_packages=("torch" "transformers" "jupyter" "pandas" "numpy")
    
    log_info "Installed packages:"
    for pkg in "${key_packages[@]}"; do
        local version
        version=$(python3 -m pip show "$pkg" 2>/dev/null | grep "Version:" | cut -d' ' -f2)
        if [[ -n "$version" ]]; then
            log_info "  ✓ $pkg ($version)"
        else
            log_info "  ✗ $pkg (not installed)"
        fi
    done
}

# Export functions
export -f install_python_dev install_ml_libraries install_ai_tools
export -f install_gpu_support setup_jupyter show_python_stack_info
