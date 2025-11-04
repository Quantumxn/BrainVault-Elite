#!/bin/bash
# Python AI/ML stack installation script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_python_stack() {
    log_section "Installing Python AI/ML Stack"
    
    # Check Python 3
    if ! command_exists python3; then
        log_info "Installing Python 3..."
        dryrun_install "python3" "Python 3"
        dryrun_install "python3-pip" "Python 3 pip"
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y python3 python3-pip python3-venv python3-dev
        fi
    else
        log_success "Python 3 is already installed"
    fi
    
    # Install pip packages if not in dry-run
    if [[ "$DRY_RUN" != "1" ]]; then
        log_step "Installing Python packages (this may take a while)..."
        
        # Upgrade pip first
        python3 -m pip install --upgrade pip setuptools wheel --quiet
        
        # Core ML/AI packages (CPU-only for compatibility)
        local packages=(
            "torch"  # PyTorch (will auto-detect CPU)
            "transformers"
            "datasets"
            "numpy"
            "pandas"
            "scikit-learn"
            "matplotlib"
            "seaborn"
            "jupyter"
            "notebook"
            "ipython"
            "requests"
            "tqdm"
        )
        
        for pkg in "${packages[@]}"; do
            log_step "Installing $pkg..."
            python3 -m pip install "$pkg" --quiet || log_warn "Failed to install $pkg"
        done
        
        log_success "Python packages installed"
    else
        log_warn "[DRY-RUN] Would install Python packages: torch, transformers, datasets, numpy, pandas, scikit-learn, matplotlib, seaborn, jupyter, notebook, ipython, requests, tqdm"
    fi
    
    # Verify installation
    if [[ "$DRY_RUN" != "1" ]]; then
        if ! python3 -c "import torch" 2>/dev/null; then
            log_warn "PyTorch verification failed (may need manual installation)"
        else
            log_success "PyTorch verified"
        fi
    fi
    
    log_success "Python stack installation completed"
}

setup_python_stack() {
    log_section "Configuring Python AI/ML Stack"
    
    # Check if Python is installed
    if ! command_exists python3; then
        log_error "Python 3 is not installed. Run install_python_stack first."
        return 1
    fi
    
    log_step "Setting up Jupyter configuration"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would configure Jupyter"
    else
        # Create Jupyter config directory
        mkdir -p "$HOME/.jupyter"
        
        # Generate Jupyter config if it doesn't exist
        if [[ ! -f "$HOME/.jupyter/jupyter_notebook_config.py" ]]; then
            jupyter notebook --generate-config --quiet
            log_success "Jupyter configuration generated"
        fi
        
        # Set Jupyter password (optional, skip for now)
        log_info "Jupyter is ready. Use 'jupyter notebook' to start."
    fi
    
    log_step "Creating Python virtual environment template"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create venv template"
    else
        local venv_dir="$HOME/.venv_template"
        if [[ ! -d "$venv_dir" ]]; then
            python3 -m venv "$venv_dir"
            log_success "Virtual environment template created at $venv_dir"
        fi
    fi
    
    log_success "Python stack configuration completed"
}

check_python_stack_status() {
    log_info "Python Stack Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if command_exists python3; then
            local py_version=$(python3 --version)
            log_success "Python: $py_version"
            
            if command_exists pip3; then
                local pip_version=$(pip3 --version | awk '{print $2}')
                log_success "pip: $pip_version"
            fi
            
            # Check key packages
            local packages=("torch" "transformers" "numpy" "pandas" "jupyter")
            for pkg in "${packages[@]}"; do
                if python3 -c "import $pkg" 2>/dev/null; then
                    log_success "$pkg: installed"
                else
                    log_warn "$pkg: not installed"
                fi
            done
        else
            log_warn "Python 3 not installed"
        fi
    else
        log_warn "[DRY-RUN] Would check Python stack status"
    fi
}
