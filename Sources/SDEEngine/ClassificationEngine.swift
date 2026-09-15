import Foundation
import SDEApplication
import SDEDomain

public struct ClassificationEngine: StorageClassifying, Sendable {
    private let homePath: String
    private let appIdentities: [String: AppIdentity]
    private let rules: [PathRule]

    public init(homePath: String, appIdentities: [String: AppIdentity] = [:]) {
        self.homePath = LexicalPath.normalize(homePath)
        self.appIdentities = Dictionary(
            uniqueKeysWithValues: appIdentities.map { ($0.key.lowercased(), $0.value) }
        )
        self.rules = DetectorCatalog.rules
    }

    public func classify(_ observation: StorageObservation) -> Classification {
        ReviewPlanner.enrich(classifyPurpose(observation), observation: observation, homePath: homePath)
    }

    private func classifyPurpose(_ observation: StorageObservation) -> Classification {
        let normalizedPath = LexicalPath.normalize(observation.path)

        for rule in rules {
            if let matched = rule.matcher.match(path: normalizedPath, homePath: homePath, kind: observation.kind) {
                let level: ExplanationLevel = rule.confidence == .high ? .known : .ownerKnown
                return Classification(
                    ruleID: rule.id,
                    category: rule.category,
                    displayName: rule.displayName,
                    owner: rule.owner,
                    explanation: rule.explanation,
                    whyLarge: rule.whyLarge,
                    nextStep: rule.nextStep,
                    risk: rule.risk,
                    confidence: rule.confidence,
                    level: level,
                    evidence: evidence(for: rule.matcher, matched: matched, fullPath: normalizedPath)
                )
            }
        }

        if let result = classifyCloudStorage(normalizedPath) { return result }
        if let result = classifyContainer(normalizedPath, folder: "Containers") { return result }
        if let result = classifyContainer(normalizedPath, folder: "Group Containers") { return result }
        if let result = classifyApplicationFamily(normalizedPath, folder: "Application Support") { return result }
        if let result = classifyCaches(normalizedPath) { return result }
        if let result = classifySharedApplicationSupport(normalizedPath) { return result }

        return classifyUnknown(observation, normalizedPath: normalizedPath)
    }

    private func classifyCloudStorage(_ path: String) -> Classification? {
        let prefix = homePath + "/Library/CloudStorage"
        guard let component = firstComponent(in: path, after: prefix) else { return nil }
        let providerName = friendlyComponent(component)
        return Classification(
            ruleID: "generic.cloud-storage.\(component.lowercased())",
            category: .cloudData,
            displayName: providerName == component ? "Cloud Storage" : providerName,
            owner: providerName == component ? nil : providerName,
            explanation: "Cloud files that are also kept on this Mac.",
            whyLarge: "Files you open often, or mark for offline use, can stay downloaded.",
            risk: .expected,
            confidence: .medium,
            level: .ownerKnown,
            evidence: [StorageEvidence(kind: .storageFamily, value: redact(prefix + "/" + component))]
        )
    }

    private func classifyContainer(_ path: String, folder: String) -> Classification? {
        let prefix = homePath + "/Library/\(folder)"
        guard let component = firstComponent(in: path, after: prefix) else { return nil }
        let identity = resolveIdentity(component)
        let name = identity?.displayName ?? "Application Container Data"

        var evidence = [StorageEvidence(kind: .storageFamily, value: redact(prefix + "/" + component))]
        if identity != nil {
            evidence.append(StorageEvidence(kind: .bundleIdentifier, value: component))
        }

        return Classification(
            ruleID: "generic.\(folder.lowercased().replacingOccurrences(of: " ", with: "-")).\(component.lowercased())",
            category: .applicationData,
            displayName: name,
            owner: identity?.displayName,
            explanation: identity == nil
                ? "Files an app keeps in its own private folder."
                : "Files kept by \(identity!.displayName).",
            whyLarge: "An app may keep downloads, account history, settings, and temporary files here.",
            risk: .review,
            confidence: .medium,
            level: .ownerKnown,
            evidence: evidence
        )
    }

    private func classifyApplicationFamily(_ path: String, folder: String) -> Classification? {
        let prefix = homePath + "/Library/\(folder)"
        guard let component = firstComponent(in: path, after: prefix) else { return nil }
        let identity = resolveIdentity(component)
        let name = identity?.displayName ?? friendlyComponent(component)

        return Classification(
            ruleID: "generic.application-support.\(component.lowercased())",
            category: .applicationData,
            displayName: identity == nil ? "\(name) Data" : identity!.displayName,
            owner: identity?.displayName,
            explanation: "Files kept by \(name) so it can remember your work and settings.",
            whyLarge: "Apps can keep downloads, history, add-ons, and other working files here.",
            risk: .review,
            confidence: .medium,
            level: .ownerKnown,
            evidence: [StorageEvidence(kind: .storageFamily, value: redact(prefix + "/" + component))]
        )
    }

    private func classifyCaches(_ path: String) -> Classification? {
        let prefix = homePath + "/Library/Caches"
        guard let component = firstComponent(in: path, after: prefix) else { return nil }
        let identity = resolveIdentity(component)
        let name = identity?.displayName

        return Classification(
            ruleID: "generic.cache.\(component.lowercased())",
            category: .cachesAndLogs,
            displayName: name.map { "\($0) Temporary Files" } ?? "Temporary Files from an Unidentified App",
            owner: name,
            explanation: name.map { "Temporary copies made by \($0) so it can work faster." }
                ?? "This is stored where apps normally keep temporary copies, but the app that created it could not be confirmed.",
            whyLarge: "These copies grow as apps open media, download content, and reuse files.",
            risk: .rebuildable,
            confidence: .medium,
            level: .ownerKnown,
            evidence: [StorageEvidence(kind: .storageFamily, value: redact(prefix + "/" + component))]
        )
    }

    private func classifySharedApplicationSupport(_ path: String) -> Classification? {
        let prefix = "/Library/Application Support"
        guard let component = firstComponent(in: path, after: prefix) else { return nil }
        let name = friendlyComponent(component)

        return Classification(
            ruleID: "generic.shared-application-support.\(component.lowercased())",
            category: .applicationData,
            displayName: "\(name) shared files",
            owner: nil,
            explanation: "Files installed for every user by \(name) or a related app.",
            whyLarge: "Apps can keep add-ons, templates, downloads, and shared working files here.",
            risk: .review,
            confidence: .medium,
            level: .ownerKnown,
            evidence: [StorageEvidence(kind: .storageFamily, value: prefix + "/" + component)]
        )
    }

    private func classifyUnknown(
        _ observation: StorageObservation,
        normalizedPath: String
    ) -> Classification {
        let anchor = unknownAnchor(path: normalizedPath, rootPath: observation.rootPath)
        let redactedAnchor = redact(anchor)
        let areaName = plainAreaName(anchor)

        return Classification(
            ruleID: "unknown.\(redactedAnchor.lowercased())",
            category: .unclassified,
            displayName: "Unidentified \(areaName)",
            explanation: "These files are in \(areaName.lowercased()), but no reliable storage standard identifies their exact purpose.",
            whyLarge: "This location may contain files from an app or tool the current rule set does not recognize yet.",
            risk: .unknown,
            confidence: .low,
            level: .unknown,
            evidence: [StorageEvidence(kind: .path, value: redactedAnchor)]
        )
    }

    private func unknownAnchor(path: String, rootPath: String) -> String {
        let root = LexicalPath.normalize(rootPath)
        guard path.hasPrefix(root + "/") else { return root }

        let remainder = String(path.dropFirst(root.count + 1))
        let components = remainder.split(separator: "/").map(String.init)
        guard let first = components.first else { return root }

        let needsOwnerComponent = [
            "Application Support", "Caches", "Containers", "Group Containers", "CloudStorage"
        ].contains(first)
        let depth = needsOwnerComponent ? min(2, components.count) : 1
        return root + "/" + components.prefix(depth).joined(separator: "/")
    }

    private func plainAreaName(_ path: String) -> String {
        let component = URL(fileURLWithPath: path).lastPathComponent
        let names: [String: String] = [
            "Library": path.hasPrefix(homePath) ? "hidden app files" : "shared app files",
            "WebKit": "web content data",
            "HTTPStorages": "website data",
            "Preferences": "app settings",
            "Saved Application State": "saved app windows",
            "Metadata": "search and app indexes",
            "Receipts": "installation records",
            "Frameworks": "shared software parts",
            "LaunchAgents": "background app helpers",
            "LaunchDaemons": "background system helpers",
            "PrivilegedHelperTools": "app helper tools",
            "Fonts": "fonts",
            "Audio": "audio files",
            "Java": "Java tools",
            "share": "Homebrew shared files",
            "lib": "Homebrew libraries",
            "var": "Homebrew service data",
            ".gradle": "Gradle files",
            ".android": "Android development files",
            ".npm": "Node package files"
        ]
        return names[component] ?? friendlyComponent(component) + " files"
    }

    private func resolveIdentity(_ value: String) -> AppIdentity? {
        let lowered = value.lowercased()
        if let exact = appIdentities[lowered] { return exact }

        let withoutTeamPrefix = value.split(separator: ".", maxSplits: 1).last.map(String.init) ?? value
        return appIdentities[withoutTeamPrefix.lowercased()]
    }

    private func friendlyComponent(_ component: String) -> String {
        if let identity = resolveIdentity(component) {
            return identity.displayName
        }

        let knownNames: [String: String] = [
            "dropbox": "Dropbox",
            "onedrive-personal": "Microsoft OneDrive",
            "onedrive-business1": "Microsoft OneDrive",
            "google drive": "Google Drive",
            "icloud drive": "iCloud Drive"
        ]
        if let known = knownNames[component.lowercased()] { return known }

        let base = component.contains(".")
            ? (component.split(separator: ".").last.map(String.init) ?? component)
            : component
        return base
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }

    private func firstComponent(in path: String, after prefix: String) -> String? {
        guard path.hasPrefix(prefix + "/") else { return nil }
        let remainder = String(path.dropFirst(prefix.count + 1))
        return remainder.split(separator: "/", maxSplits: 1).first.map(String.init)
    }

    private func redact(_ path: String) -> String {
        if path == homePath { return "~" }
        if path.hasPrefix(homePath + "/") {
            return "~" + String(path.dropFirst(homePath.count))
        }
        return path
    }

    private func evidence(
        for matcher: RuleMatcher,
        matched: String,
        fullPath: String
    ) -> [StorageEvidence] {
        switch matcher {
        case .fileExtensions:
            return [
                StorageEvidence(kind: .fileType, value: matched),
                StorageEvidence(kind: .path, value: redact(fullPath))
            ]
        case .homePrefix, .absolutePrefix:
            return [StorageEvidence(kind: .path, value: redact(matched))]
        }
    }
}
