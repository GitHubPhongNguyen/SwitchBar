#!/bin/bash
# Builds SwitchBar.app into ./build. Pass "install" to copy it to ~/Applications and launch it,
# or "dist" to zip it into ./build for sharing with others.
set -euo pipefail
cd "$(dirname "$0")"

APP=build/SwitchBar.app
rm -rf build
mkdir -p "$APP/Contents/MacOS"

# Universal binary so the app runs on both Apple Silicon and Intel Macs.
for arch in arm64 x86_64; do
    swiftc -O -swift-version 5 -target $arch-apple-macos14.0 \
        -framework AppKit -framework Carbon -framework ServiceManagement \
        -framework SwiftUI -framework SystemConfiguration \
        Sources/*.swift -o build/SwitchBar-$arch
done
lipo -create build/SwitchBar-arm64 build/SwitchBar-x86_64 -output "$APP/Contents/MacOS/SwitchBar"
rm build/SwitchBar-arm64 build/SwitchBar-x86_64
cp Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "install" ]]; then
    pkill -x SwitchBar || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/SwitchBar.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/SwitchBar.app
    echo "Installed to ~/Applications/SwitchBar.app"
fi

if [[ "${1:-}" == "dist" ]]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
    ZIP=build/SwitchBar-$VERSION.zip
    # ditto keeps the code signature intact; plain zip can break it.
    ditto -c -k --keepParent "$APP" "$ZIP"
    echo "Packaged $ZIP"
fi
