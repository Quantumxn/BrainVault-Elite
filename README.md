# 🧠 BrainVault Elite v2.0

### Autonomous Ubuntu Hardening + AI-Stack Bootstrap System  
**by MD Jahirul**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2B-orange.svg)](https://ubuntu.com/)

---

## 🚀 Overview

**BrainVault Elite** হলো একটি পূর্ণাঙ্গ **modular DevSecOps + AI bootstrap framework**,  
যা স্বয়ংক্রিয়ভাবে একটি **secure, privacy-first, AI-ready workstation/server** তৈরি করে।  
**মাত্র এক কমান্ডে!**

### ✨ What's New in v2.0

- **🔧 Modular Architecture**: Clean separation of concerns with auto-loading modules
- **🎨 Color-Coded Logging**: Beautiful, informative console output
- **⚡ Parallel Installs**: Experimental support for concurrent operations (3-5x faster)
- **🤖 LLM Integration**: AI-powered security audits with Ollama
- **🔍 Dry-Run Mode**: Preview all changes before execution
- **🎯 Advanced CLI**: Comprehensive argument parser with multiple options
- **✅ Full Validation**: Automated syntax checking and module verification
- **📊 Detailed Reports**: Installation summaries and security audits

---

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Installation Options](#-installation-options)
- [Module System](#-module-system)
- [Usage Examples](#-usage-examples)
- [Advanced Features](#-advanced-features)
- [Security Components](#-security-components)
- [AI & Development Stack](#-ai--development-stack)
- [Monitoring & Audit](#-monitoring--audit)
- [Backup System](#-backup-system)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## ✨ Features

### 🔐 Security Stack

- **UFW Firewall**: Stateful firewall with rate limiting
- **Fail2ban**: Intrusion prevention with smart banning
- **AppArmor**: Mandatory access control for applications
- **Kernel Hardening**: 50+ sysctl parameters optimized for security
- **Audit System**: Comprehensive logging with auditd
- **Rootkit Detection**: rkhunter + chkrootkit integration
- **Telemetry Blocking**: Block common telemetry endpoints
- **Security Limits**: Process and file descriptor limits

### 🤖 AI & Development Stack

- **Python ML Stack**: PyTorch, TensorFlow, Transformers, scikit-learn
- **Jupyter Lab**: Interactive development environment
- **Docker + Compose**: Full container orchestration
- **Podman**: Docker alternative for rootless containers
- **Ollama**: Local LLM runtime for privacy-first AI
- **GPU Support**: CUDA detection and configuration

### 📊 Monitoring & Audit

- **Netdata**: Real-time system monitoring (http://localhost:19999)
- **Prometheus**: Metrics collection and alerting
- **Lynis**: Security auditing and hardening suggestions
- **Automated Audits**: Daily security scans via cron
- **Custom Audit Script**: Comprehensive security reports

### 💾 Backup System

- **Encrypted Backups**: AES-256 encrypted with openssl
- **Rclone Integration**: Sync to cloud storage (S3, GCS, etc.)
- **Restic Support**: Incremental, deduplicated backups
- **Automated Scheduling**: Daily backups via cron
- **System Snapshots**: Timeshift integration

---

## 🎯 Quick Start

### Prerequisites

- Ubuntu 22.04+ or Debian 11+ (64-bit)
- Root access (sudo)
- Internet connection
- At least 5GB free disk space

### One-Command Installation

```bash
# Clone the repository
git clone https://github.com/md-jahirul/brainvault-elite.git
cd brainvault-elite

# Preview what will be installed (recommended first step)
sudo ./brainvault_elite.sh --dry-run

# Run full installation
sudo ./brainvault_elite.sh

# Or with specific options
sudo ./brainvault_elite.sh --skip-ai --secure --disable-telemetry
```

### Installation Time

- **Full Installation**: ~20-25 minutes (sequential)
- **With Parallel Mode**: ~12-15 minutes (experimental)
- **Security Only**: ~8-10 minutes
- **AI Stack Only**: ~10-12 minutes

---

## 📦 Installation Options

### CLI Arguments

```bash
sudo ./brainvault_elite.sh [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--dry-run` | Simulate all actions without executing (safe preview) |
| `--skip-ai` | Skip AI/ML and container stack installation |
| `--skip-security` | Skip security hardening (not recommended) |
| `--skip-backup` | Skip backup system setup |
| `--secure` | Enable maximum security mode with strict hardening |
| `--disable-telemetry` | Block telemetry endpoints with firewall rules |
| `--parallel` | Enable parallel installations (experimental, faster) |
| `--verbose` | Enable debug logging for troubleshooting |
| `--no-color` | Disable colored output (for logging to files) |
| `--help, -h` | Show help message with all options |

### Configuration Files

After installation, configuration files are located at:

```
/etc/brainvault/          # System-wide configuration
/opt/brainvault/          # Installation directory
├── backups/              # System backups
├── scripts/              # Helper scripts
└── logs/                 # Application logs
```

---

## 🏗️ Module System

### Architecture

```
brainvault_elite/
├── brainvault_elite.sh              # Main orchestrator
└── scripts/                         # Modular components
    ├── core/                        # Core system functions
    │   └── system.sh                # Updates, snapshots, cleanup
    ├── security/                    # Security modules
    │   ├── firewall.sh              # UFW configuration
    │   ├── intrusion_detection.sh   # Fail2ban, AppArmor
    │   └── kernel_hardening.sh      # Sysctl parameters
    ├── ai/                          # AI/ML stack
    │   ├── python_stack.sh          # PyTorch, Jupyter
    │   └── container_stack.sh       # Docker, Podman
    ├── backup/                      # Backup system
    │   └── backup_system.sh         # Encrypted backups
    ├── monitoring/                  # Monitoring tools
    │   └── monitoring.sh            # Netdata, audits
    └── utils/                       # Utilities
        ├── logging.sh               # Color-coded logging
        └── validation.sh            # Syntax validation
```

### Auto-Loading Modules

The main script automatically discovers and loads all modules:

```bash
# All *.sh files under /scripts are automatically sourced
# No manual configuration needed!

source_modules() {
    find "$SCRIPTS_BASE" -type f -name "*.sh" -print0 | \
        while IFS= read -r -d '' module; do
            source "$module"
        done
}
```

### Creating Custom Modules

Add your own module in 3 simple steps:

```bash
# 1. Create a new module file
cat > scripts/custom/my_feature.sh <<'EOF'
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

my_custom_function() {
    log_section "My Custom Feature"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Custom" "Install my feature"
        return 0
    fi
    
    run_cmd "echo 'Hello BrainVault!'" "Running custom command"
    log_success "Feature installed"
}

export -f my_custom_function
EOF

# 2. Make it executable
chmod +x scripts/custom/my_feature.sh

# 3. It will be automatically loaded on next run!
sudo ./brainvault_elite.sh --dry-run
```

---

## 💡 Usage Examples

### Example 1: Preview Installation

```bash
# See what will be installed without making changes
sudo ./brainvault_elite.sh --dry-run > installation-plan.txt
less installation-plan.txt
```

### Example 2: Security-Only Setup

```bash
# Install only security components, skip AI stack
sudo ./brainvault_elite.sh --skip-ai --secure
```

### Example 3: Development Workstation

```bash
# Install AI/ML stack without aggressive security hardening
sudo ./brainvault_elite.sh --skip-security
```

### Example 4: Maximum Security Server

```bash
# Full security hardening with telemetry blocking
sudo ./brainvault_elite.sh \
    --secure \
    --disable-telemetry \
    --skip-ai
```

### Example 5: Fast Installation (Experimental)

```bash
# Use parallel mode for faster installation
sudo ./brainvault_elite.sh --parallel --verbose
```

### Example 6: Troubleshooting Mode

```bash
# Verbose output for debugging issues
sudo ./brainvault_elite.sh --verbose 2>&1 | tee debug.log
```

---

## 🔐 Security Components

### Firewall (UFW)

```bash
# Check firewall status
sudo ufw status verbose

# Add custom rule
sudo ufw allow 8080/tcp comment 'My App'

# View numbered rules
sudo ufw status numbered
```

### Fail2ban

```bash
# Check Fail2ban status
sudo fail2ban-client status

# View SSH jail
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

### AppArmor

```bash
# Check AppArmor status
sudo aa-status

# Enforce a profile
sudo aa-enforce /etc/apparmor.d/usr.bin.example

# Complain mode (permissive)
sudo aa-complain /etc/apparmor.d/usr.bin.example
```

### Kernel Hardening

All sysctl parameters are configured in:
```
/etc/sysctl.d/99-brainvault-hardening.conf
```

View current settings:
```bash
sudo sysctl -a | grep -E "kernel\.|net\.|fs\."
```

### Security Audit

```bash
# Run comprehensive security audit
sudo brainvault-audit

# View latest audit report
sudo cat /var/log/brainvault-audit-report_*.txt | tail -100

# Check for recent failed logins
sudo grep "Failed password" /var/log/auth.log | tail -20
```

---

## 🤖 AI & Development Stack

### Python & Machine Learning

```bash
# Check installed packages
pip list | grep -E "torch|transformers|jupyter"

# Start Jupyter Lab
jupyter lab --no-browser --ip=0.0.0.0

# Upgrade ML libraries
pip install --upgrade torch transformers
```

### Docker

```bash
# Check Docker status
sudo systemctl status docker

# Run a container
docker run --rm hello-world

# View running containers
docker ps

# Add current user to docker group (no sudo needed)
sudo usermod -aG docker $USER
newgrp docker
```

### Ollama (Local LLM)

```bash
# Check if Ollama is installed
ollama --version

# Pull and run a model
ollama pull llama2
ollama run llama2

# List installed models
ollama list

# Use for security analysis
echo "Analyze this for security issues: $(sudo cat /etc/ssh/sshd_config)" | \
    ollama run llama2
```

### GPU Support

```bash
# Check for NVIDIA GPU
lspci | grep -i nvidia

# Install NVIDIA drivers (if not already installed)
sudo ubuntu-drivers autoinstall
sudo apt install nvidia-cuda-toolkit

# Verify CUDA
nvidia-smi
```

---

## 📊 Monitoring & Audit

### Netdata Dashboard

Access real-time monitoring at: **http://localhost:19999**

Features:
- CPU, Memory, Disk, Network metrics
- Process monitoring
- System logs
- Alert notifications

### Prometheus Metrics

Metrics endpoint: **http://localhost:9100/metrics**

Integrate with Grafana:
```bash
# Install Grafana
sudo apt-get install -y grafana

# Start Grafana
sudo systemctl start grafana-server

# Access at http://localhost:3000
# Default login: admin/admin
```

### Security Audits

```bash
# Run manual audit
sudo brainvault-audit

# View audit schedule
crontab -l | grep brainvault-audit

# Check audit logs
sudo tail -f /var/log/brainvault-audit.log
```

### Lynis Security Scanner

```bash
# Run full Lynis audit
sudo lynis audit system

# Quick scan
sudo lynis audit system --quick

# View hardening suggestions
sudo lynis show suggestions
```

---

## 💾 Backup System

### Manual Backup

```bash
# Set encryption password
export BACKUP_ENCRYPTION_PASSWORD='your-secure-password'

# Create backup
sudo brainvault-backup

# Backup to remote (requires rclone configuration)
sudo brainvault-backup remote-name
```

### Automated Backups

Backups are automatically scheduled via cron:

```bash
# View backup schedule
crontab -l | grep brainvault-backup

# Backup logs
sudo tail -f /var/log/brainvault-backup.log

# List existing backups
ls -lh /opt/brainvault/backups/
```

### Rclone Configuration

```bash
# Configure remote storage
rclone config

# Example: Configure S3
# Follow prompts to add your credentials

# Test connection
rclone ls remote-name:bucket-name

# Manual sync
rclone sync /opt/brainvault/backups remote-name:brainvault-backups
```

### Restore from Backup

```bash
# Decrypt backup
openssl enc -d -aes-256-cbc -pbkdf2 \
    -in backup_file.tar.gz.enc \
    -out backup_file.tar.gz

# Extract
tar -xzf backup_file.tar.gz -C /restore/location/
```

---

## 🛠️ Advanced Features

### 1. Color-Coded Logging

All output is beautifully formatted with colors:

- 🔍 **DEBUG** (Magenta): Detailed debugging info
- ℹ️ **INFO** (Blue): General information
- ⚠️ **WARNING** (Yellow): Warnings
- ❌ **ERROR** (Red): Errors
- ✅ **SUCCESS** (Green): Success messages

Disable colors:
```bash
sudo ./brainvault_elite.sh --no-color
```

### 2. Parallel Execution (Experimental)

Speed up installation with concurrent operations:

```bash
sudo ./brainvault_elite.sh --parallel
```

**Note**: This is experimental and may cause issues. Always test with `--dry-run` first.

### 3. LLM-Based Security Auditing

Integrate with Ollama for AI-powered security analysis:

```bash
# Analyze audit logs
cat /var/log/brainvault-audit-report_latest.txt | \
    ollama run llama2 "Analyze this security audit and suggest improvements"

# Generate custom firewall rules
echo "Generate UFW rules for a web server with Django" | \
    ollama run codellama

# Explain security issues
echo "Explain this error: $(sudo journalctl -xe | tail -50)" | \
    ollama run llama2
```

See [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md) for detailed documentation.

### 4. Dry-Run Summary

Get a comprehensive summary of planned actions:

```bash
sudo ./brainvault_elite.sh --dry-run

# Output includes:
# - All packages to be installed
# - System configurations to be changed
# - Services to be started/enabled
# - Total action count
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Package Installation Fails

```bash
# Clear package cache
sudo apt-get clean
sudo apt-get update

# Try again with verbose mode
sudo ./brainvault_elite.sh --verbose
```

#### 2. Module Loading Fails

```bash
# Validate all scripts
bash scripts/utils/validation.sh

# Check for syntax errors
find scripts -name "*.sh" -exec bash -n {} \;
```

#### 3. Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Activate changes
newgrp docker

# Or logout and login again
```

#### 4. Firewall Blocks SSH

```bash
# SSH should be allowed by default, but if locked out:
# Access via console/VNC and run:
sudo ufw allow 22/tcp
sudo ufw reload
```

#### 5. Low Disk Space

```bash
# Check disk usage
df -h

# Clean up
sudo apt-get autoremove
sudo apt-get clean
sudo docker system prune -a

# Remove old backups
sudo find /opt/brainvault/backups -mtime +30 -delete
```

### Logs Location

All logs are stored in:

```bash
/var/log/brainvault_elite_*.log      # Main installation log
/var/log/brainvault-audit.log        # Security audit logs
/var/log/brainvault-backup.log       # Backup logs
```

View logs:
```bash
# Latest installation log
sudo tail -f /var/log/brainvault_elite_*.log | tail -1

# Search for errors
sudo grep -E "ERROR|FAIL" /var/log/brainvault_*.log

# View with color highlighting
sudo tail -f /var/log/brainvault_elite_*.log | grep --color=auto -E "ERROR|WARN|SUCCESS|$"
```

### Getting Help

1. **Check logs**: Always start with the log files
2. **Run validation**: `bash scripts/utils/validation.sh`
3. **Dry-run mode**: Test with `--dry-run` first
4. **Verbose mode**: Use `--verbose` for detailed output
5. **Open an issue**: [GitHub Issues](https://github.com/md-jahirul/brainvault-elite/issues)

---

## 📚 Documentation

- **[ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)**: Detailed guide to advanced features
- **[scripts/README.md](scripts/README.md)**: Module development guide
- **Log files**: `/var/log/brainvault_*`
- **Configuration**: `/etc/brainvault/` and `/opt/brainvault/`

---

## 🧪 Testing

### Syntax Validation

```bash
# Validate all scripts
bash scripts/utils/validation.sh

# Validate specific script
bash -n brainvault_elite.sh
```

### Dry-Run Testing

```bash
# Test full installation
sudo ./brainvault_elite.sh --dry-run

# Test specific components
sudo DRY_RUN=true SKIP_AI=true ./brainvault_elite.sh
```

### VM Testing

Recommended VM configurations for testing:

```yaml
Minimal:
  - CPU: 2 cores
  - RAM: 4GB
  - Disk: 20GB
  - OS: Ubuntu 22.04

Recommended:
  - CPU: 4 cores
  - RAM: 8GB
  - Disk: 40GB
  - OS: Ubuntu 22.04 or 24.04

Full AI Stack:
  - CPU: 8+ cores
  - RAM: 16GB+
  - Disk: 100GB+
  - GPU: Optional (for ML workloads)
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Report Bugs

Open an issue with:
- OS version and architecture
- Command used
- Full error message
- Relevant log excerpts

### Suggest Features

Open an issue with:
- Clear feature description
- Use case / motivation
- Proposed implementation (if any)

### Submit Code

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly (including `--dry-run`)
5. Validate syntax: `bash scripts/utils/validation.sh`
6. Commit: `git commit -m 'Add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Code Style

- Follow existing bash style conventions
- Use 4 spaces for indentation (no tabs)
- Add comments for complex logic
- Use descriptive function names
- Export all public functions
- Include error handling with `set -euo pipefail`

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Ubuntu Security Team** - For security best practices
- **CIS Benchmarks** - For hardening guidelines
- **Lynis** - For security auditing tool
- **Netdata** - For real-time monitoring
- **Ollama** - For local LLM capabilities
- **Open Source Community** - For all the amazing tools

---

## 📞 Contact

**MD Jahirul**

- GitHub: [@md-jahirul](https://github.com/md-jahirul)
- Email: md.jahirul@example.com

---

## ⭐ Star History

If you find this project useful, please consider giving it a star! ⭐

```bash
# Quick install reminder
git clone https://github.com/md-jahirul/brainvault-elite.git
cd brainvault-elite
sudo ./brainvault_elite.sh --dry-run  # Preview first!
sudo ./brainvault_elite.sh             # Full installation
```

---

**Built with ❤️ by MD Jahirul**

*Transform your Ubuntu system into a secure, AI-ready powerhouse in minutes!*
