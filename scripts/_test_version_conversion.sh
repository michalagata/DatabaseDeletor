#!/usr/bin/env zsh
# Test script for version conversion logic
# Tests the conversion of 4-segment version (X.Y.Z.W) to 3-segment (X.Y.W)

set -euo pipefail

echo "Testing version conversion logic (zsh)..."
echo "========================================"

# Test function
test_conversion() {
    local input="$1"
    local expected="$2"
    
    echo ""
    echo "Testing: $input → $expected"
    
    local result="$input"
    
    # Apply the same logic as _GithubPublish.sh
    if [[ "$input" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local seg1="${match[1]}"
        local seg2="${match[2]}"
        local seg3="${match[3]}"
        local seg4="${match[4]}"
        result="${seg1}.${seg2}.${seg4}"
        echo "  4-segment detected: segments=($seg1, $seg2, $seg3, $seg4)"
        echo "  Converted to X.Y.W: $result"
    elif [[ "$input" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        echo "  Already 3-segment: $result"
    else
        echo "  Non-standard format: $result"
    fi
    
    if [[ "$result" == "$expected" ]]; then
        echo "  ✓ PASS"
        return 0
    else
        echo "  ✗ FAIL: expected '$expected', got '$result'"
        return 1
    fi
}

# Run tests
failed=0

test_conversion "28.2601.11.125" "28.2601.125" || ((failed++))
test_conversion "1.2.3.4" "1.2.4" || ((failed++))
test_conversion "10.20.30.40" "10.20.40" || ((failed++))
test_conversion "1.0.0.1" "1.0.1" || ((failed++))
test_conversion "28.2601.0.125" "28.2601.125" || ((failed++))
test_conversion "1.2.3" "1.2.3" || ((failed++))
test_conversion "1.0.0" "1.0.0" || ((failed++))

echo ""
echo "========================================"
if [[ $failed -eq 0 ]]; then
    echo "✓ All tests PASSED"
    exit 0
else
    echo "✗ $failed test(s) FAILED"
    exit 1
fi
