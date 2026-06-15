#!/usr/bin/env bash
set -euo pipefail

# Update all Homebrew formulas to their latest GitHub release versions.
# Usage: ./update.sh [formula_name]
#   No args: updates all formulas in Formula/
#   With arg: updates only that formula (e.g. ./update.sh loupe)

FORMULA_DIR="$(cd "$(dirname "$0")/Formula" && pwd)"

update_formula() {
  local rb="$1"
  local name
  name="$(basename "$rb" .rb)"

  # Extract repo from homepage
  local homepage
  homepage=$(grep -m1 'homepage' "$rb" | sed 's/.*"\(.*\)".*/\1/')
  local repo
  repo=$(echo "$homepage" | sed 's|https://github.com/||')

  # Optional tag prefix for monorepo-resident tools (read from a comment marker)
  local tag_prefix
  tag_prefix=$(grep -m1 '^[[:space:]]*# tag_prefix:' "$rb" 2>/dev/null | sed 's/^[[:space:]]*# tag_prefix:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r' || echo "")

  # Get latest release tag
  local latest latest_version
  if [ -n "$tag_prefix" ]; then
    # Monorepo: pick the latest release whose tag starts with this product's prefix.
    latest=$(gh release list --repo "$repo" --limit 100 --json tagName -q "[.[].tagName | select(startswith(\"$tag_prefix\"))] | .[0]" 2>/dev/null | tr -d '\r') || latest=""
    if [ -z "$latest" ] || [ "$latest" = "null" ]; then
      echo "  ⏭  $name: no $tag_prefix* releases, skipping"
      return
    fi
    latest_version="${latest#$tag_prefix}"
  else
    latest=$(gh release view --repo "$repo" --json tagName -q .tagName 2>/dev/null) || {
      echo "  ⏭  $name: no releases found, skipping"
      return
    }
    latest_version="${latest#v}"
  fi

  # Get current version
  local current
  current=$(grep -m1 'version ' "$rb" | sed 's/.*"\(.*\)".*/\1/')

  if [ "$current" = "$latest_version" ] && ! grep -q 'sha256 "0\{64\}"' "$rb"; then
    echo "  ✓  $name: already at $current"
    return
  fi

  echo "  ↑  $name: $current → $latest_version"

  # Download assets and compute hashes
  local tmpdir
  tmpdir=$(mktemp -d)
  gh release download "$latest" --repo "$repo" --dir "$tmpdir" --pattern "*.tar.gz" 2>/dev/null || true

  # Update version string and URLs (skip sha256 lines to avoid corrupting hashes)
  sed -i '' "/sha256/!s/$current/$latest_version/g" "$rb"

  # Update sha256 hashes by matching each downloaded asset to its URL line
  for asset in "$tmpdir"/*.tar.gz; do
    [ -f "$asset" ] || continue
    local basename_asset
    basename_asset=$(basename "$asset")
    local sha
    sha=$(shasum -a 256 "$asset" | awk '{print $1}')

    # Find the URL line for this asset, then update the sha256 on the next line
    local url_line
    url_line=$(grep -n "$basename_asset" "$rb" | head -1 | cut -d: -f1)
    if [ -n "$url_line" ]; then
      local sha_line
      sha_line=$(tail -n +"$url_line" "$rb" | grep -n 'sha256' | head -1 | cut -d: -f1)
      if [ -n "$sha_line" ]; then
        local actual_line=$((url_line + sha_line - 1))
        sed -i '' "${actual_line}s/sha256 \"[a-f0-9]*\"/sha256 \"$sha\"/" "$rb"
      fi
    fi
  done

  rm -rf "$tmpdir"
  echo "       updated $rb"
}

if [ $# -gt 0 ]; then
  formulas=("$FORMULA_DIR/$1.rb")
else
  formulas=("$FORMULA_DIR"/*.rb)
fi

echo "Checking Homebrew formulas..."
for rb in "${formulas[@]}"; do
  if [ -f "$rb" ]; then
    update_formula "$rb"
  else
    echo "  ✗  $(basename "$rb"): not found"
  fi
done
