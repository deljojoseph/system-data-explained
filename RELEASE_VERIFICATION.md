# Verify a release

The public source and the distributed Mac app serve different trust checks:

- Source inspection shows what the app is designed and able to do.
- The SHA-256 checksum identifies the exact downloaded ZIP.
- Developer ID verifies the signer.
- Apple notarization and the stapled ticket let Gatekeeper validate the distributed app.

## Current release

- Version: `1.0 (7)`
- Source revision: the release commit containing this document
- ZIP: `System-Data-Explained-1.0-7.zip`
- SHA-256: `50c41f5f3526226c07c62ae5f7b764aec57aea8d71ee3c87e45c3f6b375ce5cd`
- Notarization submission: `9211c505-1e21-416b-b450-ac09e5650a85`
- Download: `https://deljojoseph.com/downloads/System-Data-Explained-1.0-7.zip`

The app sources, resources, bundle information, and local build script for version 1.0 (7) are
present at the source revision above. Apple signing and notarization add timestamps and tickets,
so a locally built ZIP is not expected to be byte-for-byte identical to the published ZIP.

## Check the downloaded ZIP

```sh
shasum -a 256 System-Data-Explained-1.0-7.zip
```

The output must match the published SHA-256 value exactly. If it does not, do not open the app.

After extracting the ZIP, verify its signature, Gatekeeper assessment, and stapled ticket:

```sh
codesign --verify --deep --strict --verbose=2 "System Data Explained.app"
codesign -dv --verbose=4 "System Data Explained.app"
spctl --assess --type execute --verbose=2 "System Data Explained.app"
xcrun stapler validate "System Data Explained.app"
```

Gatekeeper should report `accepted` with `source=Notarized Developer ID`. Inspect the
`Authority` lines printed by `codesign` and confirm they identify Deljo Joseph's Developer ID.

## Build the source locally

A local build does not need the maintainer's signing or notarization credentials:

```sh
./Scripts/check_architecture.sh
swift test
./Scripts/build_local_app.sh
```

The resulting `.build/app/System Data Explained.app` is an ad-hoc signed development build.
It is suitable for inspecting and testing the source locally, not for redistribution as the
official notarized release.
