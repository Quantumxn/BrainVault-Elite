#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Bash Syntax Validation Script
# ================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics
TOTAL_SCRIPTS=0
PASSED_SCRIPTS=0
FAILED_SCRIPTS=0
WARNINGS=0

# Check if shellcheck is available
HAS_SHELLCHECK=false
if command -v shellcheck >/dev/null 2>&1; then
    HAS_SHELLCHECK=true
fi

# Validate a single script
validate_script() {
    local script="$1"
    local script_name=$(basename "$script")
    local errors=0
    local warnings=0
    
    echo -e "${BLUE}Checking:${NC} $script"
    
    # Basic bash syntax check
    if bash -n "$script" 2>&1; then
        echo -e "  ${GREEN}✓${NC} Bash syntax: OK"
        ((PASSED_SCRIPTS++))
    else
        echo -e "  ${RED}✗${NC} Bash syntax: FAILED"
        ((FAILED_SCRIPTS++))
        ((errors++))
        bash -n "$script" 2>&1 | sed 's/^/    /'
    fi
    
    # ShellCheck analysis (if available)
    if [ "$HAS_SHELLCHECK" = "true" ]; then
        local shellcheck_output
        shellcheck_output=$(shellcheck -x "$script" 2>&1 || true)
        
        if [ -z "$shellcheck_output" ]; then
            echo -e "  ${GREEN}✓${NC} ShellCheck: OK"
        else
            echo -e "  ${YELLOW}⚠${NC} ShellCheck: Warnings"
            ((warnings++))
            ((WARNINGS++))
            echo "$shellcheck_output" | sed 's/^/    /'
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} ShellCheck: Not installed (optional)"
    fi
    
    # Check for common issues
    check_common_issues "$script"
    
    echo ""
    return $errors
}

# Check for common issues
check_common_issues() {
    local script="$1"
    local issues=0
    
    # Check for proper shebang
    if ! head -1 "$script" | grep -q "^#!/bin/bash"; then
        echo -e "  ${YELLOW}⚠${NC} Missing or incorrect shebang"
        ((issues++))
    fi
    
    # Check for set -euo pipefail
    if ! grep -q "set -euo pipefail" "$script" && ! grep -q "set -e" "$script"; then
        echo -e "  ${YELLOW}⚠${NC} Consider adding 'set -euo pipefail' for error handling"
        ((issues++))
    fi
    
    # Check for function documentation
    local functions=$(grep -E "^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)" "$script" | wc -l)
    if [ "$functions" -gt 0 ]; then
        echo -e "  ${BLUE}ℹ${NC} Found $functions function(s)"
    fi
    
    if [ $issues -gt 0 ]; then
        ((WARNINGS+=issues))
    fi
}

# Main validation function
main() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}🧠 BrainVault Elite — Bash Syntax Validation${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Find all shell scripts
    local scripts=()
    while IFS= read -r -d '' script; do
        scripts+=("$script")
        ((TOTAL_SCRIPTS++))
    done < <(find "$PROJECT_ROOT" -type f -name "*.sh" -not -path "*/\.git/*" -print0)
    
    # Validate main script
    if [ -f "$PROJECT_ROOT/brainvault_elite.sh" ]; then
        validate_script "$PROJECT_ROOT/brainvault_elite.sh"
    fi
    
    # Validate all scripts in scripts directory
    if [ -d "$SCRIPTS_DIR" ]; then
        for script in "${scripts[@]}"; do
            if [ "$script" != "$PROJECT_ROOT/brainvault_elite.sh" ]; then
                validate_script "$script"
            fi
        done
    fi
    
    # Summary
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Validation Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "Total scripts: ${TOTAL_SCRIPTS}"
    echo -e "${GREEN}Passed: ${PASSED_SCRIPTS}${NC}"
    
    if [ $FAILED_SCRIPTS -gt 0 ]; then
        echo -e "${RED}Failed: ${FAILED_SCRIPTS}${NC}"
    else
        echo -e "${GREEN}Failed: ${FAILED_SCRIPTS}${NC}"
    fi
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Warnings: ${WARNINGS}${NC}"
    else
        echo -e "${GREEN}Warnings: ${WARNINGS}${NC}"
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    # Exit code
    if [ $FAILED_SCRIPTS -gt 0 ]; then
        echo -e "${RED}✗ Validation FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Validation PASSED${NC}"
        exit 0
    fi
}

# Run validation
main
