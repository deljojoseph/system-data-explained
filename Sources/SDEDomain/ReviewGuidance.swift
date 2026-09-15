import Foundation

public enum ReviewKind: String, Codable, Hashable, Sendable {
    case simulatorDevice, simulatorRuntime, buildFiles, downloads, generatedMedia
    case persistentData, cloudFiles, backup, archive, system, unknown
}

public struct ReviewGuidance: Codable, Hashable, Sendable {
    public let kind: ReviewKind
    public let summary: String
    public let consequence: String
    public let recovery: String
    public let nextStep: String
    public let fallbackTitle: String
    public let fallbackSteps: [String]
    public let sourceURL: String?

    public init(kind: ReviewKind, summary: String, consequence: String, recovery: String,
                nextStep: String, fallbackTitle: String = "How to review",
                fallbackSteps: [String] = [], sourceURL: String? = nil) {
        self.kind = kind
        self.summary = summary
        self.consequence = consequence
        self.recovery = recovery
        self.nextStep = nextStep
        self.fallbackTitle = fallbackTitle
        self.fallbackSteps = fallbackSteps
        self.sourceURL = sourceURL
    }
}

public struct FileIdentity: Codable, Hashable, Sendable {
    public let device: UInt64
    public let inode: UInt64
    public init(device: UInt64, inode: UInt64) { self.device = device; self.inode = inode }
}

public struct ObservedLocation: Codable, Hashable, Sendable {
    public let path: String
    public let identity: FileIdentity
    public init(path: String, identity: FileIdentity) { self.path = path; self.identity = identity }
}

public struct SimulatorMetadata: Codable, Hashable, Sendable {
    public let name: String
    public let runtime: String?
    public init(name: String, runtime: String?) { self.name = name; self.runtime = runtime }
}
