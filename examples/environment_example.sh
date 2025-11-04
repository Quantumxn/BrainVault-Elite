#!/bin/bash
# ================================================================
# BrainVault Elite - Environment Configuration Example
# Copy to .env.local and customize for your environment
# ================================================================

# ============= General Settings =============

# Dry-run mode (true/false)
export DRY_RUN=false

# Verbose logging (true/false)
export VERBOSE=false

# Disable colors (true/false)
export NO_COLOR=false

# Log file location
export LOGFILE="/var/log/brainvault_elite_$(date +%F_%H-%M-%S).log"

# Log level (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR, 4=SUCCESS)
export LOG_LEVEL=1

# ============= Installation Options =============

# Skip AI stack installation
export SKIP_AI=false

# Skip security hardening
export SKIP_SECURITY=false

# Skip backup system setup
export SKIP_BACKUP=false

# Enable maximum security mode
export SECURE_MODE=false

# Disable telemetry blocking (false means block telemetry)
export DISABLE_TELEMETRY_BLOCK=false

# Enable parallel installations (experimental)
export PARALLEL_INSTALLS=false

# Maximum parallel jobs (when parallel mode enabled)
export MAX_PARALLEL=4

# ============= Backup Configuration =============

# Backup encryption password (NEVER commit this!)
# export BACKUP_ENCRYPTION_PASSWORD='your-secure-password-here'

# Rclone remote name (from rclone.conf)
export RCLONE_REMOTE='s3-backup'

# Backup retention days
export BACKUP_RETENTION_DAYS=30

# ============= Security Settings =============

# SSH port (if non-standard)
export SSH_PORT=22

# Fail2ban ban time (in seconds)
export FAIL2BAN_BAN_TIME=3600

# Fail2ban max retry attempts
export FAIL2BAN_MAX_RETRY=3

# Enable IPv6 firewall rules
export UFW_ENABLE_IPV6=true

# ============= AI/ML Settings =============

# Python version preference
export PYTHON_VERSION='3.11'

# Install GPU support (if NVIDIA GPU detected)
export INSTALL_GPU_SUPPORT=true

# Ollama model to install
export OLLAMA_MODEL='llama2'

# Jupyter port
export JUPYTER_PORT=8888

# ============= Monitoring Settings =============

# Netdata port
export NETDATA_PORT=19999

# Prometheus node exporter port
export PROMETHEUS_PORT=9100

# Enable email notifications
export ENABLE_EMAIL_NOTIFICATIONS=false

# Email address for alerts
export ALERT_EMAIL='admin@example.com'

# ============= Docker Configuration =============

# Docker log driver
export DOCKER_LOG_DRIVER='json-file'

# Docker log max size
export DOCKER_LOG_MAX_SIZE='10m'

# Docker log max files
export DOCKER_LOG_MAX_FILE='3'

# ============= Advanced Settings =============

# Timeshift snapshot before installation
export CREATE_SNAPSHOT=true

# Backup /etc before installation
export BACKUP_ETC=true

# Run security audit after installation
export RUN_POST_AUDIT=true

# Reboot after installation
export AUTO_REBOOT=false

# ============= LLM Integration =============

# LLM provider (ollama, openai, anthropic)
export LLM_PROVIDER='ollama'

# LLM model for security analysis
export LLM_SECURITY_MODEL='llama2'

# LLM API endpoint (for Ollama)
export LLM_API_ENDPOINT='http://localhost:11434'

# OpenAI API key (if using OpenAI)
# export OPENAI_API_KEY='sk-...'

# ============= Custom Paths =============

# Installation directory
export BRAINVAULT_DIR='/opt/brainvault'

# Backup directory
export BACKUP_DIR='/opt/brainvault/backups'

# Configuration directory
export CONFIG_DIR='/etc/brainvault'

# ============= Feature Flags =============

# Enable experimental features
export ENABLE_EXPERIMENTAL=false

# Enable parallel module loading
export PARALLEL_MODULE_LOAD=false

# Enable performance profiling
export ENABLE_PROFILING=false

# ============= Compliance Settings =============

# Compliance profile (none, pci-dss, hipaa, cis, stig)
export COMPLIANCE_PROFILE='none'

# Enable audit logging to syslog
export AUDIT_TO_SYSLOG=true

# ============= Network Settings =============

# Proxy server (if required)
# export HTTP_PROXY='http://proxy.example.com:8080'
# export HTTPS_PROXY='http://proxy.example.com:8080'
# export NO_PROXY='localhost,127.0.0.1'

# DNS servers (comma-separated)
export DNS_SERVERS='8.8.8.8,8.8.4.4'

# ============= Usage =============
#
# To use this configuration:
#
# 1. Copy this file:
#    cp examples/environment_example.sh .env.local
#
# 2. Customize the settings
#
# 3. Never commit .env.local (already in .gitignore)
#
# 4. Source before running:
#    source .env.local
#    sudo -E ./brainvault_elite.sh
#
# Or:
#    sudo bash -c "source .env.local && ./brainvault_elite.sh"
#
# ================================================================

# ============= Validation =============

validate_environment() {
    local errors=0
    
    # Check required settings
    if [[ -z "$LOGFILE" ]]; then
        echo "ERROR: LOGFILE not set"
        ((errors++))
    fi
    
    # Validate log level
    if [[ ! "$LOG_LEVEL" =~ ^[0-4]$ ]]; then
        echo "ERROR: LOG_LEVEL must be 0-4"
        ((errors++))
    fi
    
    # Check backup password if backups enabled
    if [[ "$SKIP_BACKUP" == "false" ]] && [[ -z "$BACKUP_ENCRYPTION_PASSWORD" ]]; then
        echo "WARNING: BACKUP_ENCRYPTION_PASSWORD not set"
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo "Configuration validation failed with $errors error(s)"
        return 1
    fi
    
    echo "Configuration validation passed"
    return 0
}

# Run validation if sourced interactively
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    validate_environment
fi
