# 🧠 BrainVault Elite  
### Autonomous Ubuntu Hardening + AI-Stack Bootstrap System  
**by [MD Jahirul]**

---

## 🚀 Overview
**BrainVault Elite** একটি পূর্ণাঙ্গ **Ubuntu system hardening + AI-development bootstrap framework**,  
যা স্বয়ংক্রিয়ভাবে একটি **secure, privacy-first, AI-ready workstation/server** তৈরি করে।  
মাত্র এক কমান্ডে!

---

## 📦 Full Script (brainvault_elite.sh)

```bash
#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Full System Hardening + AI Stack Bootstrap
# Version: 1.0
# Author : MD Jahirul
# ================================================================

set -euo pipefail
LOGFILE="/var/log/brainvault_elite_$(date +%F_%H-%M-%S).log"

# --------------------- Utility Functions ------------------------

log() {
    echo -e "[ $(date '+%F %T') ] $*" | tee -a "$LOGFILE"
}

run_cmd() {
    local CMD="$1"
    local DESC="$2"
    if [ "${DRY_RUN:-false}" = true ]; then
        log "🔸 (dry-run) $DESC → $CMD"
    else
        log "▶️  $DESC"
        eval "$CMD" >>"$LOGFILE" 2>&1
    fi
}

install_pkg() {
    run_cmd "apt-get install -y $*" "Installing packages: $*"
}

# --------------------- Core Functions ---------------------------

create_snapshot() {
    log "📸 Creating system snapshot..."
    if command -v timeshift &>/dev/null; then
        run_cmd "timeshift --create --comments 'BrainVault pre-install snapshot'" "Creating Timeshift snapshot"
    else
        log "⚠️  Timeshift not found, skipping snapshot."
    fi
}

backup_configs() {
    BACKUP_DIR="/opt/brainvault/backups/etc_$(date +%F_%H-%M)"
    run_cmd "mkdir -p $BACKUP_DIR && rsync -a /etc/ $BACKUP_DIR" "Backing up /etc configuration"
}

# --------------------- Security Stack ---------------------------

setup_firewall() {
    run_cmd "ufw default deny incoming && ufw default allow outgoing && ufw enable" "Configuring UFW firewall"
}

setup_fail2ban() {
    run_cmd "systemctl enable fail2ban && systemctl start fail2ban" "Enabling Fail2ban"
}

setup_apparmor() {
    run_cmd "systemctl enable apparmor && systemctl start apparmor" "Starting AppArmor"
}

setup_telemetry_block() {
    run_cmd "iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m string --string 'telemetry' --algo bm -j DROP" \
        "Blocking telemetry endpoints (basic pattern match)"
}

setup_kernel_hardening() {
    SYSCTL_FILE="/etc/sysctl.d/99-brainvault-hardening.conf"
    run_cmd "cat > $SYSCTL_FILE <<EOF
kernel.randomize_va_space=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
kernel.kptr_restrict=2
EOF
sysctl --system
" "Applying kernel hardening parameters"
}

setup_integrity_tools() {
    run_cmd "rkhunter --update && lynis audit system || true" "Running initial integrity audit"
}

# --------------------- AI / Dev Stack ----------------------------

install_dev_tools() {
    install_pkg git build-essential python3 python3-pip python3-venv
}

install_python_stack() {
    run_cmd "pip3 install --upgrade pip wheel setuptools && pip3 install torch torchvision transformers pandas jupyterlab" \
        "Installing Python AI stack"
}

install_container_stack() {
    install_pkg docker.io docker-compose podman
    run_cmd "systemctl enable docker && systemctl start docker" "Starting Docker"
}

# --------------------- Backup & Monitoring -----------------------

setup_backup_template() {
    install_pkg rclone openssl
    BACKUP_SCRIPT="/usr/local/bin/elite-backup.sh"
    run_cmd "cat > $BACKUP_SCRIPT <<'EOS'
#!/bin/bash
TARGET=\${1:-default}
DATE=\$(date +%F_%H-%M)
BACKUP_FILE=\"/opt/brainvault/backups/sys_\$DATE.tar.gz\"
tar -czf - /etc /home | openssl enc -aes-256-cbc -pbkdf2 -out \$BACKUP_FILE
rclone copy \$BACKUP_FILE remote:\$TARGET
EOS
chmod +x \$BACKUP_SCRIPT
" "Deploying encrypted backup script"
}

install_monitoring() {
    install_pkg netdata prometheus-node-exporter
    run_cmd "systemctl enable netdata && systemctl start netdata" "Starting Netdata monitoring"
}

create_audit_script() {
    AUDIT_SCRIPT="/usr/local/bin/elite-audit"
    run_cmd "cat > $AUDIT_SCRIPT <<'EOS'
#!/bin/bash
echo '===== BrainVault Audit ====='
lynis audit system
rkhunter --check
EOS
chmod +x \$AUDIT_SCRIPT
" "Deploying audit script"
}

setup_cron_jobs() {
    run_cmd "(crontab -l 2>/dev/null; echo '0 2 * * * /usr/local/bin/elite-audit >> /var/log/elite-audit.log') | crontab -" \
        "Scheduling daily audit"
}

final_steps() {
    run_cmd "apt-get autoremove -y && apt-get clean" "Cleaning up"
    log "✅ Installation complete. Reboot recommended."
}

# --------------------- CLI Parser -------------------------------

parse_args() {
    DRY_RUN=false
    SKIP_SECURITY=false
    SKIP_AI=false
    SKIP_BACKUP=false
    ENABLE_TELEMETRY=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=true ;;
            --skip-security) SKIP_SECURITY=true ;;
            --skip-ai) SKIP_AI=true ;;
            --skip-backup) SKIP_BACKUP=true ;;
            --disable-telemetry) ENABLE_TELEMETRY=true ;;
        esac
        shift
    done
}

# --------------------- MAIN EXECUTION ----------------------------

main() {
    log "⚙️ Options: DRY_RUN=$DRY_RUN  SKIP_SECURITY=$SKIP_SECURITY  SKIP_AI=$SKIP_AI  SKIP_BACKUP=$SKIP_BACKUP  ENABLE_TELEMETRY=$ENABLE_TELEMETRY"

    create_snapshot
    backup_configs

    run_cmd "apt-get update && apt-get -y upgrade" "Updating system packages"
    install_pkg ca-certificates curl wget gnupg lsb-release software-properties-common htop iotop nethogs tree pv rsync

    if [ "$SKIP_SECURITY" = false ]; then
        log "🔐 Installing security stack…"
        install_pkg ufw fail2ban apparmor apparmor-utils apparmor-profiles-extra lynis chkrootkit rkhunter aide-common auditd needrestart debsecan
        setup_firewall
        setup_fail2ban
        setup_apparmor
        setup_telemetry_block
        setup_kernel_hardening
        setup_integrity_tools
    else
        log "⚠️ Security stack installation skipped per user request."
    fi

    if [ "$SKIP_AI" = false ]; then
        log "🤖 Installing AI / development stack…"
        install_dev_tools
        install_container_stack
        install_python_stack
    else
        log "⚠️ AI / Dev stack installation skipped per user request."
    fi

    setup_backup_template
    install_monitoring
    create_audit_script
    setup_cron_jobs
    final_steps
}

parse_args "$@"
main
