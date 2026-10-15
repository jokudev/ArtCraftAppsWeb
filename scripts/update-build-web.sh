#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPS_DIR="$ROOT/apps"
SITE_DIR="$ROOT/site"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

APPS=(wordcraft deckcraft gridcraft pdfcraft)

mkdir -p "$APPS_DIR" "$SITE_DIR"

for app in "${APPS[@]}"; do
  repo="https://github.com/storytold/$app.git"
  checkout="$APPS_DIR/$app"

  if [[ ! -d "$checkout/.git" ]]; then
    if [[ -e "$checkout" ]]; then
      echo "error: $checkout exists but is not a Git checkout" >&2
      exit 1
    fi
    git clone --branch main --single-branch "$repo" "$checkout"
  else
    current_remote="$(git -C "$checkout" remote get-url origin)"
    if [[ "${current_remote%.git}" != "${repo%.git}" ]]; then
      echo "error: $checkout has unexpected origin $current_remote" >&2
      exit 1
    fi
    if [[ "$(git -C "$checkout" branch --show-current)" != "main" ]]; then
      echo "error: $checkout must be on the main branch to update" >&2
      exit 1
    fi
    if [[ -n "$(git -C "$checkout" status --porcelain)" ]]; then
      echo "error: $checkout has local changes; commit or stash them before updating" >&2
      exit 1
    fi
    git -C "$checkout" fetch --prune origin main
    git -C "$checkout" merge --ff-only origin/main
  fi

  package_script="$checkout/packaging/web/package.sh"
  if [[ ! -x "$package_script" ]]; then
    echo "error: missing executable web package script: $package_script" >&2
    exit 1
  fi

  echo "Building and packaging $app..."
  (cd "$checkout" && "$package_script")

  archive="$(ls -1t "$checkout"/dist/"$app"-web-*.zip 2>/dev/null | head -n 1 || true)"
  if [[ -z "$archive" ]]; then
    echo "error: no $app web archive found in $checkout/dist" >&2
    exit 1
  fi

  package_dir="${archive%.zip}"
  package_name="$(basename "$package_dir")"
  if ! unzip -q "$archive" -d "$TMP_DIR/$app"; then
    echo "error: could not extract $archive" >&2
    exit 1
  fi
  if [[ ! -f "$TMP_DIR/$app/$package_name/index.html" ]]; then
    echo "error: $archive does not contain $package_name/index.html" >&2
    exit 1
  fi

  rm -rf "$SITE_DIR/$app"
  mkdir -p "$SITE_DIR/$app"
  cp -R "$TMP_DIR/$app/$package_name/." "$SITE_DIR/$app/"
  echo "Published $app to $SITE_DIR/$app"
done

echo "All apps are built and staged under $SITE_DIR."
