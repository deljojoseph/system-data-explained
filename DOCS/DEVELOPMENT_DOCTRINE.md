# DEVELOPMENT DOCTRINE

## System Data Explained

**Status:** Binding engineering policy  
**Version:** 1.0  
**Companion constraint:** `PRODUCT_CONSTITUTION.md`  

---

## 1. Authority

This doctrine governs how System Data Explained is designed, implemented, tested, and reviewed.

`PRODUCT_CONSTITUTION.md` defines what the product is allowed to become. This doctrine defines how engineering work must preserve that promise. Both documents are architectural constraints, not optional guidance.

When requirements conflict, use this order:

1. user safety and data integrity;
2. the Product Constitution;
3. this Development Doctrine;
4. documented architecture boundaries;
5. feature requirements;
6. implementation convenience.

No implementation is complete merely because it compiles. It must also be truthful, deterministic, local, read-only, understandable, and tested in proportion to risk.

---

## 2. Governing Engineering Thesis

> **Measure everything we can, infer only what evidence supports, explain it simply, and admit what remains unknown.**

The required processing order is:

```text
OBSERVE
↓
MEASURE
↓
IDENTIFY
↓
CLASSIFY
↓
EXPLAIN
```

Any design that reverses this order or begins with a desired answer is invalid.

---

## 3. Doctrine One — Omission Is a Feature

Every proposed capability must identify the user confusion it removes.

Before implementation, ask:

1. What important outcome breaks if this is omitted?
2. Is it required to explain hidden storage?
3. Can the same outcome be achieved with less permission, complexity, or risk?
4. Does it add a concept the user must learn?

If no important outcome breaks, omit the capability.

The team shall prefer a smaller product with a reliable explanation over a broader product with ambiguous behavior.

---

## 4. Doctrine Two — Explanation Before Action

Version 1 is strictly read-only.

Production code shall not expose operations that:

- delete files or directories;
- move or rename user files;
- truncate or overwrite data;
- change permissions or ownership;
- clear caches;
- detach or delete snapshots;
- uninstall applications;
- run cleanup shell commands; or
- mutate filesystem content for any reason.

The absence of mutation must be enforced at the interface boundary. A disabled button is not a safety architecture.

The product must still return control to the user. Results that support inspection must include evidence-backed decision guidance and a read-only Finder reveal action. Items marked **Keep** must never link to their source directory. Forcing a user to decode a path manually is a product failure when inspection is the supported next step.

Finder reveal is never the complete answer. Each classification must provide a concise best next step. Prefer the owning application's storage controls when raw folders use UUIDs, hashes, version internals, or other names a person cannot safely interpret.

Filesystem abstractions may observe and measure only. Protocols must not contain deletion, writing, moving, or cleanup methods.

Tests may create and remove their own isolated temporary fixtures. Test-only fixture cleanup must never be reachable from production targets.

---

## 5. Doctrine Three — Facts Before Interpretation

Every classification must retain evidence that explains why it was produced.

Supported evidence includes:

- normalized paths and path prefixes;
- file and directory metadata;
- bundle identifiers and installed-app metadata;
- file or package types;
- volume identity;
- known application storage conventions; and
- system roles available through stable local APIs.

A display label is not evidence. A large size is not evidence of junk, danger, or disposability.

The product must never infer that data is safe to remove merely because it appears to be a cache, temporary item, simulator, archive, backup, or generated file.

---

## 6. Doctrine Four — Unknown Is Acceptable

When evidence is insufficient, return an unknown or generic result.

The classification hierarchy is:

1. known purpose and owner;
2. known owner or generic storage family;
3. unclassified.

Confidence must reflect evidence quality, not presentation goals.

Classification coverage may never be increased by:

- assigning a likely owner without evidence;
- treating path-name resemblance as certainty;
- collapsing unreadable storage into a known category;
- hiding unclassified results; or
- reclassifying accounting differences as scanned files.

False confidence is a release-blocking defect when it could mislead a user about important storage.

Unknown results must be grouped by the smallest stable, useful location supported by evidence. A global `unknown` accumulator that merges unrelated roots or top-level directories is forbidden.

The opening interface must not predict the categories or tools present on a Mac. Candidate observation roots are an internal implementation detail, not a user-facing inventory.

---

## 7. Doctrine Five — Determinism Over AI

Core scanning, attribution, classification, aggregation, and explanation must be deterministic and local.

The same input evidence and rule set must yield the same result.

Version 1 shall include:

- no LLM dependency;
- no AI API;
- no remote classifier;
- no network fallback;
- no downloaded rule execution; and
- no behavior that changes because a service is unavailable.

Rules must be data-driven, inspectable, stable, and individually testable. The classifier must be generic; storage knowledge belongs in rule data or focused resolvers.

---

## 8. Doctrine Six — Progressive Disclosure

The presentation hierarchy must be:

1. major human-readable causes;
2. the supported user decision: keep, check first, recreatable, or not understood;
3. meaningful components within a cause;
4. a read-only Show in Finder action;
5. technical paths and evidence.

The first screen must not require knowledge of paths, bundle identifiers, APFS, sparse bundles, inodes, virtual memory, or purgeable storage.

Technical accuracy does not require leading with technical language. Plain language must remain faithful to the evidence.

Progressive disclosure must be spatial, not navigational. Category and result details expand in the same cockpit. `NavigationStack`, `NavigationLink`, separate detail pages, and auxiliary result windows are forbidden in the primary explanation flow.

User-facing copy must describe the outcome rather than the enumeration mechanism. The primary interface must not use `scan`, `scanner`, `clean`, `cleanup`, or `optimize`. Internal type and protocol names may retain technically precise terms when they are not shown to users.

The opening state must not enumerate candidate folders or categories. It may show the approved founder System Data example with a short invitation to explain the user's own number.

An expanded result must be concise: one plain description, one specific best next step, one Finder action, and one optional evidence disclosure.

An expanded category shows its five largest findings first. A single in-place control may reveal the rest. The user must never face an unbounded folder list by default.

Primary product copy must pass a tenth-grade reading test. Internal terms such as "coverage," "owner/family," and "logical size" must be rewritten or moved into optional technical details.

User-facing descriptions must not use em dashes. Use short sentences, commas, or plain conjunctions instead.

Essential information must not use caption-sized type. At default macOS display settings, use the native macOS hierarchy: approximately 13-point regular body text, 14–15-point result names, and 15–17-point important values. Large titles are reserved for the primary storage total or an empty-state message. The in-app accessibility control must enlarge meaningful content through 200 percent without clipping or hiding actions.

Primary buttons and expandable rows must have a hit region at least 44 points high. Color is never the only carrier of meaning.

The visual system uses adaptive neutral system surfaces with blue reserved for actions, focus, and a small number of key status cues. It follows the user's macOS Light or Dark appearance without adding an app-specific appearance setting. Explanatory cards, dividers, icons, and repeated details remain neutral so blue does not become visual noise. Adopt native macOS Liquid Glass through system controls and, where supported, a small number of interactive functional controls. Do not apply glass as a repeated content-card decoration. Provide a solid, high-contrast fallback when transparency is unavailable or reduced.

---

## 9. Doctrine Seven — Never Sacrifice Truth for a Prettier Number

The scanner must distinguish where possible between:

- logical file size;
- allocated file size;
- scanned and readable bytes;
- inaccessible locations;
- volume-level used and filesystem-free capacity, plus reclaimable or available capacity only when separately supported; and
- storage not represented by ordinary file enumeration.

Totals may differ because of APFS clones, snapshots, shared blocks, sparse files, purgeable storage, filesystem metadata, inaccessible locations, and other volumes.

The product must not silently force these numbers to match.

Every report must state what was scanned. Partial scans must be labeled as partial. Permission failures must be counted and summarized without implying that the missing data was classified.

---

## 10. Doctrine Eight — Safety Belongs in Architecture

Safety is a property of dependencies and capabilities.

The domain layer must not import SwiftUI, AppKit, StoreKit, or filesystem APIs.

The application layer must depend on observation protocols, not concrete macOS readers.

Infrastructure implementations must point inward and expose read-only values.

Presentation must not access `FileManager` or other filesystem APIs directly.

No production target may contain file-deletion APIs, mutation shell commands, or privileged helpers.

The initial test build must not request administrator privileges. It must continue safely when macOS denies access.

---

## 11. Scanning Rules

The scanner must:

- enumerate in the background;
- support cooperative cancellation;
- throttle progress delivery;
- never follow symbolic links;
- avoid unintentionally crossing filesystem volumes;
- handle unreadable directories without aborting the full scan;
- tolerate files disappearing or changing during enumeration;
- avoid reading file contents except the bounded machine-generated metadata allowed in section 21;
- avoid hashing file contents;
- avoid opening user documents;
- collect only metadata required for measurement or classification; and
- keep filenames and paths on the Mac.

The scanner should favor allocated size for explaining physical pressure while retaining logical size so differences remain visible.

A scan request must explicitly define its roots. Duplicate or nested roots must be normalized so bytes are not counted twice.

---

## 12. Rule-Engine Rules

Each deterministic rule must define:

- a stable identifier;
- evidence matcher;
- category;
- human-readable display name;
- owner when supported;
- explanation;
- a specific plain-language best next step;
- confidence;
- risk or review status; and
- supported user decision guidance; and
- evidence requirements.

Specific rules must win over generic fallbacks.

Rules must not depend on directory enumeration order.

Every high-impact or high-risk rule must have fixtures for:

- a positive match;
- a nearby non-match;
- confidence;
- category;
- explanation metadata; and
- precedence over generic rules.

Unknown paths must remain classifiable as unknown without crashing or disappearing.

File-type rules must preserve the individual file location so the user can reveal the file. Directory-family rules must preserve the narrowest stable directory anchor. Aggregation must never destroy the location required for a Finder action.

---

## 13. Application Attribution Rules

Bundle identifiers may be resolved from installed application metadata using local, read-only APIs.

An application name may be shown only when:

- the bundle identifier matches installed metadata; or
- a curated rule establishes the owner with high confidence.

Unresolved bundle identifiers must not be exposed as primary user-facing labels. They may appear in technical evidence.

Application attribution does not imply that data is disposable.

---

## 14. Concurrency and Responsiveness

Scanning must never block the main actor.

Long operations must:

- be asynchronous;
- respond to cancellation promptly;
- avoid unbounded task creation;
- limit UI updates to a reasonable cadence; and
- keep memory proportional to summarized results rather than the number of filesystem entries whenever practical.

The UI must remain usable while checking and show honest, non-fabricated progress. When the total work is unknowable, display activity and measured size rather than a false percentage. File and folder counters do not belong in this phase.

---

## 15. Error and Permission Doctrine

No single unreadable directory may kill a scan.

Errors must be divided into:

- cancellation;
- unavailable root;
- permission denied;
- transient file change;
- volume boundary skip; and
- unexpected reader failure.

Recoverable errors should be recorded in the report and scanning should continue.

The UI must explain incomplete visibility calmly. It must not pressure the user to grant broad access or suggest that permissions guarantee complete reproduction of macOS storage totals.

---

## 16. Privacy Doctrine

Version 1 performs all work locally.

Production code shall contain:

- no analytics SDK;
- no telemetry client;
- no crash-upload client;
- no account system;
- no advertising SDK;
- no remote configuration;
- no network requests; and
- no file or metadata upload.

Logs must not include full personal paths or filenames by default. Debug diagnostics should use redacted paths where practical.

Any future export flow requires explicit user initiation and a separate privacy review.

---

## 17. Dependency Doctrine

Version 1 uses Swift, SwiftUI, Foundation, AppKit only where required, and XCTest or Swift Testing.

Third-party dependencies are forbidden unless a written decision record proves they are necessary, privacy-compatible, maintained, and smaller in risk than an internal implementation.

The dependency direction is binding:

```text
Presentation → Application → Domain
                    ↑
              Infrastructure
```

Domain remains pure Swift. Infrastructure satisfies application-owned protocols.

---

## 18. Testing Doctrine

Tests must prove product claims, not only code paths.

Required coverage includes:

- deterministic classification;
- rule precedence;
- unknown fallback behavior;
- aggregation and explanation coverage arithmetic;
- allocated versus logical size handling;
- symlink non-traversal;
- volume-boundary behavior where testable;
- cancellation;
- permission-error resilience through test doubles;
- nested-root deduplication;
- absence of filesystem mutation capabilities; and
- domain independence from UI and platform frameworks.

Real-machine tests must be observational. They must not clean up, repair, or modify the scanned locations.

Large-scale tests should use generated temporary fixtures or read-only benchmark paths. Temporary fixtures must remain isolated from user data.

---

## 19. Review Gates

A change may merge only if:

1. it passes the Product Constitution's change-admission test;
2. no new mutation capability is introduced;
3. evidence and confidence behavior are tested;
4. user-facing wording does not overstate certainty;
5. privacy remains local-only;
6. scanning remains cancellable and responsive;
7. errors cannot erase or fabricate measured results;
8. domain boundaries remain intact; and
9. the full test suite passes.

The automated architecture check must also reject primary presentation copy containing commodity cleaner language and reject page-stack navigation in the primary explanation flow.

Before every release, search the production source for prohibited capabilities, including file removal, file movement, shell execution, network APIs, analytics, and telemetry.

---

## 20. Definition of Engineering Done

An increment is done when:

- it provides a user-visible explanation backed by evidence;
- it handles unknown and denied-access cases honestly;
- it is read-only by construction;
- it remains local and deterministic;
- it is accessible through progressive disclosure;
- its important behavior is tested;
- it introduces no unexplained dependency; and
- it passes the final inversion check.

The final test is:

> **If we wanted to turn this into another confusing, untrustworthy Mac cleaner, would we build it this way?**

If the answer is yes, stop and redesign it.

## 21. Approved guidance and accessibility amendment — 31 August 2026

Each independently measured review item must explain loss, recovery requirements, and one next step before Finder
access. Category risk must never be a majority vote. Unreviewed storage receives inspection
guidance, not an inherited removal promise. An unlisted simulator is not an unused simulator.

The file-content prohibition has one narrow exception: infrastructure may read at most
64 KiB of machine-generated `device.plist` from an individually observed UUID directory
directly inside the current user's CoreSimulator/Devices or XCTestDevices directory.
Only name, device identifier, runtime identifier, and device-type identifier may be used.
Check the observed directory identity, reject symbolic links in every path component,
reject non-regular, oversized, malformed, or mismatched metadata, and cancel between items.
Never inspect simulator apps, documents, databases, or accounts. No private APIs or shell
commands belong in the app. Missing metadata does not prevent size reporting or inspection.

Default labels and body copy use regular-weight system text at the macOS standard 13 pt.
Result names use 14–15 pt and modest medium weight where hierarchy requires it; thin weights
are not a substitute for legibility. Provide
text enlargement, 44 pt minimum actions, keyboard access, VoiceOver labels, reduced motion,
and reduced-transparency/high-contrast behavior. Checking shows bytes and one quiet access
note, not file/folder counters. Issue totals are separate from capped diagnostic samples.

Manual simulator removal instructions remain gated on a validated disposable-device
procedure. If validation is missing, disclose that limitation with exact inspection and
backup guidance; do not promise that quitting Xcode stops simulator services.
