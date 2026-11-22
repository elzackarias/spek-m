# Building the macOS bundle

Works natively on both Apple Silicon (arm64, Homebrew in `/opt/homebrew`)
and Intel (x86_64, Homebrew in `/usr/local`).

Using [Homebrew](http://brew.sh) install build dependencies:

    brew install autoconf automake libtool pkgconf gettext git
    brew install ffmpeg wxwidgets
    brew install meson ninja cmake nasm

Rebuild the libraries whose Homebrew bottles need a newer macOS than the
target (only needed once, or after `brew upgrade`):

    ./dist/osx/build-deps.sh

Bundle Spek:

    ./dist/osx/bundle.sh

Both scripts target macOS 27.0 by default; override with `MACOS_TARGET=...`.
`bundle.sh` fails if any bundled library needs a newer macOS, and lists which
ones to add to `build-deps.sh`.

The app is signed ad-hoc by default. To sign with a Developer ID instead:

    SIGN_IDENTITY="Developer ID Application: ..." ./dist/osx/bundle.sh

