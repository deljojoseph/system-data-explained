import Foundation

public struct ScanRoot: Codable, Hashable, Sendable, Identifiable {
    public let path: String
    public let displayName: String
    public let isOptional: Bool

    public var id: String { path }

    public init(path: String, displayName: String, isOptional: Bool = false) {
        self.path = path
        self.displayName = displayName
        self.isOptional = isOptional
    }
}

public struct ScanRequest: Codable, Hashable, Sendable {
    public let roots: [ScanRoot]
    public let stayOnVolume: Bool

    public init(roots: [ScanRoot], stayOnVolume: Bool = true) {
        self.roots = roots
        self.stayOnVolume = stayOnVolume
    }
}

public enum ScanIssueKind: String, Codable, Hashable, Sendable {
    case unavailableRoot
    case permissionDenied
    case transientFileChange
    case volumeBoundarySkipped
    case metadataUnavailable
}

public struct ScanIssue: Codable, Hashable, Sendable, Identifiable {
    public let kind: ScanIssueKind
    public let path: String
    public let message: String

    public var id: String { "\(kind.rawValue):\(path):\(message)" }

    public init(kind: ScanIssueKind, path: String, message: String) {
        self.kind = kind
        self.path = path
        self.message = message
    }
}

public struct ScanProgress: Codable, Hashable, Sendable {
    public let filesObserved: Int
    public let directoriesObserved: Int
    public let measuredBytes: Int64
    public let currentArea: String

    public init(filesObserved: Int, directoriesObserved: Int, measuredBytes: Int64, currentArea: String) {
        self.filesObserved = filesObserved
        self.directoriesObserved = directoriesObserved
        self.measuredBytes = measuredBytes
        self.currentArea = currentArea
    }
}

public struct ScanSummary: Codable, Hashable, Sendable {
    public let roots: [ScanRoot]
    public let filesObserved: Int
    public let directoriesObserved: Int
    public let symbolicLinksSkipped: Int
    public let measuredBytes: Int64
    public let logicalBytes: Int64
    public let issues: [ScanIssue]
    public let issueCounts: [ScanIssueKind: Int]
    public var issueCount: Int { issueCounts.values.reduce(0, +) }
    public let duration: TimeInterval

    public init(
        roots: [ScanRoot],
        filesObserved: Int,
        directoriesObserved: Int,
        symbolicLinksSkipped: Int,
        measuredBytes: Int64,
        logicalBytes: Int64,
        issues: [ScanIssue],
        duration: TimeInterval,
        issueCounts: [ScanIssueKind: Int]? = nil
    ) {
        self.roots = roots
        self.filesObserved = filesObserved
        self.directoriesObserved = directoriesObserved
        self.symbolicLinksSkipped = symbolicLinksSkipped
        self.measuredBytes = measuredBytes
        self.logicalBytes = logicalBytes
        self.issues = issues
        self.issueCounts = issueCounts ?? Dictionary(grouping: issues, by: \.kind).mapValues(\.count)
        self.duration = duration
    }
}

public struct VolumeSnapshot: Codable, Hashable, Sendable {
    public let totalBytes: Int64
    /// Bytes currently free according to the filesystem. This deliberately
    /// excludes reclaimable or purgeable capacity reported by other macOS UI.
    public let freeBytes: Int64

    public init(totalBytes: Int64, freeBytes: Int64) {
        self.totalBytes = max(0, totalBytes)
        self.freeBytes = max(0, freeBytes)
    }

    public var usedBytes: Int64 {
        max(0, totalBytes - freeBytes)
    }
}
