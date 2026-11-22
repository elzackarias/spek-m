#!/usr/bin/env bash

set -euo pipefail

LANGUAGES="bs ca cs da de el eo es fi fr gl he hr hu id it ja ko lv nb nl nn pl pt_BR ru sk sr@latin sv th tr uk vi zh_CN zh_TW"

cd $(dirname $0)/../..

# Oldest macOS version the app must run on. Libraries whose Homebrew bottles
# need something newer are rebuilt by build-deps.sh into dist/osx/deps.
MACOS_TARGET=${MACOS_TARGET:-27.0}
export MACOSX_DEPLOYMENT_TARGET=$MACOS_TARGET
DEPS_LIB=$(pwd)/dist/osx/deps/lib

# Homebrew lives in /opt/homebrew on Apple Silicon and /usr/local on Intel.
BREW_PREFIX=$(brew --prefix)
WX_ACLOCAL=$(dirname $(find "$BREW_PREFIX"/Cellar/wxwidgets -name wxwin.m4 | head -n1))
export ACLOCAL_PATH="$WX_ACLOCAL:$BREW_PREFIX/share/aclocal${ACLOCAL_PATH:+:$ACLOCAL_PATH}"
# /opt/homebrew is not in the default compiler search paths (needed for libintl).
export CPPFLAGS="-I$BREW_PREFIX/include ${CPPFLAGS:-}"
export LDFLAGS="-L$BREW_PREFIX/lib ${LDFLAGS:-}"

rm -f src/spek

./autogen.sh && make clean && make -j8 || exit 1

cd dist/osx
rm -fr Spek.app
mkdir -p Spek.app/Contents/MacOS
mkdir -p Spek.app/Contents/Frameworks
mkdir -p Spek.app/Contents/Resources
mv ../../src/spek Spek.app/Contents/MacOS/Spek
cp Info.plist Spek.app/Contents/
cp Spek.icns Spek.app/Contents/Resources/
cp *.png Spek.app/Contents/Resources/
cp ../../CREDITS.md Spek.app/Contents/Resources/
cp ../../LICENSE Spek.app/Contents/Resources/
cp ../../README.md Spek.app/Contents/Resources/
mkdir Spek.app/Contents/Resources/lic
cp ../../lic/* Spek.app/Contents/Resources/lic/

for lang in $LANGUAGES; do
    mkdir -p Spek.app/Contents/Resources/"$lang".lproj
    cp -v ../../po/"$lang".gmo Spek.app/Contents/Resources/"$lang".lproj/spek.mo
    cp -v "$BREW_PREFIX"/share/locale/"$lang"/LC_MESSAGES/wxstd-*.mo Spek.app/Contents/Resources/"$lang".lproj/ || echo "No WX translation for $lang"
done
mkdir -p Spek.app/Contents/Resources/en.lproj

BINS="Spek.app/Contents/MacOS/Spek"
while [ ! -z "$BINS" ]; do
    NEWBINS=""
    for bin in $BINS; do
        echo "Updating dependendies for $bin."
        LIBS=$(otool -L $bin | tail -n +2 | { grep -E "$BREW_PREFIX|@rpath/|@loader_path/" || test $? = 1; } | tr -d '\t' | awk '{print $1}')
        for lib in $LIBS; do
            case $lib in
                @rpath/*|@loader_path/*) reallib=$(realpath "$BREW_PREFIX/lib/$(basename $lib)") ;;
                *) reallib=$(realpath $lib) ;;
            esac
            libname=$(basename $reallib)
            # Prefer a copy rebuilt for MACOS_TARGET by build-deps.sh.
            if [ -f "$DEPS_LIB/$libname" ]; then
                reallib="$DEPS_LIB/$libname"
            fi
            install_name_tool -change $lib @executable_path/../Frameworks/$libname $bin
            if [ ! -f Spek.app/Contents/Frameworks/$libname ]; then
                echo "\tBundling $reallib."
                cp $reallib Spek.app/Contents/Frameworks/
                chmod +w Spek.app/Contents/Frameworks/$libname
                install_name_tool -id @executable_path/../Frameworks/$libname Spek.app/Contents/Frameworks/$libname
                NEWBINS="$NEWBINS Spek.app/Contents/Frameworks/$libname"
            fi
        done
    done
    BINS="$NEWBINS"
done

# Fail if anything needs a newer macOS than MACOS_TARGET.
TOO_NEW=""
for f in Spek.app/Contents/MacOS/Spek Spek.app/Contents/Frameworks/*; do
    minos=$(otool -l "$f" | awk '/LC_BUILD_VERSION/{f=1} f&&/minos/{print $2; f=0}')
    if [ "$(printf '%s\n%s\n' "$MACOS_TARGET" "$minos" | sort -V | tail -n1)" != "$MACOS_TARGET" ]; then
        TOO_NEW="$TOO_NEW\n  $(basename "$f") (macOS $minos)"
    fi
done
if [ -n "$TOO_NEW" ]; then
    echo -e "These need a newer macOS than $MACOS_TARGET:$TOO_NEW"
    echo "Add them to build-deps.sh and run it, then bundle again."
    exit 1
fi
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $MACOS_TARGET" Spek.app/Contents/Info.plist

# install_name_tool invalidates code signatures, and arm64 binaries must be
# signed to run, so re-sign everything (ad-hoc unless SIGN_IDENTITY is set).
codesign --force --sign "${SIGN_IDENTITY:--}" Spek.app/Contents/Frameworks/*.dylib
codesign --force --sign "${SIGN_IDENTITY:--}" Spek.app

# Make DMG image
VOLUME_NAME=Spek
DMG_APP=Spek.app
DMG_FILE=$VOLUME_NAME.dmg
MOUNT_POINT=$VOLUME_NAME.mounted

rm -f $DMG_FILE
rm -f $DMG_FILE.master

# Compute an approximated image size in MB, and bloat by 1MB
image_size=$(du -ck $DMG_APP | tail -n1 | cut -f1)
image_size=$((($image_size + 5000) / 1000))

echo "Creating disk image (${image_size}MB)..."
hdiutil create $DMG_FILE -megabytes $image_size -volname $VOLUME_NAME -fs HFS+ -quiet || exit $?

echo "Attaching to disk image..."
hdiutil attach $DMG_FILE -readwrite -noautoopen -mountpoint $MOUNT_POINT -quiet

echo "Populating image..."
cp -Rp $DMG_APP $MOUNT_POINT
cd $MOUNT_POINT
ln -s /Applications " "
cd ..
cp DS_Store $MOUNT_POINT/.DS_Store

echo "Detaching from disk image..."
hdiutil detach $MOUNT_POINT -quiet
mv $DMG_FILE $DMG_FILE.master

echo "Creating distributable image..."
hdiutil convert -quiet -format UDBZ -o $DMG_FILE $DMG_FILE.master
rm $DMG_FILE.master

echo "Done."

cd ../..
