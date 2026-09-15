import SDEDomain

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
        let summary = try await fileSystem.scan(
            normalizedRequest,
            onObservation: { observation in
                let classification = explainer.execute(observation)
                reportBuilder.observe(observation, as: classification)
            },
            onProgress: onProgress
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
    }
}
