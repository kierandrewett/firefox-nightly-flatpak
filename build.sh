#!/usr/bin/env bash
set -euox pipefail

APP_ID="org.mozilla.FirefoxNightly"
RUNTIME_VERSION="24.08"
ARCH="x86_64"

REDIRECT_URL="https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US"

WORKDIR="$(pwd)"
TMP="$(mktemp -d)"
REPO_DIR="$WORKDIR/repo"
BUILD_DIR="$WORKDIR/build-dir"
DIST_DIR="$WORKDIR/dist"

mkdir -p "$DIST_DIR"

echo "Resolving Nightly download URL…"
FINAL_URL="$(curl -Ls -o /dev/null -w '%{url_effective}' "$REDIRECT_URL")"
[ -n "$FINAL_URL" ]

echo "Downloading Nightly:"
echo "  $FINAL_URL"

curl -L "$FINAL_URL" -o "$TMP/firefox.tar.xz"

# place tarball where flatpak-builder can see it
cp "$TMP/firefox.tar.xz" "$DIST_DIR/firefox.tar.xz"

# manifest
sed \
  -e "s|@RUNTIME_VERSION@|$RUNTIME_VERSION|g" \
  "$WORKDIR/templates/org.mozilla.FirefoxNightly.yml.in" \
  > "$DIST_DIR/org.mozilla.FirefoxNightly.yml"

cp "$WORKDIR/templates/org.mozilla.FirefoxNightly.desktop.in" \
   "$DIST_DIR/org.mozilla.FirefoxNightly.desktop"

cp "$WORKDIR/templates/org.mozilla.FirefoxNightly.appdata.xml" \
   "$DIST_DIR/org.mozilla.FirefoxNightly.appdata.xml"

echo "Building Flatpak…"

flatpak uninstall -y org.mozilla.FirefoxNightly || true

flatpak-builder \
  --force-clean \
  --repo="$REPO_DIR" \
  "$BUILD_DIR" \
  "$DIST_DIR/org.mozilla.FirefoxNightly.yml"

flatpak remote-delete firefox-nightly-local || true
flatpak remote-add --no-gpg-verify firefox-nightly-local "$REPO_DIR"

flatpak install -y firefox-nightly-local "$APP_ID" || \
flatpak update -y "$APP_ID"

echo "Done."
