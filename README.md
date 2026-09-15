# System Data Explained

A native, local-only macOS utility that explains storage commonly hidden behind the System Data label.

The source is public so people can inspect what the app reads, how findings are classified,
and which capabilities are deliberately absent. The signed download is built and notarized
by [Deljo Joseph](https://deljojoseph.com/). See [Verify a release](RELEASE_VERIFICATION.md) before running a downloaded copy.

## Safety model

- Read-only production filesystem interface
- No deletion, cleanup, repair, move, or rename capability
- No administrator privileges
- No network calls, uploads, analytics, accounts, or AI services
- Symbolic links are never followed
- Mounted-volume boundaries are not crossed unintentionally
- Unreadable locations are reported as incomplete visibility instead of failing the scan

The app does not claim to reproduce Apple's System Data number exactly.
It does not recognise every possible storage scenario. Unknown findings remain visible instead
of receiving a confident removal recommendation.

## Requirements

- macOS 14 or later
- Xcode 26 or later with the macOS SDK and Swift Package Manager (needed for the native Icon Composer icon)

## Run in Xcode

1. Open `Package.swift` in Xcode.
2. Select the **SystemDataExplained** scheme and **My Mac** destination.
3. Press Run.
4. Select **Explain My System Data**.

The first scan may take several minutes on a large Mac. It remains cancellable. macOS may deny access to protected locations; that is expected and the report will remain explicit about partial visibility. Do not grant Full Disk Access for the first safety test.

## Run from Terminal

```sh
swift run SystemDataExplained
```

## Build a local app bundle

```sh
./Scripts/build_local_app.sh
open ".build/app/System Data Explained.app"
```

The bundle is ad-hoc signed for local testing only. It is not an App Store or notarized distribution build.

The local app builder compiles `Assets/system-data-explained.icon` into the native macOS icon, including appearances and older-system fallbacks. For future icon changes, edit that file in Icon Composer and rebuild. The PNG export is only a preview. See [icon instructions](Assets/README.md).

## Verify before running

```sh
./Scripts/check_architecture.sh
swift test
swift build
```

## Default scan scope

The development build observes metadata in existing high-value areas such as the user's Library, `/Library`, `/private/var`, Homebrew, developer caches, and common virtual-machine locations. It reads metadata and sizes; it does not read document contents.

## Governing documents

- `DOCS/PRODUCT_CONSTITUTION.md`
- `DOCS/DEVELOPMENT_DOCTRINE.md`
- `DOCS/ARCHITECTURE.md`

The Product Constitution and Development Doctrine are binding architectural constraints.

## Contributing and security

- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Release verification](RELEASE_VERIFICATION.md)
- [MIT License](LICENSE)

## Item guidance

Large simulator devices, project build folders, backups, and supported virtual machines
are measured as independent review items. Each explanation places loss, recovery limits,
and a next step before its exact Finder link. Missing metadata never means unused data.
The app reads only size/identity metadata, plus a narrowly bounded simulator `device.plist`
for human-readable device names. It never opens personal documents or simulator databases.

Labels use regular-weight system text. The Text size menu enlarges text up to 200%.
Checking shows size progress and a quiet folder-access note. Diagnostics distinguish
permission denial from other failures and keep totals independent of the 250-sample cap.
