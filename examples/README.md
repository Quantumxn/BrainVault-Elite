# BrainVault Elite - Examples Directory

This directory contains example configurations and templates to help you customize BrainVault Elite.

---

## 📁 Contents

### 1. `custom_module_example.sh`
**Purpose**: Template for creating custom modules

**Usage:**
```bash
# Copy to scripts directory
cp examples/custom_module_example.sh scripts/custom/my_module.sh

# Customize for your needs
vim scripts/custom/my_module.sh

# Make executable
chmod +x scripts/custom/my_module.sh

# Module auto-loads on next run
sudo ./brainvault_elite.sh --dry-run
```

**Features:**
- Complete module structure
- Dry-run support
- Error handling
- Logging integration
- Function exports
- Documentation

---

### 2. `rclone_config_example.conf`
**Purpose**: Example rclone configuration for cloud backups

**Supported Services:**
- Amazon S3
- Google Cloud Storage
- Azure Blob Storage
- Backblaze B2
- Dropbox
- SFTP/SSH
- Local/NAS

**Setup:**
```bash
# Create rclone config directory
mkdir -p ~/.config/rclone

# Copy and customize
cp examples/rclone_config_example.conf ~/.config/rclone/rclone.conf

# Edit with your credentials
vim ~/.config/rclone/rclone.conf

# Protect the file
chmod 600 ~/.config/rclone/rclone.conf

# Test connection
rclone lsd s3-backup:

# Use with backups
export BACKUP_ENCRYPTION_PASSWORD='your-password'
sudo brainvault-backup s3-backup
```

---

### 3. `environment_example.sh`
**Purpose**: Environment configuration template

**Settings Include:**
- Installation options
- Security settings
- Backup configuration
- AI/ML preferences
- Monitoring settings
- Docker configuration
- Custom paths

**Usage:**
```bash
# Copy to project root
cp examples/environment_example.sh .env.local

# Customize settings
vim .env.local

# Source and run
source .env.local
sudo -E ./brainvault_elite.sh

# Or in one command
sudo bash -c "source .env.local && ./brainvault_elite.sh"
```

**Security Note:** `.env.local` is in `.gitignore` - never commit credentials!

---

## 🎯 Common Scenarios

### Scenario 1: Web Server with Maximum Security

**environment:**
```bash
export SKIP_AI=true
export SECURE_MODE=true
export DISABLE_TELEMETRY_BLOCK=false
export SSH_PORT=2222
export FAIL2BAN_BAN_TIME=86400
```

**Run:**
```bash
source .env.local
sudo -E ./brainvault_elite.sh
```

---

### Scenario 2: ML/AI Development Workstation

**environment:**
```bash
export SKIP_SECURITY=true
export INSTALL_GPU_SUPPORT=true
export PYTHON_VERSION='3.11'
export OLLAMA_MODEL='llama2'
export JUPYTER_PORT=8888
```

**Run:**
```bash
source .env.local
sudo -E ./brainvault_elite.sh
```

---

### Scenario 3: Automated Encrypted Cloud Backups

**1. Configure rclone:**
```bash
cp examples/rclone_config_example.conf ~/.config/rclone/rclone.conf
vim ~/.config/rclone/rclone.conf
# Add your S3 credentials
```

**2. Set environment:**
```bash
export BACKUP_ENCRYPTION_PASSWORD='super-secure-password'
export RCLONE_REMOTE='s3-backup'
export BACKUP_RETENTION_DAYS=90
```

**3. Run installation:**
```bash
sudo -E ./brainvault_elite.sh
```

**4. Backups run automatically at 3:00 AM daily**

---

### Scenario 4: Custom Module Integration

**1. Create custom module:**
```bash
cp examples/custom_module_example.sh scripts/custom/company_tools.sh
```

**2. Customize module:**
```bash
vim scripts/custom/company_tools.sh
# Implement your company-specific tools
```

**3. Test:**
```bash
sudo ./brainvault_elite.sh --dry-run --verbose
```

**4. Deploy:**
```bash
sudo ./brainvault_elite.sh
```

---

## 🔧 Advanced Configuration

### Custom Compliance Profile

Create a compliance-specific configuration:

```bash
# compliance-pci-dss.env
export SECURE_MODE=true
export FAIL2BAN_MAX_RETRY=2
export FAIL2BAN_BAN_TIME=86400
export AUDIT_TO_SYSLOG=true
export BACKUP_RETENTION_DAYS=365
export RUN_POST_AUDIT=true

# Use it
source compliance-pci-dss.env
sudo -E ./brainvault_elite.sh --secure
```

---

### Multi-Environment Setup

**development.env:**
```bash
export SKIP_SECURITY=true
export DRY_RUN=true
export VERBOSE=true
```

**staging.env:**
```bash
export SECURE_MODE=false
export CREATE_SNAPSHOT=true
export AUTO_REBOOT=false
```

**production.env:**
```bash
export SECURE_MODE=true
export DISABLE_TELEMETRY_BLOCK=false
export RUN_POST_AUDIT=true
export ENABLE_EMAIL_NOTIFICATIONS=true
```

**Usage:**
```bash
source production.env
sudo -E ./brainvault_elite.sh
```

---

## 📚 Additional Resources

### Module Development
- See [scripts/README.md](../scripts/README.md) for detailed module development guide
- Study existing modules in [scripts/](../scripts/) directory
- Follow coding standards in [CONTRIBUTING.md](../CONTRIBUTING.md)

### Backup Configuration
- rclone documentation: https://rclone.org/docs/
- Supported remotes: https://rclone.org/overview/
- Encryption: https://rclone.org/crypt/

### Environment Variables
- All available options are documented in `environment_example.sh`
- Override any setting without modifying code
- Use different configs for different environments

---

## 🔒 Security Best Practices

### 1. Protect Configuration Files
```bash
chmod 600 .env.local
chmod 600 ~/.config/rclone/rclone.conf
```

### 2. Never Commit Secrets
- `.env.local` is in `.gitignore`
- Always use environment variables for credentials
- Consider using a secrets manager

### 3. Use Strong Passwords
```bash
# Generate strong password
export BACKUP_ENCRYPTION_PASSWORD="$(openssl rand -base64 32)"
echo "$BACKUP_ENCRYPTION_PASSWORD" > ~/backup_password.txt
chmod 600 ~/backup_password.txt
```

### 4. Regular Backups
```bash
# Test backup system
sudo brainvault-backup

# Verify backup
ls -lh /opt/brainvault/backups/

# Test restore (in VM!)
```

---

## 🧪 Testing Examples

### Test Custom Module
```bash
#!/bin/bash
# Test in isolation

DRY_RUN=true bash -c "
    source scripts/utils/logging.sh
    source scripts/custom/my_module.sh
    setup_my_feature
"
```

### Test with Specific Configuration
```bash
# Create test environment
cat > test.env <<EOF
export DRY_RUN=true
export VERBOSE=true
export SKIP_AI=true
EOF

# Test
source test.env
sudo -E ./brainvault_elite.sh
```

---

## 💡 Tips and Tricks

### 1. Quick Dry-Run Tests
```bash
# Test specific configuration
DRY_RUN=true SKIP_AI=true sudo -E ./brainvault_elite.sh
```

### 2. Override Individual Settings
```bash
# Just change one setting
SECURE_MODE=true sudo ./brainvault_elite.sh
```

### 3. Use Shell Functions
```bash
# Add to ~/.bashrc
brainvault_dev() {
    source ~/projects/brainvault/.env.dev
    sudo -E ~/projects/brainvault/brainvault_elite.sh "$@"
}

brainvault_prod() {
    source ~/projects/brainvault/.env.prod
    sudo -E ~/projects/brainvault/brainvault_elite.sh "$@"
}

# Use it
brainvault_dev --dry-run
brainvault_prod
```

---

## ❓ FAQ

**Q: Can I use multiple custom modules?**
A: Yes! All `.sh` files in `scripts/custom/` are auto-loaded.

**Q: How do I disable a module temporarily?**
A: Rename it to `.disabled` extension: `mv module.sh module.sh.disabled`

**Q: Can I override module functions?**
A: Yes, source your override after the original module loads.

**Q: How do I backup to multiple destinations?**
A: Configure multiple rclone remotes and run backup script for each.

---

## 🆘 Support

- **Documentation**: [README.md](../README.md)
- **Advanced Guide**: [ADVANCED_FEATURES.md](../ADVANCED_FEATURES.md)
- **Contributing**: [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Issues**: https://github.com/md-jahirul/brainvault-elite/issues

---

**Need more examples?** Open an issue and describe your use case!
