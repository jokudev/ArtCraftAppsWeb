#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$ROOT/site"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

APPS=(wordcraft deckcraft gridcraft pdfcraft)

command -v curl >/dev/null || { echo "error: curl is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
command -v unzip >/dev/null || { echo "error: unzip is required" >&2; exit 1; }
mkdir -p "$SITE_DIR"

for app in "${APPS[@]}"; do
  download_dir="$TMP_DIR/$app"
  mkdir -p "$download_dir"

  echo "Looking up the latest $app web release..."
  release_json="$(curl --fail --silent --show-error --location \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/storytold/$app/releases/latest")"
  asset_url="$(jq -r --arg prefix "$app-web-" \
    '[.assets[] | select(.name | startswith($prefix) and endswith(".zip"))][0].browser_download_url // empty' \
    <<< "$release_json")"
  if [[ -z "$asset_url" ]]; then
    echo "error: latest $app release has no $app-web-*.zip asset" >&2
    exit 1
  fi

  archive="$download_dir/${asset_url##*/}"
  curl --fail --silent --show-error --location "$asset_url" --output "$archive"

  package_name="$(basename "${archive%.zip}")"
  if ! unzip -q "$archive" -d "$download_dir"; then
    echo "error: could not extract $archive" >&2
    exit 1
  fi
  if [[ ! -f "$download_dir/$package_name/index.html" ]]; then
    echo "error: $archive does not contain $package_name/index.html" >&2
    exit 1
  fi

  rm -rf "$SITE_DIR/$app"
  mkdir -p "$SITE_DIR/$app"
  cp -R "$download_dir/$package_name/." "$SITE_DIR/$app/"
  echo "Staged $app release $(basename "$archive" .zip) at $SITE_DIR/$app"
done

echo "All latest web release assets are staged under $SITE_DIR."
