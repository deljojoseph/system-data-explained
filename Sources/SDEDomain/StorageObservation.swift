import Foundation

public enum StorageEntryKind: String, Codable, Hashable, Sendable {
    case file
    case directory
    case package
    case symbolicLink
    case other
}

public struct StorageObservation: Codable, Hashable, Sendable {
    public let path: String
    public let rootPath: String
    public let logicalBytes: Int64
    public let allocatedBytes: Int64?
    public let kind: StorageEntryKind
    public let modificationDate: Date?
    public let volumeIdentifier: String?
    public let identity: FileIdentity?

    public init(
        path: String,
        rootPath: String,
        logicalBytes: Int64,
        allocatedBytes: Int64?,
        kind: StorageEntryKind,
        modificationDate: Date? = nil,
        volumeIdentifier: String? = nil,
        identity: FileIdentity? = nil
    ) {
        self.path = path
        self.rootPath = rootPath
        self.logicalBytes = max(0, logicalBytes)
        self.allocatedBytes = allocatedBytes.map { max(0, $0) }
        self.kind = kind
        self.modificationDate = modificationDate
        self.volumeIdentifier = volumeIdentifier
        self.identity = identity
    }

    public var measuredBytes: Int64 {
        allocatedBytes ?? logicalBytes
    }
}

public struct StorageNode: Codable, Hashable, Sendable, Identifiable {
    public let path: String
    public let displayName: String
    public let logicalBytes: Int64
    public let allocatedBytes: Int64?
    public let kind: StorageEntryKind
    public let childCount: Int

    public var id: String { path }

    public init(
        path: String,
        displayName: String,
        logicalBytes: Int64,
        allocatedBytes: Int64?,
        kind: StorageEntryKind,
        childCount: Int
    ) {
        self.path = path
        self.displayName = displayName
        self.logicalBytes = logicalBytes
        self.allocatedBytes = allocatedBytes
        self.kind = kind
        self.childCount = childCount
    }
}
