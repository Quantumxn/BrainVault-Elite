#!/bin/bash
# ================================================================
# BrainVault Elite - Validation Utilities
# Bash syntax validation and module verification
# ================================================================

# ============= Bash Syntax Validation =============

validate_bash_syntax() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file"
        return 1
    fi
    
    if bash -n "$file" 2>/dev/null; then
        echo "✓ $file: Valid syntax"
        return 0
    else
        echo "✗ $file: Syntax error"
        bash -n "$file" 2>&1
        return 1
    fi
}

# ============= Module Import Validation =============

validate_module_imports() {
    local file="$1"
    local base_dir="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file"
        return 1
    fi
    
    echo "Checking imports in: $file"
    
    local errors=0
    
    # Find all source statements
    while IFS= read -r source_line; do
        # Extract the sourced file path
        local sourced_file
        sourced_file=$(echo "$source_line" | sed -n 's/.*source[[:space:]]*['"'"'"]\([^'"'"'"]*\)['"'"'"].*/\1/p')
        
        if [[ -z "$sourced_file" ]]; then
            continue
        fi
        
        # Handle relative paths
        if [[ "$sourced_file" =~ ^\$\(dirname ]]; then
            # This is a relative path, can't validate easily
            echo "  ℹ️  Relative import: $sourced_file"
            continue
        fi
        
        # Check if file exists
        local full_path="$base_dir/$sourced_file"
        if [[ -f "$full_path" ]]; then
            echo "  ✓ Import found: $sourced_file"
        else
            echo "  ✗ Import missing: $sourced_file"
            ((errors++))
        fi
    done < <(grep -E "^[[:space:]]*source[[:space:]]" "$file" 2>/dev/null)
    
    if [[ $errors -eq 0 ]]; then
        echo "✓ All imports validated"
        return 0
    else
        echo "✗ $errors import errors found"
        return 1
    fi
}

# ============= Function Export Validation =============

validate_function_exports() {
    local file="$1"
    
    echo "Checking function exports in: $file"
    
    # Find all function definitions
    local functions=()
    while IFS= read -r func_name; do
        functions+=("$func_name")
    done < <(grep -oP '^\s*\K[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\(\))' "$file" 2>/dev/null)
    
    if [[ ${#functions[@]} -eq 0 ]]; then
        echo "  ℹ️  No functions defined"
        return 0
    fi
    
    echo "  Found ${#functions[@]} functions"
    
    # Check if functions are exported
    local exported=0
    local not_exported=0
    
    for func in "${functions[@]}"; do
        if grep -q "export -f.*$func" "$file" 2>/dev/null; then
            ((exported++))
        else
            ((not_exported++))
            echo "  ⚠️  Not exported: $func"
        fi
    done
    
    echo "  Exported: $exported, Not exported: $not_exported"
    return 0
}

# ============= Main Validation Script =============

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # This script is being run directly
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     BrainVault Elite - Syntax & Import Validation         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    total_files=0
    valid_files=0
    invalid_files=0
    
    # Validate all bash scripts
    while IFS= read -r -d '' script; do
        ((total_files++))
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "Validating: $script"
        echo "═══════════════════════════════════════════════════════════"
        
        if validate_bash_syntax "$script"; then
            ((valid_files++))
            
            # Additional checks for module files
            if [[ "$script" =~ /scripts/ ]]; then
                validate_function_exports "$script"
            fi
        else
            ((invalid_files++))
        fi
    done < <(find "$PROJECT_ROOT" -type f -name "*.sh" -print0 2>/dev/null)
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "Validation Summary"
    echo "═══════════════════════════════════════════════════════════"
    echo "Total files: $total_files"
    echo "Valid: $valid_files"
    echo "Invalid: $invalid_files"
    echo ""
    
    if [[ $invalid_files -eq 0 ]]; then
        echo "✅ All scripts passed validation!"
        exit 0
    else
        echo "❌ $invalid_files scripts have errors"
        exit 1
    fi
fi
