#!/bin/bash
# System monitoring tools (Netdata, Prometheus) script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_monitoring() {
    log_section "Installing Monitoring Tools"
    
    # Check dependencies
    if ! command_exists curl; then
        log_error "curl is required but not installed"
        return 1
    fi
    
    log_step "Installing Netdata"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would install Netdata"
    else
        if ! command_exists netdata; then
            # Install Netdata via official installer
            bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive --stable-channel
            log_success "Netdata installed"
        else
            log_success "Netdata is already installed"
        fi
    fi
    
    log_step "Installing Prometheus Node Exporter"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would install Prometheus Node Exporter"
    else
        if ! command_exists node_exporter; then
            # Download and install node_exporter
            local node_exporter_version="1.7.0"
            local arch=$(uname -m)
            [[ "$arch" == "x86_64" ]] && arch="amd64" || arch="$arch"
            
            local download_url="https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-${arch}.tar.gz"
            local install_dir="/usr/local/bin"
            
            curl -L "$download_url" -o /tmp/node_exporter.tar.gz
            tar xzf /tmp/node_exporter.tar.gz -C /tmp
            cp "/tmp/node_exporter-${node_exporter_version}.linux-${arch}/node_exporter" "$install_dir/"
            chmod +x "$install_dir/node_exporter"
            rm -rf /tmp/node_exporter*
            
            log_success "Prometheus Node Exporter installed"
        else
            log_success "Prometheus Node Exporter is already installed"
        fi
    fi
    
    log_success "Monitoring tools installation completed"
}

setup_monitoring() {
    log_section "Configuring Monitoring Tools"
    
    log_step "Configuring Netdata"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would configure Netdata"
    else
        if command_exists netdata; then
            dryrun_service "enable" "netdata"
            dryrun_service "start" "netdata"
            log_info "Netdata available at http://localhost:19999"
        fi
    fi
    
    log_step "Configuring Prometheus Node Exporter"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would configure Node Exporter service"
    else
        if command_exists node_exporter; then
            # Create systemd service for node_exporter
            cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload
            systemctl enable node_exporter
            systemctl start node_exporter
            log_success "Node Exporter service configured"
            log_info "Node Exporter available at http://localhost:9100/metrics"
        fi
    fi
    
    log_success "Monitoring configuration completed"
}

check_monitoring_status() {
    log_info "Monitoring Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if command_exists netdata; then
            if service_running netdata; then
                log_success "Netdata: running"
            else
                log_warn "Netdata: installed but not running"
            fi
        else
            log_warn "Netdata: not installed"
        fi
        
        if command_exists node_exporter; then
            if service_running node_exporter; then
                log_success "Node Exporter: running"
            else
                log_warn "Node Exporter: installed but not running"
            fi
        else
            log_warn "Node Exporter: not installed"
        fi
    else
        log_warn "[DRY-RUN] Would check monitoring tools status"
    fi
}
