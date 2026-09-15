# Security policy

System Data Explained reads filesystem metadata across storage locations that can contain
private information. Security and privacy reports are welcome.

## Supported version

Only the latest release is supported with security fixes.

## Report privately

Do not open a public issue for a vulnerability, exposed credential, private path, or other
sensitive finding. Email `dj@deljojoseph.com` with:

- the affected version or commit;
- what you observed;
- steps that reproduce it without including private files; and
- the impact you believe it could have.

You may omit personal details that are not needed to understand the report. Please allow time
to investigate before publishing a vulnerability. No payment or response deadline is promised.

## Product security boundaries

Production code must remain local, deterministic, and read-only. It must not contain file
deletion or mutation, shell execution, network clients, telemetry, analytics, accounts,
privileged helpers, or remote classification. `Scripts/` contains local build and architecture
checks and is not bundled as executable app functionality.

Run `./Scripts/check_architecture.sh` to check these boundaries mechanically.
