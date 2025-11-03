#!/bin/bash
# ================================================================
# BrainVault Elite - Test Suite
# Comprehensive testing for all components
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ============= Helper Functions =============

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║$(printf '%*s' $((30 + ${#1}/2)) "$1")$(printf '%*s' $((30 - ${#1}/2)) '')║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

test_skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    ((TESTS_SKIPPED++))
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name"
        return 1
    fi
}

# ============= Syntax Tests =============

test_syntax() {
    print_header "Bash Syntax Validation"
    
    local failed_files=()
    
    while IFS= read -r -d '' script; do
        if bash -n "$script" 2>/dev/null; then
            test_pass "Syntax: $(basename "$script")"
        else
            test_fail "Syntax: $(basename "$script")"
            failed_files+=("$script")
        fi
    done < <(find . -type f -name "*.sh" -print0)
    
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        echo -e "\n${RED}Failed files:${NC}"
        printf '%s\n' "${failed_files[@]}"
    fi
}

# ============= Module Tests =============

test_modules() {
    print_header "Module Loading Tests"
    
    # Test if modules directory exists
    if [[ ! -d "scripts" ]]; then
        test_fail "scripts/ directory not found"
        return 1
    fi
    test_pass "scripts/ directory exists"
    
    # Test module structure
    local expected_dirs=("core" "security" "ai" "backup" "monitoring" "utils")
    for dir in "${expected_dirs[@]}"; do
        if [[ -d "scripts/$dir" ]]; then
            test_pass "Module directory: $dir"
        else
            test_fail "Module directory: $dir"
        fi
    done
    
    # Test if modules have required files
    if [[ -f "scripts/utils/logging.sh" ]]; then
        test_pass "Logging module exists"
    else
        test_fail "Logging module missing (critical)"
        return 1
    fi
    
    # Test module sourcing
    if bash -c "source scripts/utils/logging.sh && declare -F log &>/dev/null"; then
        test_pass "Logging module sources correctly"
    else
        test_fail "Logging module has errors"
    fi
}

# ============= Function Export Tests =============

test_function_exports() {
    print_header "Function Export Validation"
    
    # Source logging first
    source scripts/utils/logging.sh 2>/dev/null || {
        test_fail "Cannot source logging.sh"
        return 1
    }
    test_pass "Logging module sourced"
    
    # Test exported functions from logging
    local logging_functions=(
        "log" "log_info" "log_success" "log_warn" "log_error" 
        "run_cmd" "install_pkg" "check_command"
    )
    
    for func in "${logging_functions[@]}"; do
        if declare -F "$func" &>/dev/null; then
            test_pass "Function exported: $func"
        else
            test_fail "Function not exported: $func"
        fi
    done
}

# ============= Main Script Tests =============

test_main_script() {
    print_header "Main Script Validation"
    
    # Check if main script exists
    if [[ ! -f "brainvault_elite.sh" ]]; then
        test_fail "brainvault_elite.sh not found"
        return 1
    fi
    test_pass "Main script exists"
    
    # Check if executable
    if [[ -x "brainvault_elite.sh" ]]; then
        test_pass "Main script is executable"
    else
        test_fail "Main script not executable"
    fi
    
    # Check shebang
    if head -1 brainvault_elite.sh | grep -q "^#!/bin/bash"; then
        test_pass "Correct shebang"
    else
        test_fail "Invalid shebang"
    fi
    
    # Check for help option
    if grep -q "\-\-help" brainvault_elite.sh; then
        test_pass "Help option available"
    else
        test_fail "Help option missing"
    fi
    
    # Check for dry-run option
    if grep -q "\-\-dry-run" brainvault_elite.sh; then
        test_pass "Dry-run option available"
    else
        test_fail "Dry-run option missing"
    fi
}

# ============= CLI Argument Tests =============

test_cli_arguments() {
    print_header "CLI Argument Parsing"
    
    # Test help (should not require root)
    if ./brainvault_elite.sh --help 2>&1 | grep -q "BrainVault Elite"; then
        test_pass "Help displays correctly"
    else
        test_fail "Help not working"
    fi
    
    # Test invalid argument
    if ./brainvault_elite.sh --invalid-option 2>&1 | grep -q "Unknown option"; then
        test_pass "Invalid option detection works"
    else
        test_fail "Invalid option not detected"
    fi
}

# ============= Dry-Run Tests =============

test_dry_run() {
    print_header "Dry-Run Mode Tests"
    
    echo "Note: Dry-run tests require root privileges"
    
    if [[ $EUID -ne 0 ]]; then
        test_skip "Dry-run test (requires root)"
        return 0
    fi
    
    # Test dry-run mode
    local dry_run_output="/tmp/brainvault_dryrun_test.log"
    if timeout 30 ./brainvault_elite.sh --dry-run > "$dry_run_output" 2>&1; then
        test_pass "Dry-run completes without errors"
        
        # Check for dry-run indicators
        if grep -q "DRY-RUN" "$dry_run_output"; then
            test_pass "Dry-run mode active"
        else
            test_fail "Dry-run mode not working"
        fi
        
        # Check for summary
        if grep -q "DRY-RUN SUMMARY" "$dry_run_output"; then
            test_pass "Dry-run summary generated"
        else
            test_fail "Dry-run summary missing"
        fi
    else
        test_fail "Dry-run failed to complete"
    fi
    
    rm -f "$dry_run_output"
}

# ============= Documentation Tests =============

test_documentation() {
    print_header "Documentation Validation"
    
    # Check README
    if [[ -f "README.md" ]]; then
        test_pass "README.md exists"
        
        # Check for required sections
        if grep -q "Quick Start" README.md; then
            test_pass "README has Quick Start section"
        else
            test_fail "README missing Quick Start"
        fi
        
        if grep -q "Installation" README.md; then
            test_pass "README has Installation section"
        else
            test_fail "README missing Installation"
        fi
    else
        test_fail "README.md not found"
    fi
    
    # Check for ADVANCED_FEATURES
    if [[ -f "ADVANCED_FEATURES.md" ]]; then
        test_pass "ADVANCED_FEATURES.md exists"
    else
        test_skip "ADVANCED_FEATURES.md not found"
    fi
    
    # Check module documentation
    if [[ -f "scripts/README.md" ]]; then
        test_pass "Module documentation exists"
    else
        test_skip "Module documentation not found"
    fi
}

# ============= Security Tests =============

test_security_features() {
    print_header "Security Feature Detection"
    
    # Check for security modules
    if [[ -f "scripts/security/firewall.sh" ]]; then
        test_pass "Firewall module exists"
    else
        test_fail "Firewall module missing"
    fi
    
    if [[ -f "scripts/security/intrusion_detection.sh" ]]; then
        test_pass "Intrusion detection module exists"
    else
        test_fail "Intrusion detection module missing"
    fi
    
    if [[ -f "scripts/security/kernel_hardening.sh" ]]; then
        test_pass "Kernel hardening module exists"
    else
        test_fail "Kernel hardening module missing"
    fi
    
    # Check for security functions
    if grep -q "setup_firewall" scripts/security/*.sh; then
        test_pass "Firewall setup function exists"
    else
        test_fail "Firewall setup function missing"
    fi
    
    if grep -q "setup_fail2ban" scripts/security/*.sh; then
        test_pass "Fail2ban setup function exists"
    else
        test_fail "Fail2ban setup function missing"
    fi
}

# ============= AI Stack Tests =============

test_ai_features() {
    print_header "AI Stack Detection"
    
    # Check for AI modules
    if [[ -f "scripts/ai/python_stack.sh" ]]; then
        test_pass "Python stack module exists"
    else
        test_fail "Python stack module missing"
    fi
    
    if [[ -f "scripts/ai/container_stack.sh" ]]; then
        test_pass "Container stack module exists"
    else
        test_fail "Container stack module missing"
    fi
    
    # Check for AI functions
    if grep -q "install_python_dev" scripts/ai/*.sh; then
        test_pass "Python install function exists"
    else
        test_fail "Python install function missing"
    fi
    
    if grep -q "install_docker" scripts/ai/*.sh; then
        test_pass "Docker install function exists"
    else
        test_fail "Docker install function missing"
    fi
}

# ============= Validation Script Test =============

test_validation_script() {
    print_header "Validation Script Tests"
    
    if [[ -f "scripts/utils/validation.sh" ]]; then
        test_pass "Validation script exists"
        
        if [[ -x "scripts/utils/validation.sh" ]]; then
            test_pass "Validation script is executable"
        else
            test_fail "Validation script not executable"
        fi
        
        # Run validation script
        if bash scripts/utils/validation.sh &>/dev/null; then
            test_pass "Validation script runs successfully"
        else
            test_fail "Validation script has errors"
        fi
    else
        test_fail "Validation script not found"
    fi
}

# ============= File Permissions Tests =============

test_permissions() {
    print_header "File Permissions"
    
    # Check main script
    if [[ -x "brainvault_elite.sh" ]]; then
        test_pass "Main script is executable"
    else
        test_fail "Main script not executable"
    fi
    
    # Check validation script
    if [[ -x "scripts/utils/validation.sh" ]]; then
        test_pass "Validation script is executable"
    else
        test_fail "Validation script not executable"
    fi
    
    # Check that modules are readable
    local unreadable=()
    while IFS= read -r -d '' script; do
        if [[ ! -r "$script" ]]; then
            unreadable+=("$script")
        fi
    done < <(find scripts -type f -name "*.sh" -print0)
    
    if [[ ${#unreadable[@]} -eq 0 ]]; then
        test_pass "All modules are readable"
    else
        test_fail "Some modules are not readable"
        printf '%s\n' "${unreadable[@]}"
    fi
}

# ============= Structure Tests =============

test_directory_structure() {
    print_header "Directory Structure"
    
    local required_dirs=(
        "scripts"
        "scripts/core"
        "scripts/security"
        "scripts/ai"
        "scripts/backup"
        "scripts/monitoring"
        "scripts/utils"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            test_pass "Directory exists: $dir"
        else
            test_fail "Directory missing: $dir"
        fi
    done
}

# ============= Main Test Runner =============

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      BrainVault Elite - Comprehensive Test Suite          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Starting tests at $(date)"
    echo ""
    
    # Run all test suites
    test_directory_structure
    test_syntax
    test_modules
    test_function_exports
    test_main_script
    test_cli_arguments
    test_documentation
    test_security_features
    test_ai_features
    test_validation_script
    test_permissions
    test_dry_run
    
    # Print summary
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                     Test Summary                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo ""
    
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    echo "Total tests: $total"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✅ All tests passed!${NC}"
        echo ""
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Some tests failed${NC}"
        echo ""
        exit 1
    fi
}

# Run tests
main "$@"
