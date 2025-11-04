#!/bin/bash
# System integrity checking (AIDE, chkrootkit) script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_integrity() {
    log_section "Installing Integrity Checking Tools"
    
    local packages=("aide" "chkrootkit")
    local missing_packages=()
    
    # Check dependencies
    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "Installing integrity checking tools..."
        for pkg in "${missing_packages[@]}"; do
            dryrun_install "$pkg" "Integrity tool: $pkg"
        done
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y "${missing_packages[@]}"
        fi
    else
        log_success "Integrity checking tools already installed"
    fi
    
    # Verify installation
    for pkg in "${packages[@]}"; do
        if [[ "$DRY_RUN" != "1" ]] && ! command_exists "${pkg}"; then
            log_error "$pkg installation failed"
            return 1
        fi
    done
    
    log_success "Integrity tools installation completed"
}

setup_integrity() {
    log_section "Configuring Integrity Checking"
    
    # Check if tools are installed
    if ! command_exists aide || ! command_exists chkrootkit; then
        log_error "Integrity tools not installed. Run install_integrity first."
        return 1
    fi
    
    log_step "Initializing AIDE database"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would initialize AIDE database"
    else
        if [[ ! -f /var/lib/aide/aide.db ]]; then
            aideinit
            log_success "AIDE database initialized"
        else
            log_info "AIDE database already exists"
        fi
    fi
    
    log_step "Configuring AIDE cron job"
    local cron_file="/etc/cron.daily/aide-check"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create AIDE cron job: $cron_file"
    else
        cat > "$cron_file" << 'EOF'
#!/bin/bash
/usr/bin/aide --check
EOF
        chmod +x "$cron_file"
        log_success "AIDE cron job configured"
    fi
    
    log_step "Testing chkrootkit"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would test chkrootkit"
    else
        log_info "Running chkrootkit check..."
        chkrootkit -q || log_warn "chkrootkit found potential issues (may be false positives)"
    fi
    
    log_success "Integrity checking configuration completed"
}

check_integrity_status() {
    log_info "Integrity Checking Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if command_exists aide && file_exists /var/lib/aide/aide.db; then
            log_success "AIDE database exists"
        else
            log_warn "AIDE database not initialized"
        fi
        
        if command_exists chkrootkit; then
            log_success "chkrootkit installed"
        else
            log_warn "chkrootkit not installed"
        fi
    else
        log_warn "[DRY-RUN] Would check integrity tools status"
    fi
}
