#!/bin/zsh
set -eu
if (( $# > 1 )) || [[ -n "${1:-}" && "$1" != --install ]]; then
    print -u2 'Usage: ./scripts/package.sh [--install]'
    exit 1
fi
cd "${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

mkdir -p build dist
# Compile outside Documents to avoid file-provider metadata breaking code signing.
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
print 'Building DesktopStickyNotes (Release, Apple silicon + Intel)…'
if ! xcodebuild -project DesktopStickyNotes.xcodeproj \
    -scheme DesktopStickyNotes -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$build_dir" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
    'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO build > build/package.log 2>&1; then
    tail -n 60 build/package.log
    exit 1
fi

source_app="$build_dir/Build/Products/Release/DesktopStickyNotes.app"
codesign --verify --deep --strict "$source_app"
rm -rf dist/DesktopStickyNotes.app
ditto --norsrc --noextattr "$source_app" dist/DesktopStickyNotes.app
# Archive the verified source before a file provider can attach Finder metadata.
ditto -c -k --sequesterRsrc --keepParent "$source_app" dist/DesktopStickyNotes.zip
print "App: $PWD/dist/DesktopStickyNotes.app"
print "Zip: $PWD/dist/DesktopStickyNotes.zip"
if [[ "${1:-}" == --install ]]; then
    install_app="$HOME/Applications/DesktopStickyNotes.app"
    mkdir -p "$HOME/Applications"
    rm -rf "$install_app"
    ditto --norsrc --noextattr "$source_app" "$install_app"
    codesign --verify --deep --strict "$install_app"
    print "Installed: $install_app"
else
    print 'Double-click the app in Finder, or run again with --install to install in ~/Applications.'
fi
