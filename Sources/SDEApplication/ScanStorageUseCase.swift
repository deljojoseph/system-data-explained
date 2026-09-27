import Foundation
import SDEDomain

public struct ScanCancelledError: Error, Sendable {
    public let partialReport: ExplanationReport

    public init(partialReport: ExplanationReport) {
        self.partialReport = partialReport
    }
}

private final class ProgressSnapshot: @unchecked Sendable {
    private let lock = NSLock()
    private var progress: ScanProgress

    init(_ progress: ScanProgress) {
        self.progress = progress
    }

    func update(_ progress: ScanProgress) {
        lock.lock()
        self.progress = progress
        lock.unlock()
    }

    var value: ScanProgress {
        lock.lock()
        defer { lock.unlock() }
        return progress
    }
}

public struct ScanStorageUseCase: Sendable {
    private let fileSystem: any FileSystemReading
    private let volumeReader: any VolumeReading
    private let explainer: ExplainStorageUseCase
    private let simulatorReader: (any SimulatorMetadataReading)?

    public init(
        fileSystem: any FileSystemReading,
        volumeReader: any VolumeReading,
        classifier: any StorageClassifying,
        simulatorReader: (any SimulatorMetadataReading)? = nil
    ) {
        self.fileSystem = fileSystem
        self.volumeReader = volumeReader
        self.explainer = ExplainStorageUseCase(classifier: classifier)
        self.simulatorReader = simulatorReader
    }

    public func execute(
        _ request: ScanRequest,
        onProgress: @escaping @Sendable (ScanProgress) -> Void = { _ in }
    ) async throws -> ExplanationReport {
        let normalizedRequest = ScanRequest(
            roots: ScanRootNormalizer.normalize(request.roots),
            stayOnVolume: request.stayOnVolume
        )

        let reportBuilder = BuildReportUseCase()
        let initialProgress = ScanProgress(
            filesObserved: 0,
            directoriesObserved: 0,
            measuredBytes: 0,
            currentArea: "Preparing"
        )
        let progressSnapshot = ProgressSnapshot(initialProgress)
        let startedAt = Date()

        do {
            let summary = try await fileSystem.scan(
                normalizedRequest,
                onObservation: { observation in
                    let classification = explainer.execute(observation)
                    reportBuilder.observe(observation, as: classification)
                },
                onProgress: { progress in
                    progressSnapshot.update(progress)
                    onProgress(progress)
                }
            )

            let volume = await volumeReader.snapshot(forPath: normalizedRequest.roots.first?.path ?? "/")
            let initialReport = reportBuilder.build(summary: summary, volume: volume)
            guard let simulatorReader else { return initialReport }
            let worker = Task.detached(priority: .userInitiated) {
                var report = initialReport
                for category in report.categories.indices {
                    for index in report.categories[category].items.indices {
                        try Task.checkCancellation()
                        let item = report.categories[category].items[index]
                        guard item.classification.guidance?.kind == .simulatorDevice,
                              let location = item.location else { continue }
                        report.categories[category].items[index].simulator = simulatorReader.read(location)
                    }
                }
                return report
            }
            return try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: { worker.cancel() })
        } catch is CancellationError {
            let progress = progressSnapshot.value
            let issue = ScanIssue(
                kind: .cancelled,
                path: progress.currentArea,
                message: "The check was stopped before every selected location was examined."
            )
            let summary = ScanSummary(
                roots: normalizedRequest.roots,
                filesObserved: progress.filesObserved,
                directoriesObserved: progress.directoriesObserved,
                symbolicLinksSkipped: 0,
                measuredBytes: progress.measuredBytes,
                logicalBytes: reportBuilder.partialLogicalBytes(),
                issues: [issue],
                duration: Date().timeIntervalSince(startedAt)
            )
            let volume = await volumeReader.snapshot(forPath: normalizedRequest.roots.first?.path ?? "/")
            throw ScanCancelledError(partialReport: reportBuilder.build(summary: summary, volume: volume))
        }
    }
}
