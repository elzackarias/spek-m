# Spek for Apple Silicon (M1, M2, M3, M4...)

A native port of [Spek](https://www.spek.cc/) for Macs with Apple M-series chips.

Spek is an acoustic spectrum analyser written in C++. It uses FFmpeg for audio
decoding and wxWidgets for the GUI. It's handy for things like checking whether
a "lossless" file is truly lossless or a transcoded MP3.

## Why this port?

The last official macOS release of Spek (0.8.2) is Intel-only. On Apple Silicon
Macs it only runs through Rosetta 2, which Apple has announced is going away.
This fork builds Spek natively for arm64, so it runs faster and without Rosetta.

## Download and install

Requirements: an **Apple Silicon Mac** running **macOS 27.0 or later**.

1. Download the `.dmg` from the
   [latest release](https://github.com/elzackarias/spek-m/releases/latest).
2. Open it and drag Spek to **Applications**.
3. The app is not notarized by Apple, so macOS blocks it the first time. To
   allow it:
   - Open Spek. macOS warns that it can't verify the app; click **Done**.
   - Go to **System Settings → Privacy & Security**, scroll down to the message
     about Spek, click **Open Anyway** and confirm with your password.

   This is only needed once. Alternatively, run this in Terminal:

       xattr -dr com.apple.quarantine /Applications/Spek.app

## What changed from upstream

- **Native arm64 build**, with Homebrew in `/opt/homebrew`. The scripts still
  work on Intel.
- **FFmpeg 8 and 9 support**: the FFT was ported from the `avfft` API (removed
  in FFmpeg 8) to `av_tx`.
- **Self-contained bundle**: every library ships inside the app, so Homebrew is
  not needed to run it.
- **Ad-hoc code signing**, which arm64 binaries require to run.
- **macOS 27.0 minimum**: libraries whose Homebrew bottles require a newer
  macOS are rebuilt by `dist/osx/build-deps.sh`.
- **Accented file names on network shares**: files like `León.flac` on SMB
  shares now open (wxWidgets converts names to Unicode NFC; Spek now matches
  them to the exact on-disk spelling).
- **Tests updated** for FFmpeg 9, plus new path tests.

## Building from source

See [dist/osx/README.md](dist/osx/README.md) for details. In short:

    brew install autoconf automake libtool pkgconf gettext git
    brew install ffmpeg wxwidgets meson ninja cmake nasm
    ./dist/osx/build-deps.sh
    ./dist/osx/bundle.sh

The result is written to `dist/osx/Spek.dmg`.

## Credits and license

Spek was created by Alexander Kojevnikov and contributors
([upstream project](https://github.com/alexkay/spek), [CREDITS.md](CREDITS.md)).
This fork only adds the Apple Silicon port.

Licensed under the GPL v3; see [LICENSE](LICENSE).
