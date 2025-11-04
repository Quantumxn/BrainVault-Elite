#!/bin/bash
# integrity.sh - File integrity monitoring for BrainVault Elite

install_aide() {
    log_section "🔍 Installing AIDE (File Integrity Monitoring)"
    
    if command_exists aide; then
        log_info "AIDE is already installed"
    else
        if is_dryrun; then
            add_dryrun_operation "SECURITY" "Install AIDE"
        else
            safe_exec "Installing AIDE" apt-get install -y aide aide-common
        fi
    fi
    
    configure_aide
}

configure_aide() {
    log_info "Configuring AIDE..."
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Initialize AIDE database"
        add_dryrun_operation "SECURITY" "Configure AIDE monitoring"
        return 0
    fi
    
    # Check if database exists
    if [[ ! -f /var/lib/aide/aide.db ]]; then
        log_info "Initializing AIDE database (this may take several minutes)..."
        safe_exec "Initializing AIDE" aideinit || {
            log_warn "AIDE initialization failed, trying manual init..."
            aide --init && cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        }
        log_success "AIDE database initialized"
    else
        log_info "AIDE database already exists"
    fi
    
    # Create custom AIDE configuration
    create_aide_config
    
    log_success "AIDE configured successfully"
}

create_aide_config() {
    log_info "Creating custom AIDE configuration..."
    
    local aide_conf="/etc/aide/aide.conf.d/99_brainvault"
    
    cat > "$aide_conf" <<'EOF'
# BrainVault Elite - Custom AIDE Rules

# Monitor critical system directories
/bin CONTENT_EX
/sbin CONTENT_EX
/usr/bin CONTENT_EX
/usr/sbin CONTENT_EX
/lib CONTENT_EX
/lib64 CONTENT_EX

# Monitor system configuration
/etc CONTENT_EX
!/etc/mtab
!/etc/resolv.conf

# Monitor boot files
/boot CONTENT_EX

# Monitor user homes (selective)
/root CONTENT_EX

# Exclude frequently changing directories
!/var/log
!/var/cache
!/var/tmp
!/tmp
!/proc
!/sys
!/dev
!/run
EOF
    
    log_success "Custom AIDE configuration created"
}

# Run AIDE check
run_aide_check() {
    log_info "Running AIDE integrity check..."
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Run AIDE integrity check"
        return 0
    fi
    
    if ! command_exists aide; then
        log_error "AIDE is not installed"
        return 1
    fi
    
    local check_output
    check_output=$(aide --check 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "AIDE check: No changes detected"
    else
        log_warn "AIDE detected changes:"
        echo "$check_output" | tail -20
        log_info "Full report available via: aide --check"
    fi
    
    return $exit_code
}

# Update AIDE database
update_aide_database() {
    log_info "Updating AIDE database..."
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Update AIDE database"
        return 0
    fi
    
    safe_exec "Updating AIDE database" aide --update
    
    if [[ -f /var/lib/aide/aide.db.new ]]; then
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        log_success "AIDE database updated"
    else
        log_error "Failed to update AIDE database"
        return 1
    fi
}

# Install chkrootkit
install_chkrootkit() {
    log_section "🔐 Installing chkrootkit (Rootkit Detection)"
    
    if command_exists chkrootkit; then
        log_info "chkrootkit is already installed"
    else
        if is_dryrun; then
            add_dryrun_operation "SECURITY" "Install chkrootkit"
        else
            safe_exec "Installing chkrootkit" apt-get install -y chkrootkit
        fi
    fi
    
    log_success "chkrootkit ready"
}

# Run chkrootkit scan
run_chkrootkit() {
    log_info "Running chkrootkit scan..."
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Run chkrootkit scan"
        return 0
    fi
    
    if ! command_exists chkrootkit; then
        log_error "chkrootkit is not installed"
        return 1
    fi
    
    log_info "Starting rootkit scan (this may take a few minutes)..."
    
    local scan_output
    scan_output=$(chkrootkit 2>&1)
    
    # Check for infections
    if echo "$scan_output" | grep -i "INFECTED" >/dev/null; then
        log_error "chkrootkit detected potential rootkit!"
        echo "$scan_output" | grep -i "INFECTED"
        log_warn "Please investigate immediately"
        return 1
    else
        log_success "chkrootkit scan: No rootkits detected"
    fi
    
    return 0
}

# Install rkhunter (alternative rootkit scanner)
install_rkhunter() {
    log_info "Installing rkhunter..."
    
    if command_exists rkhunter; then
        log_info "rkhunter is already installed"
    else
        if is_dryrun; then
            add_dryrun_operation "SECURITY" "Install rkhunter"
        else
            safe_exec "Installing rkhunter" apt-get install -y rkhunter
        fi
    fi
    
    # Update rkhunter database
    if ! is_dryrun && command_exists rkhunter; then
        safe_exec "Updating rkhunter database" rkhunter --update
        safe_exec "Updating rkhunter properties" rkhunter --propupd
    fi
    
    log_success "rkhunter configured"
}

# Run comprehensive integrity check
run_full_integrity_check() {
    log_section "🔍 Running Full Integrity Check"
    
    # Run AIDE
    run_aide_check
    
    # Run chkrootkit
    if command_exists chkrootkit; then
        run_chkrootkit
    fi
    
    # Run rkhunter
    if command_exists rkhunter; then
        log_info "Running rkhunter scan..."
        if ! is_dryrun; then
            rkhunter --check --skip-keypress --report-warnings-only || true
        fi
    fi
    
    log_success "Full integrity check completed"
}

# Export functions
export -f install_aide
export -f configure_aide
export -f create_aide_config
export -f run_aide_check
export -f update_aide_database
export -f install_chkrootkit
export -f run_chkrootkit
export -f install_rkhunter
export -f run_full_integrity_check
