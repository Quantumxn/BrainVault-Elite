#!/usr/bin/env bash

setup_backup_template() {
  log_section "Backup Automation"
  install_pkg rclone openssl tar
  local backup_script="/usr/local/bin/elite-backup.sh"
  local content
  content=$(cat <<'EOB'
#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-default}"
DATE="$(date +%F_%H-%M)"
BACKUP_ROOT="/opt/brainvault/backups"
mkdir -p "${BACKUP_ROOT}"
BACKUP_FILE="${BACKUP_ROOT}/sys_${DATE}.tar.gz"

tar -czf - /etc /home | openssl enc -aes-256-cbc -pbkdf2 -out "${BACKUP_FILE}"
if command -v rclone >/dev/null 2>&1; then
  rclone copy "${BACKUP_FILE}" "remote:${TARGET}"
fi
EOB
)
  write_file "${backup_script}" "${content}" "Deploying encrypted backup script"
  run_cmd "chmod +x ${backup_script}" "Setting execute permission on backup script"
}

install_monitoring_suite() {
  log_section "Monitoring Suite"
  install_pkg netdata prometheus-node-exporter
  run_cmd "systemctl enable netdata" "Enabling Netdata service"
  run_cmd "systemctl start netdata" "Starting Netdata service"
}

create_audit_script() {
  log_section "Audit Script"
  local audit_script="/usr/local/bin/elite-audit"
  local content
  content=$(cat <<'EOC'
#!/usr/bin/env bash
set -euo pipefail

echo '===== BrainVault Audit ====='
if command -v lynis >/dev/null 2>&1; then
  lynis audit system
fi
if command -v rkhunter >/dev/null 2>&1; then
  rkhunter --check
fi
EOC
)
  write_file "${audit_script}" "${content}" "Deploying audit script"
  run_cmd "chmod +x ${audit_script}" "Setting execute permission on audit script"
}

setup_cron_jobs() {
  log_section "Scheduled Tasks"
  run_cmd "(crontab -l 2>/dev/null; echo '0 2 * * * /usr/local/bin/elite-audit >> /var/log/elite-audit.log 2>&1') | crontab -" "Scheduling daily audit cron job"
}
