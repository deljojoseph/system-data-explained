# Verify a release

The public source and the distributed Mac app serve different trust checks:

- Source inspection shows what the app is designed and able to do.
- The SHA-256 checksum identifies the exact downloaded ZIP.
- Developer ID verifies the signer.
- Apple notarization and the stapled ticket let Gatekeeper validate the distributed app.

## Current release

- Version: `1.0 (6)`
- Source revision: tag `v1.0.6`
- ZIP: `System-Data-Explained-1.0-6.zip`
- SHA-256: `2b9cb8bcdb962c402691b97300b82e87812490b587612c5e3f292465b1a2b27e`
- Notarization submission: `84eb63ec-7a27-4ae1-a76e-c97e5fd0e09f`
- Download: `https://deljojoseph.com/downloads/System-Data-Explained-1.0-6.zip`

The app sources, resources, bundle information, and local build script for version 1.0 (6) are
present at the source revision above. Apple signing and notarization add timestamps and tickets,
so a locally built ZIP is not expected to be byte-for-byte identical to the published ZIP.

## Check the downloaded ZIP

```sh
shasum -a 256 System-Data-Explained-1.0-6.zip
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
