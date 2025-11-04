#!/bin/bash
# monitoring.sh - System monitoring and observability for BrainVault Elite

install_monitoring_tools() {
    log_section "📊 Installing Monitoring Tools"
    
    if is_dryrun; then
        add_dryrun_operation "MONITORING" "Install Netdata"
        add_dryrun_operation "MONITORING" "Install Prometheus Node Exporter"
        return 0
    fi
    
    # Install Netdata
    install_netdata
    
    # Install Prometheus Node Exporter
    install_prometheus_node_exporter
    
    # Install basic monitoring tools
    install_basic_monitoring_tools
    
    log_success "Monitoring tools installed"
}

# Install Netdata
install_netdata() {
    log_info "Installing Netdata..."
    
    if systemctl is-active --quiet netdata 2>/dev/null; then
        log_info "Netdata is already installed and running"
        return 0
    fi
    
    if command_exists netdata; then
        log_info "Netdata is already installed"
        safe_exec "Starting Netdata" systemctl start netdata
        return 0
    fi
    
    log_info "Downloading and installing Netdata..."
    
    # Install Netdata using official installer
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --stable-channel || {
        log_error "Failed to install Netdata"
        return 1
    }
    
    if systemctl is-active --quiet netdata; then
        log_success "Netdata installed and running"
        log_info "Access Netdata at: http://localhost:19999"
    else
        log_error "Netdata installation failed"
        return 1
    fi
}

# Install Prometheus Node Exporter
install_prometheus_node_exporter() {
    log_info "Installing Prometheus Node Exporter..."
    
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        log_info "Node Exporter is already running"
        return 0
    fi
    
    if command_exists node_exporter; then
        log_info "Node Exporter is already installed"
        return 0
    fi
    
    local version="1.7.0"
    local archive="node_exporter-${version}.linux-amd64.tar.gz"
    local url="https://github.com/prometheus/node_exporter/releases/download/v${version}/${archive}"
    
    log_info "Downloading Node Exporter v${version}..."
    
    cd /tmp || return 1
    wget -q "$url" || {
        log_error "Failed to download Node Exporter"
        return 1
    }
    
    tar xzf "$archive"
    cp "node_exporter-${version}.linux-amd64/node_exporter" /usr/local/bin/
    chmod +x /usr/local/bin/node_exporter
    
    # Create systemd service
    cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    # Start service
    systemctl daemon-reload
    safe_exec "Starting Node Exporter" systemctl start node_exporter
    safe_exec "Enabling Node Exporter" systemctl enable node_exporter
    
    # Cleanup
    rm -rf "/tmp/node_exporter-${version}.linux-amd64" "/tmp/$archive"
    
    if systemctl is-active --quiet node_exporter; then
        log_success "Node Exporter installed and running on port 9100"
    else
        log_error "Node Exporter installation failed"
        return 1
    fi
}

# Install basic monitoring tools
install_basic_monitoring_tools() {
    log_info "Installing basic monitoring tools..."
    
    local tools=(
        "sysstat"
        "iotop"
        "nethogs"
        "dstat"
        "glances"
    )
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            safe_exec "Installing $tool" apt-get install -y "$tool" || log_warn "Failed to install $tool"
        else
            log_debug "$tool already installed"
        fi
    done
    
    log_success "Basic monitoring tools installed"
}

# Configure log rotation
setup_log_rotation() {
    log_info "Configuring log rotation..."
    
    if is_dryrun; then
        add_dryrun_operation "MONITORING" "Configure log rotation"
        return 0
    fi
    
    local logrotate_conf="/etc/logrotate.d/brainvault"
    
    cat > "$logrotate_conf" <<'EOF'
/var/log/brainvault*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
}
EOF
    
    log_success "Log rotation configured"
}

# System health check
run_health_check() {
    log_section "🏥 SYSTEM HEALTH CHECK"
    
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║         SYSTEM HEALTH STATUS                   ║"
    echo "╠════════════════════════════════════════════════╣"
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "║ CPU Usage:              ${cpu_usage}%"
    
    # Memory usage
    local mem_total=$(free -h | awk 'NR==2{print $2}')
    local mem_used=$(free -h | awk 'NR==2{print $3}')
    local mem_percent=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    echo "║ Memory:                 $mem_used / $mem_total (${mem_percent}%)"
    
    # Disk usage
    local disk_usage=$(df -h / | awk 'NR==2{print $5}')
    local disk_available=$(df -h / | awk 'NR==2{print $4}')
    echo "║ Disk Usage:             $disk_usage (${disk_available} free)"
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo "║ Load Average:           $load_avg"
    
    # Uptime
    local uptime_str=$(uptime -p)
    echo "║ Uptime:                 $uptime_str"
    
    echo "╠════════════════════════════════════════════════╣"
    echo "║         SERVICE STATUS                         ║"
    echo "╠════════════════════════════════════════════════╣"
    
    # Check key services
    local services=("ufw" "fail2ban" "ssh" "netdata")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            printf "║ %-30s [ACTIVE]      ║\n" "$service"
        else
            printf "║ %-30s [INACTIVE]    ║\n" "$service"
        fi
    done
    
    echo "╚════════════════════════════════════════════════╝"
    echo ""
}

# Monitor system resources
monitor_resources() {
    log_info "Monitoring system resources..."
    
    if is_dryrun; then
        add_dryrun_operation "MONITORING" "Monitor system resources"
        return 0
    fi
    
    echo ""
    echo "=== CPU Information ==="
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket"
    
    echo ""
    echo "=== Memory Information ==="
    free -h
    
    echo ""
    echo "=== Disk Information ==="
    df -h | grep -vE "tmpfs|devtmpfs|loop"
    
    echo ""
    echo "=== Network Interfaces ==="
    ip -brief addr show
    
    echo ""
}

# Check for high resource usage
check_resource_alerts() {
    log_info "Checking for resource alerts..."
    
    local alert_count=0
    
    # Check CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null || echo 0) )); then
        log_warn "⚠️  High CPU usage: ${cpu_usage}%"
        ((alert_count++))
    fi
    
    # Check memory
    local mem_percent=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [[ $mem_percent -gt 85 ]]; then
        log_warn "⚠️  High memory usage: ${mem_percent}%"
        ((alert_count++))
    fi
    
    # Check disk
    local disk_percent=$(df / | awk 'NR==2{print $5}' | tr -d '%')
    if [[ $disk_percent -gt 85 ]]; then
        log_warn "⚠️  High disk usage: ${disk_percent}%"
        ((alert_count++))
    fi
    
    # Check load average
    local load_1min=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
    local cpu_count=$(nproc)
    if (( $(echo "$load_1min > $cpu_count * 2" | bc -l 2>/dev/null || echo 0) )); then
        log_warn "⚠️  High load average: $load_1min (CPUs: $cpu_count)"
        ((alert_count++))
    fi
    
    if [[ $alert_count -eq 0 ]]; then
        log_success "No resource alerts"
    else
        log_warn "Found $alert_count resource alert(s)"
    fi
    
    return $alert_count
}

# Show monitoring status
show_monitoring_status() {
    log_section "📊 MONITORING STATUS"
    
    echo ""
    
    # Netdata
    if systemctl is-active --quiet netdata 2>/dev/null; then
        echo "✓ Netdata:           RUNNING (http://localhost:19999)"
    else
        echo "✗ Netdata:           NOT RUNNING"
    fi
    
    # Node Exporter
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        echo "✓ Node Exporter:     RUNNING (port 9100)"
    else
        echo "✗ Node Exporter:     NOT RUNNING"
    fi
    
    # System stats
    if command_exists sar; then
        echo "✓ sysstat:           INSTALLED"
    else
        echo "✗ sysstat:           NOT INSTALLED"
    fi
    
    echo ""
}

# Export functions
export -f install_monitoring_tools
export -f install_netdata
export -f install_prometheus_node_exporter
export -f install_basic_monitoring_tools
export -f setup_log_rotation
export -f run_health_check
export -f monitor_resources
export -f check_resource_alerts
export -f show_monitoring_status
