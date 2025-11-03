#!/usr/bin/env bash

setup_backup_template() {
    log_info "Deploying encrypted backup template"

    install_pkg rclone openssl

    local backup_script
    backup_script="/usr/local/bin/elite-backup.sh"

    run_cmd "cat <<'EOS' > ${backup_script}
#!/usr/bin/env bash
set -euo pipefail

TARGET=\${1:-default}
DATE=\$(date +%F_%H-%M)
BACKUP_FILE=\"/opt/brainvault/backups/sys_\${DATE}.tar.gz\"

mkdir -p /opt/brainvault/backups
tar -czf - /etc /home | openssl enc -aes-256-cbc -pbkdf2 -out \"\${BACKUP_FILE}\"
rclone copy \"\${BACKUP_FILE}\" remote:\"\${TARGET}\"
EOS" "Creating backup helper script at ${backup_script}"

    run_cmd "chmod +x ${backup_script}" "Making ${backup_script} executable"
    log_success "Encrypted backup template deployed"
}

install_monitoring() {
    log_info "Installing monitoring stack"

    install_pkg netdata prometheus-node-exporter
    run_cmd "systemctl enable netdata" "Enabling Netdata service" true || log_warn "Unable to enable Netdata service"
    run_cmd "systemctl restart netdata" "Starting Netdata service" true || log_warn "Unable to start Netdata service"
    log_success "Monitoring stack provisioned"
}

create_audit_script() {
    log_info "Deploying audit automation script"

    local audit_script
    audit_script="/usr/local/bin/elite-audit"

    run_cmd "cat <<'EOS' > ${audit_script}
#!/usr/bin/env bash
set -euo pipefail

echo '===== BrainVault Audit ====='
lynis audit system
rkhunter --check
EOS" "Creating audit script at ${audit_script}"

    run_cmd "chmod +x ${audit_script}" "Making ${audit_script} executable"
    log_success "Audit script deployed"
}

setup_cron_jobs() {
    log_info "Scheduling automated audits"

    run_cmd "(crontab -l 2>/dev/null; echo '0 2 * * * /usr/local/bin/elite-audit >> /var/log/elite-audit.log 2>&1') | crontab -" "Registering daily audit cron job"
    log_success "Audit cron job scheduled"
}
