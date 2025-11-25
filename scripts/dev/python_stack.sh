#!/bin/bash
# python_stack.sh - Python and AI/ML stack installation for BrainVault Elite

install_python() {
    log_section "🐍 Installing Python Stack"
    
    if is_dryrun; then
        add_dryrun_operation "PYTHON" "Install Python 3 and pip"
        add_dryrun_operation "PYTHON" "Install virtual environment tools"
        return 0
    fi
    
    # Install Python and essential packages
    local python_packages=(
        "python3"
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "python-is-python3"
    )
    
    log_info "Installing Python packages..."
    for package in "${python_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            safe_exec "Installing $package" apt-get install -y "$package" || log_warn "Failed to install $package"
        else
            log_debug "$package already installed"
        fi
    done
    
    # Verify installation
    if command_exists python3; then
        log_success "Python installed: $(python3 --version)"
        log_info "pip version: $(pip3 --version 2>/dev/null || echo 'N/A')"
    else
        log_error "Python installation failed"
        return 1
    fi
    
    # Upgrade pip
    upgrade_pip
}

upgrade_pip() {
    log_info "Upgrading pip..."
    
    if is_dryrun; then
        add_dryrun_operation "PYTHON" "Upgrade pip to latest version"
        return 0
    fi
    
    safe_exec "Upgrading pip" python3 -m pip install --upgrade pip || log_warn "Failed to upgrade pip"
}

install_python_ml_stack() {
    log_section "🤖 Installing Python AI/ML Stack"
    
    if [[ "${SKIP_AI:-0}" == "1" ]]; then
        log_warn "Skipping AI stack (--skip-ai flag)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "AI/ML" "Install PyTorch (CPU version)"
        add_dryrun_operation "AI/ML" "Install Transformers library"
        add_dryrun_operation "AI/ML" "Install Jupyter and scientific packages"
        return 0
    fi
    
    log_info "Installing AI/ML packages (this may take several minutes)..."
    
    # Install PyTorch CPU version
    install_pytorch_cpu
    
    # Install Transformers and related
    install_transformers
    
    # Install scientific computing packages
    install_scientific_packages
    
    # Install Jupyter
    install_jupyter
    
    log_success "Python AI/ML stack installed"
}

install_pytorch_cpu() {
    log_info "Installing PyTorch (CPU version)..."
    
    if python3 -c "import torch" 2>/dev/null; then
        log_info "PyTorch is already installed"
        return 0
    fi
    
    # Install PyTorch CPU version
    safe_exec "Installing PyTorch" pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu || {
        log_error "Failed to install PyTorch"
        return 1
    }
    
    # Verify installation
    if python3 -c "import torch; print(f'PyTorch {torch.__version__}')" 2>/dev/null; then
        log_success "PyTorch installed successfully"
    else
        log_error "PyTorch installation verification failed"
        return 1
    fi
}

install_transformers() {
    log_info "Installing Transformers library..."
    
    local ml_packages=(
        "transformers"
        "datasets"
        "tokenizers"
        "accelerate"
        "sentencepiece"
        "protobuf"
    )
    
    for package in "${ml_packages[@]}"; do
        safe_exec "Installing $package" pip3 install "$package" || log_warn "Failed to install $package"
    done
    
    log_success "Transformers library installed"
}

install_scientific_packages() {
    log_info "Installing scientific computing packages..."
    
    local sci_packages=(
        "numpy"
        "pandas"
        "scipy"
        "matplotlib"
        "seaborn"
        "scikit-learn"
        "pillow"
        "opencv-python-headless"
    )
    
    for package in "${sci_packages[@]}"; do
        safe_exec "Installing $package" pip3 install "$package" || log_warn "Failed to install $package"
    done
    
    log_success "Scientific packages installed"
}

install_jupyter() {
    log_info "Installing Jupyter..."
    
    if command_exists jupyter; then
        log_info "Jupyter is already installed"
        return 0
    fi
    
    local jupyter_packages=(
        "jupyter"
        "jupyterlab"
        "notebook"
        "ipywidgets"
    )
    
    for package in "${jupyter_packages[@]}"; do
        safe_exec "Installing $package" pip3 install "$package" || log_warn "Failed to install $package"
    done
    
    if command_exists jupyter; then
        log_success "Jupyter installed: $(jupyter --version 2>&1 | head -1)"
        log_info "Start Jupyter Lab with: jupyter lab --ip=0.0.0.0 --no-browser"
    else
        log_error "Jupyter installation failed"
        return 1
    fi
}

# Install common Python development tools
install_python_dev_tools() {
    log_info "Installing Python development tools..."
    
    if is_dryrun; then
        add_dryrun_operation "PYTHON" "Install Python dev tools (black, ruff, mypy)"
        return 0
    fi
    
    local dev_tools=(
        "black"
        "ruff"
        "mypy"
        "pytest"
        "pytest-cov"
        "ipython"
        "poetry"
    )
    
    for tool in "${dev_tools[@]}"; do
        safe_exec "Installing $tool" pip3 install "$tool" || log_warn "Failed to install $tool"
    done
    
    log_success "Python development tools installed"
}

# Install popular Python libraries
install_popular_python_libraries() {
    log_info "Installing popular Python libraries..."
    
    if is_dryrun; then
        add_dryrun_operation "PYTHON" "Install popular libraries"
        return 0
    fi
    
    local popular_libs=(
        "requests"
        "beautifulsoup4"
        "lxml"
        "httpx"
        "aiohttp"
        "fastapi"
        "uvicorn"
        "pydantic"
        "python-dotenv"
        "rich"
        "typer"
    )
    
    for lib in "${popular_libs[@]}"; do
        safe_exec "Installing $lib" pip3 install "$lib" || log_warn "Failed to install $lib"
    done
    
    log_success "Popular Python libraries installed"
}

# Create a sample Python ML environment
create_ml_venv() {
    log_info "Creating sample ML virtual environment..."
    
    if is_dryrun; then
        add_dryrun_operation "PYTHON" "Create ML virtual environment at ~/ml-env"
        return 0
    fi
    
    local venv_path="$HOME/ml-env"
    
    if [[ -d "$venv_path" ]]; then
        log_info "ML environment already exists at $venv_path"
        return 0
    fi
    
    python3 -m venv "$venv_path" || {
        log_error "Failed to create virtual environment"
        return 1
    }
    
    log_success "ML virtual environment created at $venv_path"
    log_info "Activate with: source $venv_path/bin/activate"
}

# Show Python environment info
show_python_info() {
    log_section "🐍 Python Environment Information"
    
    echo ""
    echo "Python Version: $(python3 --version 2>&1)"
    echo "pip Version: $(pip3 --version 2>&1 | head -1)"
    echo ""
    
    if python3 -c "import torch" 2>/dev/null; then
        echo "PyTorch: $(python3 -c 'import torch; print(torch.__version__)')"
    else
        echo "PyTorch: Not installed"
    fi
    
    if python3 -c "import transformers" 2>/dev/null; then
        echo "Transformers: $(python3 -c 'import transformers; print(transformers.__version__)')"
    else
        echo "Transformers: Not installed"
    fi
    
    if command_exists jupyter; then
        echo "Jupyter: $(jupyter --version 2>&1 | head -1)"
    else
        echo "Jupyter: Not installed"
    fi
    
    echo ""
}

# Export functions
export -f install_python
export -f upgrade_pip
export -f install_python_ml_stack
export -f install_pytorch_cpu
export -f install_transformers
export -f install_scientific_packages
export -f install_jupyter
export -f install_python_dev_tools
export -f install_popular_python_libraries
export -f create_ml_venv
export -f show_python_info
