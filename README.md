# 🧠 BrainVault Elite

### Autonomous Ubuntu Hardening + AI-Stack Bootstrap System

BrainVault Elite is a modular DevSecOps bootstrap framework that orchestrates Ubuntu hardening, developer tooling, and AI stack setup in one workflow. The system is composed of a primary entry script (`brainvault_elite.sh`) that dynamically sources task-specific modules under `scripts/` to keep the codebase maintainable and auditable.

## 🚀 Features
- Modular shell architecture (`scripts/00_logging.sh`, `scripts/10_common.sh`, etc.) automatically sourced at runtime
- Color-aware logging with dry-run awareness and execution summaries
- Preflight checks, snapshot/backup automation, and security hardening routines
- AI/development stack installer with container tooling and Python packages
- Backup, monitoring, and audit automation with cron integration

## 🔧 Usage
```bash
sudo ./brainvault_elite.sh [options]
```

### CLI Flags
- `--dry-run` – Simulate actions and present a unified summary of intended operations
- `--skip-ai` – Bypass AI/development tooling installation
- `--secure` – Enable additional secure-mode hardening (locked root shell, auditd enforcement)
- `--disable-telemetry` – Insert outbound telemetry blocking iptables rules

Run in dry-run mode first to review planned changes:
```bash
sudo ./brainvault_elite.sh --dry-run --skip-ai
```

## 🧱 Module Breakdown
- `00_logging.sh` – Log formatting, color detection, summary helpers
- `10_common.sh` – Environment bootstrapping, command execution, syntax validation
- `20_system.sh` – Snapshots, backups, core packages, cleanup
- `30_security.sh` – Firewall, intrusion prevention, kernel hardening, secure mode
- `40_ai_stack.sh` – Developer tooling, container stack, Python AI libraries
- `50_backup_monitoring.sh` – Encrypted backups, monitoring suite, audit scripts

## ✅ Recommended Workflow
1. Review and optionally customize module scripts under `scripts/`
2. Execute a dry-run to inspect planned commands
3. Run the installer (ideally on a fresh system or test VM) with the desired flags
4. Review `/var/log/brainvault_*.log` (or `./logs/` fallback) for detailed output

## 🔮 Future Enhancements
- Parallelized package installation paths for supported subsystems
- Pluggable LLM-based audit assistant for continuous compliance checks
- Dynamic policy tuning driven by real-time security telemetry
