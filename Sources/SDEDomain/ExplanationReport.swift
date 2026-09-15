import Foundation

public struct ExplanationItem: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let classification: Classification
    public let measuredBytes: Int64
    public let logicalBytes: Int64
    public let fileCount: Int
    public let technicalPaths: [String]
    public let location: ObservedLocation?
    public var simulator: SimulatorMetadata?
    public var title: String { simulator?.name ?? classification.reviewName ?? classification.displayName }

    public init(
        id: String,
        classification: Classification,
        measuredBytes: Int64,
        logicalBytes: Int64,
        fileCount: Int,
        technicalPaths: [String],
        location: ObservedLocation? = nil,
        simulator: SimulatorMetadata? = nil
    ) {
        self.id = id
        self.classification = classification
        self.measuredBytes = measuredBytes
        self.logicalBytes = logicalBytes
        self.fileCount = fileCount
        self.technicalPaths = technicalPaths
        self.location = location
        self.simulator = simulator
    }
}

public struct CategorySummary: Codable, Hashable, Sendable, Identifiable {
    public let category: StorageCategory
    public let measuredBytes: Int64
    public let logicalBytes: Int64
    public var items: [ExplanationItem]

    public var id: String { category.id }

    public init(
        category: StorageCategory,
        measuredBytes: Int64,
        logicalBytes: Int64,
        items: [ExplanationItem]
    ) {
        self.category = category
        self.measuredBytes = measuredBytes
        self.logicalBytes = logicalBytes
        self.items = items
    }

    public func contributionLabel(totalBytes: Int64) -> String {
        guard totalBytes > 0 else { return "Observed" }
        let share = Double(measuredBytes) / Double(totalBytes)
        if share >= 0.35 { return "Major contributor" }
        if share >= 0.15 { return "Large contributor" }
        if share >= 0.05 { return "Noticeable" }
        return "Smaller contributor"
    }

    public var decisionTitle: String {
        if category == .unclassified { return RiskLevel.unknown.title }

        let kinds = Set(items.map { $0.classification.risk })
        if kinds.count > 1 { return "Different kinds of data · review individually" }
        return "Review items individually"
    }
}

public struct ScanReport: Codable, Hashable, Sendable {
    public let summary: ScanSummary
    public let volume: VolumeSnapshot?
    public let measuredBytes: Int64
    public let logicalBytes: Int64

    public init(summary: ScanSummary, volume: VolumeSnapshot?, measuredBytes: Int64, logicalBytes: Int64) {
        self.summary = summary
        self.volume = volume
        self.measuredBytes = measuredBytes
        self.logicalBytes = logicalBytes
    }
}

public struct ExplanationReport: Codable, Hashable, Sendable {
    public let createdAt: Date
    public let scan: ScanReport
    public var categories: [CategorySummary]
    public let explainedBytes: Int64
    public let genericBytes: Int64
    public let unclassifiedBytes: Int64

    public init(
        createdAt: Date,
        scan: ScanReport,
        categories: [CategorySummary],
        explainedBytes: Int64,
        genericBytes: Int64,
        unclassifiedBytes: Int64
    ) {
        self.createdAt = createdAt
        self.scan = scan
        self.categories = categories
        self.explainedBytes = explainedBytes
        self.genericBytes = genericBytes
        self.unclassifiedBytes = unclassifiedBytes
    }

    public var explanationCoverage: Double {
        guard scan.measuredBytes > 0 else { return 0 }
        return min(1, max(0, Double(explainedBytes) / Double(scan.measuredBytes)))
    }

    public var isPartial: Bool {
        scan.summary.issueCount > 0
    }

    public var priorityItems: [ExplanationItem] {
        categories
            .flatMap(\.items)
            .filter { $0.classification.risk == .rebuildable || $0.classification.risk == .review }
            .sorted { $0.measuredBytes > $1.measuredBytes }
    }
}
