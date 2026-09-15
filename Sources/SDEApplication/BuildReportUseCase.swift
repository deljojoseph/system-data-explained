import Foundation
import SDEDomain

public final class BuildReportUseCase: @unchecked Sendable {
    private struct MutableItem {
        var classification: Classification
        var measuredBytes: Int64 = 0
        var logicalBytes: Int64 = 0
        var fileCount: Int = 0
        var technicalPaths: Set<String> = []
    }

    private let lock = NSLock()
    private var itemsByID: [String: MutableItem] = [:]
    private var locationsByPath: [String: ObservedLocation] = [:]

    public init() {}

    public func observe(_ observation: StorageObservation, as classification: Classification) {
        lock.lock()
        defer { lock.unlock() }

        if observation.path == classification.reviewPath, let identity = observation.identity {
            locationsByPath[observation.path] = ObservedLocation(path: observation.path, identity: identity)
        }
        guard observation.kind != .directory else { return }

        let locationKey = classification.reviewPath ?? classification.evidence.first {
            $0.kind == .path || $0.kind == .storageFamily
        }?.value ?? classification.ruleID
        let itemID = classification.ruleID + "::" + locationKey

        var item = itemsByID[itemID] ?? MutableItem(classification: classification)
        item.measuredBytes += observation.measuredBytes
        item.logicalBytes += observation.logicalBytes
        item.fileCount += 1

        for evidence in classification.evidence
        where evidence.kind == .path || evidence.kind == .storageFamily {
            if item.technicalPaths.count < 8 {
                item.technicalPaths.insert(evidence.value)
            }
        }

        itemsByID[itemID] = item
    }

    public func build(summary: ScanSummary, volume: VolumeSnapshot?) -> ExplanationReport {
        lock.lock()
        let snapshot = itemsByID
        let locations = locationsByPath
        lock.unlock()

        let items = snapshot.map { id, mutable in
            ExplanationItem(
                id: id,
                classification: mutable.classification,
                measuredBytes: mutable.measuredBytes,
                logicalBytes: mutable.logicalBytes,
                fileCount: mutable.fileCount,
                technicalPaths: mutable.technicalPaths.sorted(),
                location: mutable.classification.reviewPath.flatMap { locations[$0] }
            )
        }

        let grouped = Dictionary(grouping: items, by: { $0.classification.category })
        let categories = grouped.map { category, categoryItems in
            CategorySummary(
                category: category,
                measuredBytes: categoryItems.reduce(0) { $0 + $1.measuredBytes },
                logicalBytes: categoryItems.reduce(0) { $0 + $1.logicalBytes },
                items: categoryItems.sorted {
                    if $0.measuredBytes == $1.measuredBytes {
                        return $0.classification.displayName < $1.classification.displayName
                    }
                    return $0.measuredBytes > $1.measuredBytes
                }
            )
        }.sorted {
            if $0.measuredBytes == $1.measuredBytes {
                return $0.category.sortOrder < $1.category.sortOrder
            }
            return $0.measuredBytes > $1.measuredBytes
        }

        let measuredBytes = items.reduce(0) { $0 + $1.measuredBytes }
        let logicalBytes = items.reduce(0) { $0 + $1.logicalBytes }
        let explainedBytes = items
            .filter { $0.classification.level == .known }
            .reduce(0) { $0 + $1.measuredBytes }
        let genericBytes = items
            .filter { $0.classification.level == .ownerKnown }
            .reduce(0) { $0 + $1.measuredBytes }
        let unclassifiedBytes = items
            .filter { $0.classification.level == .unknown }
            .reduce(0) { $0 + $1.measuredBytes }

        let scanReport = ScanReport(
            summary: summary,
            volume: volume,
            measuredBytes: measuredBytes,
            logicalBytes: logicalBytes
        )

        return ExplanationReport(
            createdAt: Date(),
            scan: scanReport,
            categories: categories,
            explainedBytes: explainedBytes,
            genericBytes: genericBytes,
            unclassifiedBytes: unclassifiedBytes
        )
    }
}
