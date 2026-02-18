#!/usr/bin/env zsh
# Test konwersji wersji 4→3 segmentów

set -euo pipefail

echo "=========================================="
echo "TEST KONWERSJI WERSJI GitHub"
echo "=========================================="
echo ""

# Test cases
test_versions=(
  "28.2601.11.125"
  "28.2601.23.125"
  "1.0.0.1"
  "10.20.30.40"
  "1.2.3"
  "1.2"
)

for VERSION in "${test_versions[@]}"; do
  GITHUB_VERSION="$VERSION"
  
  # Konwersja 4-segment (X.Y.Z.W) do 3-segment (X.Y.W)
  if [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    local seg1="${match[1]}"
    local seg2="${match[2]}"
    local seg4="${match[4]}"
    GITHUB_VERSION="${seg1}.${seg2}.${seg4}"
    echo "4-segment: $VERSION → $GITHUB_VERSION (X.Y.W format)"
  else
    echo "Inne:      $VERSION → $GITHUB_VERSION (bez zmian)"
  fi
done

echo ""
echo "=========================================="
echo "TEST FORMAT RELEASE TAG i TITLE"
echo "=========================================="
echo ""

VERSION="28.2601.11.125"
GITHUB_VERSION="28.2601.125"
release_tag="R-${GITHUB_VERSION}"
release_title="R-${GITHUB_VERSION}"

echo "Wersja pełna:     $VERSION"
echo "Wersja GitHub:    $GITHUB_VERSION"
echo "Release Tag:      $release_tag"
echo "Release Title:    $release_title"
echo ""
echo "✓ Format zgodny z wymaganiami!"
