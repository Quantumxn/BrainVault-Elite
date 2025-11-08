#!/usr/bin/env bash

setup_container_stack() {
    local context="DEV:CONTAINERS"
    local docker_repo="/etc/apt/sources.list.d/docker.list"
    local docker_gpg="/usr/share/keyrings/docker-archive-keyring.gpg"
    local target_user="${TARGET_USER:-${SUDO_USER:-${USER}}}"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get curl systemctl

    run_apt_install "$context" "Install Docker prerequisites" ca-certificates curl gnupg lsb-release

    if is_dry_run; then
        simulate_file_change "$context" "$docker_gpg"
        simulate_file_change "$context" "$docker_repo"
    else
        run_step "$context" "Add Docker GPG key" bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o ${docker_gpg}"
        run_step "$context" "Configure Docker repository" bash -c "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=${docker_gpg}] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee ${docker_repo} >/dev/null"
    fi

    run_apt_update "$context" "Update apt cache for Docker"
    run_apt_install "$context" "Install Docker Engine" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    run_step "$context" "Enable Docker service" sudo systemctl enable --now docker

    if [[ -n "$target_user" ]]; then
        run_step "$context" "Add ${target_user} to docker group" sudo usermod -aG docker "$target_user"
    fi

    clear_error_handler
    log_success "[$context] Container stack ready"
}

export -f setup_container_stack
