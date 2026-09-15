#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
mkdir -p "$project_directory/.build"
staging_directory=$(mktemp -d "$project_directory/.build/app-stage.XXXXXX")
bundle_directory="$staging_directory/System Data Explained.app"
contents_directory="$bundle_directory/Contents"
executable_directory="$contents_directory/MacOS"
resources_directory="$contents_directory/Resources"
icon_source="$project_directory/Assets/system-data-explained.icon"
icon_info_plist="$project_directory/.build/app-icon-info.plist"

if [ ! -f "$icon_source/icon.json" ]; then
    echo "Missing Icon Composer source: $icon_source" >&2
    echo "Save the editable .icon file here; a PNG export does not contain its Liquid Glass layers." >&2
    exit 1
fi

cd "$project_directory"
if [ "${SDE_UNIVERSAL:-0}" = "1" ]; then
    swift build -c release --arch arm64 --arch x86_64
    binary_directory=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)
else
    swift build -c release
    binary_directory=$(swift build -c release --show-bin-path)
fi

mkdir -p "$executable_directory" "$resources_directory"
cp -f "$binary_directory/SystemDataExplained" "$executable_directory/SystemDataExplained"
cp -f "$project_directory/BuildSupport/Info.plist" "$contents_directory/Info.plist"

# Use Apple's compiler for native appearances, sizing, and older-macOS fallbacks.
# Keep the PNG export as artwork; do not flatten the layered runtime icon.
deployment_target=$(plutil -extract LSMinimumSystemVersion raw "$contents_directory/Info.plist")
xcrun actool "$icon_source" \
    --compile "$resources_directory" \
    --platform macosx \
    --minimum-deployment-target "$deployment_target" \
    --app-icon system-data-explained \
    --output-partial-info-plist "$icon_info_plist" \
    --output-format human-readable-text \
    --warnings --notices
/usr/libexec/PlistBuddy -c "Merge \"$icon_info_plist\"" "$contents_directory/Info.plist"

resource_bundle="$binary_directory/SystemDataExplained_SystemDataExplained.bundle"
if [ -d "$resource_bundle" ]; then
    resource_destination="$resources_directory/SystemDataExplained_SystemDataExplained.bundle"
    cp -R "$resource_bundle" "$resource_destination"
    if [ ! -f "$resource_destination/Contents/Info.plist" ]; then
        cp -f "$project_directory/BuildSupport/ResourceBundleInfo.plist" "$resource_destination/Info.plist"
    fi
    xattr -cr "$resource_destination"
    codesign --force --sign - \
        "$resource_destination"
fi
chmod 755 "$executable_directory/SystemDataExplained"
codesign --force --sign - "$bundle_directory"
codesign --verify --deep --strict "$bundle_directory"

mkdir -p "$project_directory/.build/app"
if [ -d "$project_directory/.build/app/System Data Explained.app" ]; then
    mv "$project_directory/.build/app/System Data Explained.app" "$staging_directory/Previous Build.app.previous"
fi
mv "$bundle_directory" "$project_directory/.build/app/System Data Explained.app"
bundle_directory="$project_directory/.build/app/System Data Explained.app"

echo "$bundle_directory"
