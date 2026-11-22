#!/usr/bin/env bash

# Rebuilds Homebrew libraries whose bottles require a newer macOS than
# MACOS_TARGET, so the bundled app runs on MACOS_TARGET and later.
# The same versions as the installed Homebrew packages are built, from the
# checksum-verified sources that `brew fetch` downloads, into dist/osx/deps.
# bundle.sh then bundles these instead of the Homebrew copies.

set -euo pipefail

MACOS_TARGET=${MACOS_TARGET:-27.0}
export MACOSX_DEPLOYMENT_TARGET=$MACOS_TARGET

cd $(dirname $0)
DEPS=$(pwd)/deps
BUILD=$(pwd)/deps-build
rm -rf "$DEPS" "$BUILD"
mkdir -p "$DEPS/lib" "$BUILD"

unpack() {
    brew fetch -s "$1" >/dev/null
    mkdir -p "$BUILD/$1"
    tar -xf "$(brew --cache -s "$1")" -C "$BUILD/$1" --strip-components 1
}

echo "Building dav1d for macOS $MACOS_TARGET+..."
unpack dav1d
meson setup "$BUILD/dav1d/build" "$BUILD/dav1d" \
    --prefix="$BUILD/dav1d/install" --buildtype=release \
    -Denable_tools=false -Denable_tests=false
ninja -C "$BUILD/dav1d/build" install

echo "Building svt-av1 for macOS $MACOS_TARGET+..."
unpack svt-av1
cmake -S "$BUILD/svt-av1" -B "$BUILD/svt-av1/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$BUILD/svt-av1/install" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOS_TARGET" \
    -DBUILD_APPS=OFF -DBUILD_TESTING=OFF
ninja -C "$BUILD/svt-av1/build" install

# Keep only the real dylib files (not symlinks), named like Homebrew's.
for lib in "$BUILD"/*/install/lib/*.dylib; do
    [ -L "$lib" ] || cp "$lib" "$DEPS/lib/"
done
rm -rf "$BUILD"

echo "Done. Libraries in $DEPS/lib:"
ls "$DEPS/lib"
