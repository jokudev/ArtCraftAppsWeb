#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$ROOT/site"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

APPS=(wordcraft deckcraft gridcraft pdfcraft)

command -v curl >/dev/null || { echo "error: curl is required" >&2; exit 1; }
command -v unzip >/dev/null || { echo "error: unzip is required" >&2; exit 1; }
mkdir -p "$SITE_DIR"

for app in "${APPS[@]}"; do
  download_dir="$TMP_DIR/$app"
  mkdir -p "$download_dir"

  echo "Resolving the latest $app release..."
  latest_url="$(curl --fail --silent --show-error --location \
    --output /dev/null --write-out '%{url_effective}' \
    "https://github.com/storytold/$app/releases/latest")"
  if [[ "$latest_url" != "https://github.com/storytold/$app/releases/tag/"* ]]; then
    echo "error: could not resolve the latest $app release tag ($latest_url)" >&2
    exit 1
  fi

  tag="${latest_url##*/}"
  version="${tag#v}"
  archive="$download_dir/$app-web-$version.zip"
  asset_url="https://github.com/storytold/$app/releases/download/$tag/$(basename "$archive")"
  curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
    "$asset_url" --output "$archive"

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
