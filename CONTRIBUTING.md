# Contributing

Thank you for helping make hidden Mac storage easier to understand.

## Before changing code

Read these binding constraints completely:

1. `DOCS/PRODUCT_CONSTITUTION.md`
2. `DOCS/DEVELOPMENT_DOCTRINE.md`
3. `DOCS/ARCHITECTURE.md`

The app is not a cleaner. Contributions must preserve its local, deterministic, read-only
architecture and its honest handling of unknown storage.

## Good contributions

- improve an explanation without overstating certainty;
- add an evidence-backed storage rule and focused tests;
- improve accessibility or native macOS behaviour;
- report an unidentified storage pattern without posting private filenames; or
- strengthen safety checks and documentation.

Do not submit deletion, cleanup, shell-command, telemetry, analytics, account, AI, remote-rule,
or privileged-helper features.

## Verify a change

```sh
./Scripts/check_architecture.sh
swift test
swift build
```

Include tests for classification or safety behaviour. Do not include real usernames, private
paths, document names, secrets, certificates, or signing credentials in fixtures or reports.

Opening an issue or pull request does not guarantee that a change will be accepted. Small,
focused changes that remove user confusion are preferred.
