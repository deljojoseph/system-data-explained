import AppKit
import Foundation
import SDEApplication
import SDEDomain
import Darwin

@MainActor
public struct FinderLocationRevealer: LocationRevealing {
    private let homePath: String

    public init(homePath: String = MacEnvironment.homePath) {
        self.homePath = homePath
    }

    public func reveal(_ location: ObservedLocation) -> Bool {
        guard let descriptor = ObservedFileAccess.verifiedDescriptor(location) else { return false }
        defer { close(descriptor) }
        NSWorkspace.shared.activateFileViewerSelecting([
            URL(fileURLWithPath: location.path)
        ])
        return true
    }
}
