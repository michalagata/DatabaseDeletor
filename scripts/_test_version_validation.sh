#!/usr/bin/env zsh
# Test walidacji wersji

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Funkcja normalizująca wersję
normalize_version() {
  local ver="$1"
  ver="${ver%+*}"
  ver=$(echo "$ver" | sed -E 's/\.0+([0-9])/.\1/g; s/^0+([0-9])/\1/')
  echo "$ver"
}

echo "=========================================="
echo "TEST WALIDACJI WERSJI"
echo "=========================================="
echo ""

# Test walidacji
version_txt_path="$PROJECT_ROOT/version.txt"
expected_version="$(cat "$version_txt_path" | tr -d ' \t\r\n')"
echo "version.txt: $expected_version"
echo "Normalized: $(normalize_version "$expected_version")"
echo ""

# Sprawdź .csproj
validation_ok=true
for csproj in "$PROJECT_ROOT/Core/Versioner.csproj" "$PROJECT_ROOT/Cli/Versioner.Cli.csproj"; do
  if [[ -f "$csproj" ]]; then
    csproj_version="$(grep -Eo '<Version>[^<]+</Version>' "$csproj" | sed 's/<Version>\(.*\)<\/Version>/\1/' | head -n1)"
    csproj_normalized=$(normalize_version "$csproj_version")
    expected_normalized=$(normalize_version "$expected_version")
    
    echo "$(basename "$csproj"): $csproj_version"
    echo "  Normalized: $csproj_normalized"
    if [[ "$csproj_normalized" == "$expected_normalized" ]]; then
      echo "  ✓ ZGODNE"
    else
      echo "  ✗ ROZBIEŻNOŚĆ"
      validation_ok=false
    fi
    echo ""
  fi
done

echo "=========================================="
if [[ "$validation_ok" == "true" ]]; then
  echo "✓ WSZYSTKIE WERSJE ZGODNE"
  echo "=========================================="
  exit 0
else
  echo "✗ WYKRYTO ROZBIEŻNOŚCI WERSJI"
  echo "=========================================="
  exit 1
fi
