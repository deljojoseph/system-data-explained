public enum Confidence: String, Codable, Hashable, Sendable {
    case high
    case medium
    case low

    public var title: String {
        switch self {
        case .high: "High confidence"
        case .medium: "Owner or storage family identified"
        case .low: "Purpose not identified"
        }
    }
}

public enum ExplanationLevel: String, Codable, Hashable, Sendable {
    case known
    case ownerKnown
    case unknown

    public var title: String {
        switch self {
        case .known: "Identified"
        case .ownerKnown: "Application data"
        case .unknown: "Unclassified"
        }
    }
}

public enum RiskLevel: String, Codable, Hashable, Sendable {
    case expected
    case rebuildable
    case review
    case unknown

    public var title: String {
        switch self {
        case .expected: "Keep"
        case .rebuildable: "Check what you need"
        case .review: "Check first"
        case .unknown: "Not understood"
        }
    }

    public var explanation: String {
        switch self {
        case .expected: "The app or macOS appears to need this for normal use. Keep it unless the app has its own storage controls."
        case .rebuildable: "Some files may be replaceable. Check the requirements for this item before removing anything."
        case .review: "These may be projects, backups, downloads, or history you still need. Open the location and check before removing anything."
        case .unknown: "The app cannot tell what these files do. Keep them unless you recognize their purpose."
        }
    }
}

public enum EvidenceKind: String, Codable, Hashable, Sendable {
    case path
    case bundleIdentifier
    case fileType
    case storageFamily
}

public struct StorageEvidence: Codable, Hashable, Sendable {
    public let kind: EvidenceKind
    public let value: String

    public init(kind: EvidenceKind, value: String) {
        self.kind = kind
        self.value = value
    }
}

public struct Classification: Codable, Hashable, Sendable {
    public let ruleID: String
    public let category: StorageCategory
    public let displayName: String
    public let owner: String?
    public let explanation: String
    public let whyLarge: String
    public let nextStep: String
    public let risk: RiskLevel
    public let confidence: Confidence
    public let level: ExplanationLevel
    public let evidence: [StorageEvidence]
    public let reviewPath: String?
    public let reviewName: String?
    public let guidance: ReviewGuidance?

    /// Keep results explain normal or required storage. Providing a direct
    /// filesystem shortcut would contradict that decision and invite harm.
    public var allowsFinderReveal: Bool { risk != .expected }

    public init(
        ruleID: String,
        category: StorageCategory,
        displayName: String,
        owner: String? = nil,
        explanation: String,
        whyLarge: String,
        nextStep: String? = nil,
        risk: RiskLevel,
        confidence: Confidence,
        level: ExplanationLevel,
        evidence: [StorageEvidence],
        reviewPath: String? = nil,
        reviewName: String? = nil,
        guidance: ReviewGuidance? = nil
    ) {
        self.ruleID = ruleID
        self.category = category
        self.displayName = displayName
        self.owner = owner
        self.explanation = explanation
        self.whyLarge = whyLarge
        self.nextStep = nextStep ?? Self.defaultNextStep(risk: risk, owner: owner)
        self.risk = risk
        self.confidence = confidence
        self.level = level
        self.evidence = evidence
        self.reviewPath = reviewPath
        self.reviewName = reviewName
        self.guidance = guidance
    }

    private static func defaultNextStep(risk: RiskLevel, owner: String?) -> String {
        let app = owner ?? "the app that made it"
        switch risk {
        case .expected:
            return "Keep this. If you need space, look for storage controls inside \(app) first."
        case .rebuildable:
            return "Check which files \(app) can replace, and what you would need to get them back."
        case .review:
            return "Check \(app) for storage controls first. In Finder, change only projects or files you recognize."
        case .unknown:
            return "There is no safe removal suggestion for this yet. Leave it alone unless you know exactly what it is."
        }
    }
}
