import Foundation
import SDEDomain

enum RuleMatcher: Sendable {
    case homePrefix(String)
    case absolutePrefix(String)
    case fileExtensions(Set<String>)

    func match(path: String, homePath: String, kind: StorageEntryKind) -> String? {
        switch self {
        case .homePrefix(let relativePath):
            let prefix = homePath + "/" + relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return Self.isInside(path, prefix: prefix) ? prefix : nil
        case .absolutePrefix(let prefix):
            let normalized = LexicalPath.normalize(prefix)
            return Self.isInside(path, prefix: normalized) ? normalized : nil
        case .fileExtensions(let extensions):
            guard kind == .file || kind == .package else { return nil }
            let pathExtension = (path as NSString).pathExtension.lowercased()
            return extensions.contains(pathExtension) ? ".\(pathExtension)" : nil
        }
    }

    private static func isInside(_ path: String, prefix: String) -> Bool {
        path == prefix || path.hasPrefix(prefix + "/")
    }
}

struct PathRule: Sendable {
    let id: String
    let matcher: RuleMatcher
    let category: StorageCategory
    let displayName: String
    let owner: String?
    let explanation: String
    let whyLarge: String
    let nextStep: String?
    let risk: RiskLevel
    let confidence: Confidence

    init(
        id: String,
        matcher: RuleMatcher,
        category: StorageCategory,
        displayName: String,
        owner: String? = nil,
        explanation: String,
        whyLarge: String,
        nextStep: String? = nil,
        risk: RiskLevel,
        confidence: Confidence = .high
    ) {
        self.id = id
        self.matcher = matcher
        self.category = category
        self.displayName = displayName
        self.owner = owner
        self.explanation = explanation
        self.whyLarge = whyLarge
        self.nextStep = nextStep
        self.risk = risk
        self.confidence = confidence
    }
}
