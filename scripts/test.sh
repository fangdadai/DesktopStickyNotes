#!/bin/zsh
set -eu
cd "${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -module-cache-path "$build_dir/ModuleCache" DesktopStickyNotes/StickyNote.swift DesktopStickyNotes/NoteStorage.swift DesktopStickyNotes/NoteStore.swift Tests/CoreTests.swift -o "$build_dir/CoreTests"
"$build_dir/CoreTests"
