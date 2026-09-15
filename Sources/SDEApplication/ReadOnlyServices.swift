import SDEDomain

public protocol FileSystemReading: Sendable {
    func scan(
        _ request: ScanRequest,
        onObservation: @escaping @Sendable (StorageObservation) -> Void,
        onProgress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> ScanSummary
}

public protocol VolumeReading: Sendable {
    func snapshot(forPath path: String) async -> VolumeSnapshot?
}

public protocol StorageClassifying: Sendable {
    func classify(_ observation: StorageObservation) -> Classification
}

@MainActor
public protocol LocationRevealing {
    func reveal(_ location: ObservedLocation) -> Bool
}

public protocol SimulatorMetadataReading: Sendable {
    func read(_ location: ObservedLocation) -> SimulatorMetadata?
}
