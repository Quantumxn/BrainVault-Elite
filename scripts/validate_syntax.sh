#!/bin/bash
# validate_syntax.sh - Bash syntax validation for BrainVault Elite

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0
declare -a FAILED_LIST

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     BrainVault Elite - Bash Syntax Validation                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Find all shell scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${BLUE}[INFO]${NC} Searching for shell scripts in: $SCRIPT_DIR"
echo ""

# Find all .sh files
SHELL_SCRIPTS=$(find "$SCRIPT_DIR" -type f -name "*.sh" | sort)

if [[ -z "$SHELL_SCRIPTS" ]]; then
    echo -e "${YELLOW}[WARN]${NC} No shell scripts found"
    exit 0
fi

# Count total files
TOTAL_FILES=$(echo "$SHELL_SCRIPTS" | wc -l)
echo -e "${BLUE}[INFO]${NC} Found $TOTAL_FILES shell script(s) to validate"
echo ""

# Validate each script
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VALIDATION RESULTS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for script in $SHELL_SCRIPTS; do
    # Get relative path
    rel_path=${script#$SCRIPT_DIR/}
    
    # Validate syntax
    if bash -n "$script" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $rel_path"
        ((PASSED_FILES++))
    else
        echo -e "${RED}✗${NC} $rel_path"
        ((FAILED_FILES++))
        FAILED_LIST+=("$rel_path")
        
        # Show error details
        error_output=$(bash -n "$script" 2>&1)
        echo -e "${RED}  └─ Error:${NC} $error_output"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "Total Scripts:   $TOTAL_FILES"
echo -e "${GREEN}Passed:          $PASSED_FILES${NC}"
echo -e "${RED}Failed:          $FAILED_FILES${NC}"
echo ""

# Show failed files if any
if [[ $FAILED_FILES -gt 0 ]]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    FAILED SCRIPTS                              ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    for failed_script in "${FAILED_LIST[@]}"; do
        echo -e "${RED}  ✗${NC} $failed_script"
    done
    echo ""
    echo -e "${YELLOW}[WARN]${NC} Please fix the syntax errors above before deploying"
    echo ""
    exit 1
else
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               ALL SCRIPTS PASSED VALIDATION! ✓                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
fi
