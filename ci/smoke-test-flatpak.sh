#!/usr/bin/env bash
set -euo pipefail

source ./config.sh

flatpak --user remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user remote-add --no-gpg-verify --if-not-exists \
  firefox-nightly-local "$PWD/repo"
timeout --kill-after=5s 10m \
  flatpak --user install --assumeyes firefox-nightly-local "$APP_ID"
timeout --kill-after=5s 30s flatpak --user info "$APP_ID"

unset WAYLAND_DISPLAY
timeout --signal=TERM --kill-after=5s 45s \
  flatpak --user run "$APP_ID" about:blank &
firefox_pid=$!

cleanup() {
  timeout --kill-after=2s 10s flatpak --user kill "$APP_ID" >/dev/null 2>&1 || true
  wait "$firefox_pid" || true
}
trap cleanup EXIT

for _ in {1..30}; do
  if ! kill -0 "$firefox_pid" 2>/dev/null; then
    wait "$firefox_pid" || true
    echo "Firefox Nightly exited before opening a window" >&2
    exit 1
  fi

  if xwininfo -root -tree 2>/dev/null | grep -qi firefox; then
    echo "Firefox Nightly opened an X11 window under Xvfb"
    exit 0
  fi

  sleep 1
done

echo "Firefox Nightly did not open an X11 window within 30 seconds" >&2
exit 1
