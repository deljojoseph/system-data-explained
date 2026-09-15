# PRODUCT CONSTITUTION

## System Data Explained

**Status:** Foundational product policy  
**Version:** 1.0  
**Platform:** macOS  

---

## 1. Purpose of This Constitution

This constitution defines the product promises, boundaries, and decision rules that govern System Data Explained.

It exists to prevent feature pressure, technical convenience, visual polish, growth tactics, or commercial incentives from weakening the product's clarity, truthfulness, privacy, or safety.

When a proposed feature or implementation conflicts with this constitution, this constitution wins.

The governing product thesis is:

> **macOS gives you a number. We give you the explanation.**

---

## 2. The Product's Job

System Data Explained exists to answer one question:

> **Why is my Mac full?**

It SHALL identify and explain the storage commonly hidden behind macOS System Data and other opaque storage categories.

It SHALL help an ordinary Mac owner understand:

- what is consuming storage;
- which application or system component created it;
- why it exists;
- whether it appears normal, temporary, or recreatable;
- how confidently the product understands it; and
- whether the user should care.

The product SHALL NOT claim to reproduce Apple's System Data calculation exactly. Apple does not provide a public file-by-file membership API for that category.

The approved positioning is:

> **Understand what's actually using your Mac storage.**

The technically precise promise is:

> **We identify and explain the storage commonly hidden behind macOS System Data and other opaque storage.**

---

## 3. The User We Serve

The primary user is a Mac owner who sees a large, unexplained storage number and wants an answer without becoming a filesystem expert.

The first-level experience SHALL be understandable to someone who does not know what `Library`, APFS, a bundle identifier, a sparse bundle, an inode, or a filesystem path is.

The product SHALL be especially useful to:

- owners of 256 GB and 512 GB Macs;
- creative professionals with large working files and media caches;
- developers using Xcode, simulators, Docker, Homebrew, Android tools, or virtual machines;
- office users with large application databases and caches;
- users with local iPhone or iPad backups; and
- users whose cloud-storage tools retain local data.

No segment may distort the product into a specialist-only utility. Developer storage is an important use case, not the entire market thesis.

---

## 4. Product Category and Boundaries

System Data Explained defines a focused category:

> **System Data Explanation**

Filesystem scanning is infrastructure. Filesystem interpretation is the product.

The product is not:

- a Mac cleaner;
- a disk visualizer;
- an optimization suite;
- an AI filesystem assistant;
- a malware scanner;
- an uninstaller;
- a duplicate-file finder; or
- a system-health monitor.

It SHALL answer:

> What is this, why is it here, who created it, and should I care?

It SHALL NOT lead with:

> What can I remove?

---

## 5. Non-Negotiable Product Principles

### 5.1 Omission is a feature

Every proposed feature MUST answer:

> What important user outcome breaks if we do not build this?

If nothing important breaks, the feature SHALL be omitted.

### 5.2 Explanation before action

Version 1 explains storage. It does not clean, delete, modify, repair, or optimize anything.

Read-only behavior is a trust feature, not a temporary deficiency.

Read-only SHALL NOT mean passive or non-actionable. Every meaningful result MUST tell the user which of these decisions is supported by the evidence:

- **Keep** — normal storage the app or macOS currently relies on;
- **Check first** — potentially useful data whose value depends on the user's apps, projects, devices, or history;
- **Recreatable** — generated or downloaded data that its owner can create again; or
- **Not understood** — the product does not understand it well enough to guide removal.

Every meaningful result SHALL state one specific best next step before offering Finder. If the owner application provides the safer management path, the product SHALL name that path instead of sending the user into opaque identifiers or internal folders.

For **Check first**, **Recreatable**, and **Not understood** results, the product SHALL provide a direct, read-only way to reveal the exact item in Finder. Finder reveal is supporting evidence, not a substitute for guidance. The user—not the app—retains control of any deletion.

Items marked **Keep** SHALL NOT provide a Finder reveal action. A direct path into normal or required application and system storage would contradict the decision and create an avoidable opportunity for accidental deletion. Technical evidence may remain visible for transparency, but it is not an action.

### 5.3 Facts before interpretation

Every result MUST follow this sequence:

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

The product SHALL NOT guess and present the guess as a confident answer.

### 5.4 Unknown is an honest result

The product MUST prefer an explicit unknown or generic classification over an unsupported explanation.

False confidence is a product defect.

### 5.5 Determinism over AI

Classification SHALL be local, evidence-based, reproducible, and deterministic.

The same evidence MUST produce the same explanation. No LLM, AI API, or network service is required for core classification.

### 5.6 Progressive disclosure

The information hierarchy SHALL move from human meaning to technical evidence:

1. what is taking the space;
2. whether to keep it, check it first, or treat it as recreatable;
3. what makes up a category;
4. where the data exists and which evidence supports the explanation.

Raw paths, bundle identifiers, and filesystem terminology belong in technical details, not in the first-level experience.

Progressive disclosure MUST happen inside one persistent cockpit. Opening a result SHALL expand it in place. Routine understanding and Finder actions SHALL NOT require navigation to another page, window, or inspector.

The cockpit MUST preserve context: the total, the ranked causes, the selected cause, the decision, and the Finder action remain part of the same continuous view.

Expanded categories SHALL initially show no more than five findings. More findings require one explicit in-place expansion so large machines do not become a wall of folders.

Blue SHALL identify actions, focus, and a small number of key status cues. Explanatory content surfaces, dividers, and repeated detail rows SHALL remain neutral and high contrast.

### 5.7 Truth over numerical neatness

The product SHALL NOT manipulate, relabel, or hide values merely to make totals appear to match.

When logical size, allocated size, APFS accounting, snapshots, clones, shared blocks, purgeable storage, inaccessible data, or other volumes produce different totals, the product MUST explain the discrepancy to the extent supported by evidence.

### 5.8 Safety by construction

Safety SHALL be enforced by product architecture, not merely by interface controls.

Version 1 production filesystem capabilities SHALL expose no deletion or mutation operation.

---

## 6. Evidence and Explanation Standard

Classifications MAY be based on evidence such as:

- exact paths and path prefixes;
- bundle identifiers;
- installed application metadata;
- known application storage conventions;
- file and package types;
- directory structures;
- volume identity and filesystem metadata; and
- APFS roles when reliably observable.

Every explanation MUST be traceable to observed evidence.

Every classified result SHALL communicate an appropriate level of certainty. Results degrade gracefully through three levels:

### Level A — Known

The product can identify the storage's purpose and owner with strong evidence.

### Level B — Owner known

The product can identify the owning application or family but cannot safely determine the exact purpose or disposability of all data.

### Level C — Unknown

The product measured the storage but cannot confidently identify its purpose or owner.

Unknown storage SHALL remain visible and SHALL NOT be forced into a more attractive category.

Unknown storage MUST still be grouped into the smallest useful evidence-backed locations. Unrelated scan roots, applications, and top-level directories SHALL NOT be collapsed into one undifferentiated unknown bucket.

---

## 7. Explanation Coverage

Honesty SHALL be measurable.

Every report SHOULD distinguish among:

- explained storage;
- generic or owner-level classification; and
- unclassified storage.

Explanation Coverage is the primary internal product-quality metric. It represents the proportion of analyzed storage that the product can meaningfully explain with supported evidence.

Rule and detector releases SHOULD improve explanation coverage across a representative test corpus without reducing classification accuracy or inflating confidence.

Coverage SHALL NOT be improved by weakening evidence requirements.

---

## 8. User Experience Covenant

The first screen SHALL answer:

> **Why is my Mac full?**

Before analysis, the first screen SHALL frame the real user problem rather than describe the app's machinery. It MAY use the founder's real macOS Storage screenshot as a clearly labeled example of the unexplained System Data problem.

It SHALL NOT list fixed or speculative folders, apps, categories, or technologies that "will be scanned." The product does not know what is present on another person's Mac until local observation finishes.

It SHALL prioritize a small number of meaningful contributors, such as developer tools, application data, device backups, creative working data, macOS-managed data, and unclassified storage.

Every user-facing explanation SHOULD answer, in plain language:

- What is this?
- Who created or owns it?
- Why can it become large?
- Is it expected, recreatable, or worthy of review?
- How certain is this explanation?
- What should I do with it?
- Where can I inspect it myself?

Technical details SHALL remain available through drill-down for users who want them.

User-facing language SHALL describe the outcome, not the mechanism. Words associated with commodity cleaner utilities—including **scan**, **scanner**, **clean**, and **optimize**—SHALL NOT appear in the primary interface. Approved action language includes **Explain My System Data**, **Understand My Storage**, **Check Again**, and **Show in Finder**.

All routine interaction SHALL remain in a single cockpit with inline expansion. A category expands to its observed parts; a part expands to one concise explanation, one decision, and one Finder action. Page stacks and detail-page navigation are forbidden for this core flow.

Primary copy MUST be concise. An expanded result SHOULD communicate, without repetition:

- what it is;
- the supported decision; and
- where to inspect it.

Secondary reasoning and raw evidence MAY appear in one optional inline disclosure.

The visual system SHALL use calm neutral system surfaces with blue reserved for actions, generous whitespace, strong contrast, and large interaction regions. It SHALL follow the user's macOS Light or Dark appearance automatically and SHALL NOT add a separate appearance setting. On contemporary macOS, standard controls and a small number of primary controls SHALL adopt the system Liquid Glass appearance. Liquid Glass SHALL remain a functional layer and SHALL NOT be repeated as decoration across content cards.

Every primary row and action SHALL provide an interaction region of at least 44 points in height, even when the macOS platform minimum is smaller. The interface SHALL support pointer, keyboard, Full Keyboard Access, VoiceOver, increased contrast, reduced transparency, and larger text without hiding essential meaning.

The product SHALL NOT:

- show raw paths as the primary label;
- call all large storage "junk";
- use unexplained technical terminology;
- overwhelm the user with dozens of equal-priority categories;
- use fake urgency, fear, or exaggerated warnings;
- block the interface while scanning; or
- imply that a large number is inherently dangerous.

Internal quality language such as "coverage," "owner/family," "logical size," "APFS," or rule identifiers SHALL NOT appear in the primary decision flow. If shown at all, it belongs in optional technical details and must be explained.

Essential labels, descriptions, sizes, and actions MUST remain comfortably legible at default macOS display settings. Caption-sized text SHALL NOT carry information required to understand or act on a result.

The zero-technical-knowledge test is binding:

> A user must not need to understand the filesystem to understand why their disk is full.

The plain-language test is also binding:

> A tenth-grade reader should understand every primary label and recommendation on the first read, without learning storage jargon.

---

## 9. Privacy and Trust Covenant

The product SHALL make these statements technically true:

```text
READ ONLY

System Data Explained cannot delete your files.

All analysis happens locally.

No filenames or filesystem information leave this Mac.
```

Version 1 SHALL require:

- no account;
- no login;
- no cloud backend;
- no file upload;
- no AI or network dependency; and
- no telemetry or analytics SDK that contradicts the local-only promise.

Permissions SHALL be requested only when necessary, at the moment their purpose can be explained clearly. The product SHALL NOT request broad or sensitive access before explaining why it is needed.

Any future diagnostic export MUST be initiated explicitly by the user. It SHOULD prefer categories, sizes, redacted or relative paths, and classification-relevant metadata. It MUST exclude usernames, document contents, secrets, and personal filenames when they are unnecessary.

---

## 10. Version 1 Scope

Version 1 SHALL provide:

- read-only storage scanning;
- meaningful category aggregation;
- deterministic application and storage-family attribution;
- plain-language explanations;
- confidence-aware handling of unknown data;
- explanation coverage reporting;
- progressive drill-down to technical evidence; and
- evidence-backed keep, review, recreatable, or do-not-delete-yet guidance;
- direct Finder reveal actions for observed files and folders; and
- resilient behavior when some directories cannot be read.
- one persistent cockpit with inline result expansion; and
- a real, clearly labeled System Data example on the opening state.

The initial detector set SHOULD focus on approximately 30–50 high-impact storage families across:

- Apple and personal data;
- development tools;
- creative applications;
- virtual machines;
- system-managed storage; and
- generic fallbacks for large application-owned or unknown directories.

### Explicitly excluded from Version 1

Version 1 SHALL NOT include:

- deletion or automated cleanup;
- a Clean button;
- duplicate-file detection;
- malware scanning;
- uninstallers;
- RAM, CPU, or menu-bar monitoring;
- startup optimization;
- an account or subscription;
- analytics SDKs;
- a cloud backend;
- AI APIs or chat;
- recommendation feeds;
- health scores;
- gamification; or
- fear-based conversion mechanics.

Adding one of these capabilities requires an explicit amendment to this constitution. It MUST NOT enter the product as an incidental implementation detail.

---

## 11. Engineering Constraints That Protect the Product

The application SHALL use native macOS technology: Swift, SwiftUI, Foundation, AppKit where required, and XCTest.

Version 1 SHOULD avoid third-party dependencies unless genuinely unavoidable.

The domain model SHALL remain independent of UI frameworks, StoreKit, payment SDKs, and macOS filesystem implementations.

Dependency direction SHALL remain:

```text
Presentation
      ↓
Application
      ↓
Domain
```

Infrastructure SHALL point inward through interfaces. Core product behavior MUST remain testable without access to a real filesystem.

Classification rules SHALL be declarative and evidence-driven. They MUST NOT become an opaque collection of ad hoc conditions.

Each rule SHOULD define:

- a stable identity;
- matching evidence;
- category and display name;
- owner when known;
- plain-language description;
- confidence;
- risk or status; and
- minimum evidence requirements.

Scanning MUST:

- remain read-only;
- never follow symbolic links;
- avoid crossing volume boundaries unintentionally;
- handle permission failures without failing the entire scan;
- support cancellation;
- run without freezing the interface; and
- tolerate files appearing, disappearing, or changing during a scan.

---

## 12. Product Success and Definition of Done

Version 1 is done when a user with no knowledge of macOS internals can run one scan and understand the largest causes of their hidden storage.

The user must also be able to decide what deserves attention, reveal the relevant location in Finder, and make their own informed keep-or-delete choice without the app mutating anything.

The success reaction is:

> **Oh. That's where it went.**

Version 1 is not blocked on:

- explaining every filesystem location;
- classifying every byte;
- matching Apple's displayed number exactly; or
- providing cleanup.

The primary product metric is Explanation Coverage.

The primary user-outcome question is:

> Did the user identify their largest unexplained storage source?

The product SHALL NOT optimize for files deleted, gigabytes cleaned, daily active use, or time spent in the app. A successful session may last only two minutes.

---

## 13. Commercial and Distribution Principles

Version 1 is intended to be a focused, one-time-purchase utility priced at $4.99, with no subscription.

The Mac App Store is the preferred first distribution channel only if its sandbox permits enough visibility to deliver the core promise truthfully.

If the sandbox materially prevents useful explanation, the limitation MUST be measured and disclosed. A signed and notarized direct-distribution edition MAY be pursued when it enables a materially better product.

Distribution capability SHALL take priority over commission optimization.

Marketing MUST be transparent. The product SHALL NOT use stealth promotion, fear, fake urgency, or misleading storage claims.

Educational content SHOULD solve the reader's problem even if they never purchase the application. The app is the shortcut, not a reason to withhold useful information.

---

## 14. Change Admission Test

Before any product change is accepted, its proposal MUST answer:

1. Which user confusion does this remove?
2. What observed evidence supports it?
3. What important outcome breaks if it is omitted?
4. Does it expose unnecessary technical complexity?
5. Could it mislead the user or overstate certainty?
6. Does it increase filesystem, privacy, or permission risk?
7. Does it preserve deterministic, local behavior?
8. Does it preserve read-only architecture?
9. Does it make totals more truthful and understandable?
10. Does it make the product resemble a generic cleaner or optimization suite?

A proposal that cannot answer these questions satisfactorily SHALL be rejected, narrowed, or deferred.

---

## 15. Final Inversion Check

Before shipping any change, ask:

> **How would this change make the product worse?**

Reject or redesign changes that would:

- confuse the user;
- increase anxiety;
- exaggerate a problem;
- introduce deletion risk;
- weaken deterministic behavior;
- require unnecessary permissions;
- reduce privacy;
- expose implementation details too early;
- make scanning materially slower without proportional value;
- make totals less trustworthy;
- introduce concepts the user should not need to learn; or
- make the app resemble generic cleaner software.

When uncertainty remains, use this final test:

> **If we wanted to turn this into another confusing, untrustworthy Mac cleaner, would we add this?**

If the answer is yes, omit it.

---

## 16. Constitutional Summary

### Product thesis

> **macOS gives you a number. We give you the explanation.**

### Engineering thesis

> **Measure everything we can, infer only what evidence supports, explain it simply, and admit what remains unknown.**

### User-experience thesis

> **The user should never need to understand the filesystem in order to understand why their disk is full.**

### Business thesis

> **A focused $4.99 utility that resolves a painful mystery is more valuable than a bloated cleaner trying to become a subscription business.**

## Approved first-release clarification — 31 August 2026

The initial release is a directly downloaded, Developer ID signed and Apple-notarized Mac
app, not an App Store submission. The application remains local, read-only, and without
network capability. Release tooling may contact Apple for signing and notarization.

User control means identifying exact large items, explaining the consequences of removal,
distinguishing replacement from recovery, and providing an inspection route when an app's
own storage controls fail. Finder access must select the observed item, not a broad parent
chosen from a list of evidence paths. Advice must never treat missing, old, or unlisted data
as disposable. Nothing is deleted by the app. See DEVELOPMENT_DOCTRINE section 21 for the
strictly bounded simulator metadata exception and its safety gates.
