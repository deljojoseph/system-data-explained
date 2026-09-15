# ARCHITECTURE

## System Data Explained V1

**Status:** Binding implementation boundary  
**Constraints:** `PRODUCT_CONSTITUTION.md` and `DEVELOPMENT_DOCTRINE.md`

---

## 1. Architecture Goal

Build a native macOS utility that observes filesystem metadata, deterministically classifies high-impact hidden storage, and explains the results without modifying user data or requiring a network service.

---

## 2. Dependency Direction

```text
Presentation
      ↓
Application
      ↓
Domain
      ↑
Infrastructure
```

- **Domain** contains pure value types and no UI or filesystem imports.
- **Application** owns use cases and read-only protocol contracts.
- **Infrastructure** implements those contracts with local macOS APIs.
- **Rules/Engine** provide deterministic evidence matching and aggregation.
- **Presentation** renders application state and never accesses the filesystem directly.

---

## 3. V1 Modules

```text
Sources/SystemDataExplained/
├── Domain/
├── Application/
├── Engine/
├── Rules/
├── Infrastructure/macOS/
└── Presentation/

Tests/SystemDataExplainedTests/
```

The first implementation is a Swift Package that Xcode can open and run as a native SwiftUI macOS executable. This keeps the dependency graph inspectable and the test workflow reproducible while App Store sandbox visibility is still being evaluated.

---

## 4. Read-Only Capability Boundary

Application code depends on a scan-only filesystem interface. It accepts explicit scan roots, emits throttled progress, and returns observations plus recoverable issues.

The interface exposes no write, delete, move, rename, chmod, ownership, snapshot, cleanup, or shell-execution operation.

Test-only code may manage isolated temporary fixtures. Production source may not.

---

## 5. Scan Scope

The recommended V1 scan observes high-value locations that commonly contribute to opaque storage:

- the current user's `Library`;
- system-wide `/Library` when readable;
- `/private/var` when readable;
- Homebrew locations when present; and
- user-visible virtual-machine and developer-tool locations covered by deterministic rules.

Roots are normalized and nested roots are removed before enumeration. The scanner stays on the root's volume and never follows symbolic links.

The report always identifies its roots and issues. It never claims to equal Apple's System Data total.

---

## 6. Data Flow

```text
Scan request
    ↓
Read-only metadata enumeration
    ↓
Filesystem observations
    ↓
Deterministic rule classification
    ↓
Category and item aggregation
    ↓
Explanation report
    ↓
SwiftUI dashboard and drill-down
```

Classification runs from normalized path and local metadata. Personal file contents are never read; the bounded machine-generated simulator metadata exception is defined in Doctrine section 21.

---

## 7. Accounting

Each observation retains logical and allocated byte counts where available.

Dashboard totals use allocated bytes when the filesystem reports them, because they better represent physical storage pressure. Logical totals remain available in technical details.

Filesystem free space must be named **Free space**, not **Available space**. Finder may include purgeable capacity in its Available value. The app does not infer purgeable capacity from filesystem-free bytes and explains this distinction where the value appears.

Unreadable locations, skipped volume boundaries, and transient metadata failures remain report issues. They are never counted as explained storage.

---

## 8. Classification

Rules are ordered by specificity and use stable identifiers. Each result contains category, owner where known, display name, explanation, confidence, status, and evidence.

Specific known rules precede application-owner and storage-family fallbacks. The final fallback is unclassified.

Unclassified observations are grouped by a meaningful directory anchor beneath each scan root. They are never aggregated under one global identifier. File-type detections retain the individual file location.

Installed application bundles may resolve container bundle identifiers to human-readable app names. Failure to resolve remains a generic owner-level result.

---

## 9. UI State Model

The application has four phases rendered by one persistent cockpit:

1. context — the approved real System Data example and **Explain My System Data** action;
2. working — only the measured GB found so far and a full-size Stop control in the same cockpit;
3. results — the largest findings and plain-language decisions in the same cockpit;
4. recoverable failure — a concise inline explanation and retry action.

The UI does not estimate a fake completion percentage when total work is unknown.

The window is a fixed native cockpit, not a document-length page. The app identity and controls
remain fixed. The complete results surface, beginning with the measured storage summary, scrolls
as one region. Opening a result expands it there without moving the app identity or controls out of view.
Opening and failure states may reflow within their content region for accessibility, but the
window chrome remains stable.

Primary UI language avoids internal classification vocabulary. Default copy follows the native
macOS 13-point body hierarchy, with restrained 14–17-point emphasis and a larger primary total.
The existing reading control scales meaningful content through 200 percent.

Results use nested inline expansion instead of navigation. A category row initially expands to its five largest observed items and offers one in-place control for the remainder. An item expands to one description, one specific best next step, one Finder action, and an optional evidence disclosure. The primary flow contains no navigation stack, detail page, or separate inspector.

The opening cockpit does not render candidate roots or a generalized list of apps and categories. Those are only known after observation.

The presentation layer never displays `scan`, `scanner`, `clean`, `cleanup`, or `optimize`. Internal application and domain identifiers may use technically precise terminology.

The visual hierarchy follows the user's Light or Dark appearance with adaptive neutral system surfaces and reserves blue for actions, focus, and key status cues. Repeated content surfaces and dividers are neutral. Native Liquid Glass is limited to functional controls and the cockpit's control layer on supported macOS versions, with a solid high-contrast fallback. Interactive rows and primary buttons provide at least 44-point hit regions.

---

## 10. Finder Reveal Boundary

Finder reveal is a read-only infrastructure capability. Presentation passes an observed path to an application-owned protocol; the macOS implementation asks Finder to show the existing item.

Finder reveal is preceded by a classification-owned best next step. When an owning application provides a safer management interface, that instruction is primary and the raw path remains supporting evidence.

The domain classification explicitly denies Finder reveal for **Keep** results. Presentation renders an explanation-only locked state for those items and must not offer a source-directory action.

The capability does not delete, move, rename, or edit anything. Missing paths fail visibly and safely. Redacted home-relative paths are expanded locally immediately before the Finder request.

---

## 11. Distribution Boundary

The development build is intentionally non-sandboxed so its read visibility can be measured honestly during local testing. It requests no administrator privileges and continues through normal permission failures.

An App Store sandbox target is a later controlled experiment. It must be compared against known filesystem truth before the App Store distribution decision is made.

The standard Help menu may open a concise native help window and hand a prefilled support
message to the user's default mail handler. The message contains only app version, macOS
version, Mac model identifier, and processor family. It never includes findings, filenames,
paths, permissions, or storage totals. Failure to open email falls back to copying the fixed
support address and does not launch a website or add an in-app network client.

---

## 12. Automated Safety Gates

The project must provide checks that fail when production source introduces:

- file deletion or movement APIs;
- shell execution;
- network client APIs;
- analytics or telemetry frameworks;
- StoreKit or payment logic in core layers; or
- UI imports in the domain layer.

The build, test suite, and safety checks must pass before a local test build is delivered.

## 13. Approved item guidance increment — 31 August 2026

Domain review units carry exact observed identity, purpose, consequences, recovery limits,
and conditional troubleshooting. The deterministic engine selects explicit reviewed
recipes; application orchestration groups independent units without double counting.
Infrastructure optionally reads the narrowly allowed device.plist metadata described in
Doctrine section 21, and revalidates identity before Finder reveal. The UI never reads
the filesystem. Findings and troubleshooting expand in the same cockpit.

Developer ID direct distribution is the initial release target, superseding the earlier
App Store experiment as the first-release route. Signing/notarization scripts live outside
Sources, keep credentials out of the bundle and repository, and must fail closed when a
valid identity, Apple acceptance, or a stapled ticket is missing.
