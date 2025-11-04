#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_TELEMETRY_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_TELEMETRY_SH=1

: "${DISABLE_TELEMETRY:=false}"

install_telemetry_block() {
  log_info "Preparing telemetry blocklist tooling"

  if [[ "${DISABLE_TELEMETRY}" != "true" ]]; then
    log_warn "Telemetry blocking disabled by runtime flag"
    return 0
  fi

  ensure_dependencies sudo apt-get || return 1

  perform_step "Install required utilities" sudo apt-get install -y curl jq

  log_success "Telemetry blocklist tooling installed"
}

setup_telemetry_block() {
  log_info "Applying telemetry blocking policies"
  if [[ "${DISABLE_TELEMETRY}" != "true" ]]; then
    log_warn "Telemetry blocking skipped"
    return 0
  fi
  ensure_dependencies sudo tee || return 1

  local blocklist_path="/etc/brainvault/telemetry-blocklist.txt"

  perform_step "Create BrainVault config directory" sudo mkdir -p /etc/brainvault
  perform_step "Write telemetry blocklist" sudo tee "${blocklist_path}" >/dev/null <<'EOF'
0.0.0.0 telemetry.microsoft.com
0.0.0.0 telemetry.apple.com
0.0.0.0 incoming.telemetry.mozilla.org
0.0.0.0 google-analytics.com
EOF

  perform_step "Apply hosts entries" sudo tee -a /etc/hosts >/dev/null <"${blocklist_path}"

  log_success "Telemetry blocking rules applied"
}

