#!/usr/bin/env bash
set -euox pipefail

source ./config.sh

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
  > "$DIST_DIR/$APP_ID.yml"

cp "$WORKDIR/templates/org.mozilla.FirefoxNightly.desktop.in" \
   "$DIST_DIR/$APP_ID.desktop"

cp "$WORKDIR/templates/org.mozilla.FirefoxNightly.appdata.xml" \
   "$DIST_DIR/$APP_ID.appdata.xml"
   
echo "Building Flatpak…"

flatpak-builder \
  --user \
  --force-clean \
  --repo="$REPO_DIR" \
  "$BUILD_DIR" \
  "$DIST_DIR/$APP_ID.yml"

if [ -n "${CI:-}" ]; then
  # Add a simple HTML landing page in the repo for GitHub Pages (CI only).
  cat >"$REPO_DIR/index.html" <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Firefox Nightly Flatpak Repo</title>
    <meta http-equiv="refresh" content="0; url=https://github.com/kierandrewett/firefox-nightly-flatpak" />
  </head>
  <body>
    <p>
      If you are not redirected automatically, visit
      <a href="https://github.com/kierandrewett/firefox-nightly-flatpak">the GitHub repository</a>.
    </p>
  </body>
</html>
EOF
fi

if [ -z "${CI:-}" ]; then
  flatpak uninstall -y "$APP_ID" || true

  flatpak remote-delete firefox-nightly-local || true
  flatpak remote-add --no-gpg-verify firefox-nightly-local "$REPO_DIR"

  flatpak install -y firefox-nightly-local "$APP_ID" || \
  flatpak update -y "$APP_ID"
fi

echo "Done."
