#!/bin/bash
# Development module main orchestrator

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

# Source dev modules
source "${SCRIPT_DIR}/dev_tools.sh"
source "${SCRIPT_DIR}/python_stack.sh"
source "${SCRIPT_DIR}/containers.sh"

install_dev_stack() {
    log_section "Installing Development Stack"
    
    install_dev_tools
    install_python_stack
    install_containers
    
    log_success "Development stack installation completed"
}

setup_dev_stack() {
    log_section "Configuring Development Stack"
    
    setup_dev_tools
    setup_python_stack
    setup_containers
    
    log_success "Development stack configuration completed"
}

check_dev_status() {
    log_section "Development Status Check"
    
    check_dev_tools_status
    check_python_stack_status
    check_containers_status
    
    log_success "Development status check completed"
}
