import Foundation
import SDEApplication
import SDEDomain

public struct MacVolumeReader: VolumeReading, Sendable {
    public init() {}

    public func snapshot(forPath path: String) async -> VolumeSnapshot? {
        await Task.detached(priority: .utility) {
            let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path)
            guard let total = attributes?[.systemSize] as? NSNumber,
                  let free = attributes?[.systemFreeSize] as? NSNumber else {
                return nil
            }
            return VolumeSnapshot(
                totalBytes: total.int64Value,
                freeBytes: free.int64Value
            )
        }.value
    }
}
