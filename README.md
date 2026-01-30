# Firefox Nightly Flatpak

Repository hosting builds of Firefox Nightly for Flatpak.

## Using the hosted Flatpak repo

Add this repo as a Flatpak remote and install Firefox Nightly with:

```bash
flatpak remote-add --if-not-exists firefox-nightly https://kierandrewett.github.io/firefox-nightly-flatpak/ --no-gpg-verify
flatpak install -y firefox-nightly org.mozilla.FirefoxNightly
```

To update later:

```bash
flatpak update org.mozilla.FirefoxNightly
```

## Local build

To build and install locally, run:

```bash
./build.sh
```

This will:

- Download the latest Firefox Nightly.
- Build the Flatpak via `flatpak-builder`.
- Create or update a local Flatpak remote `firefox-nightly-local` pointing at the local `repo/` directory.
- Install or update `org.mozilla.FirefoxNightly` from that local remote.

## Why?

I wanted Firefox Nightly on Linux and couldn't find an option that wasn't half-broken. On Fedora especially, the COPR repos are either dead or need more effort to keep working than they're worth.

Flatpak ended up being the least annoying option. It's distro-agnostic, updates cleanly and generally has less hassle.