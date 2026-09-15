import Foundation
import SDEDomain

public enum MacEnvironment {
    public static var homePath: String {
        NSHomeDirectory()
    }
}

public struct DefaultScanScope: Sendable {
    private let homePath: String

    public init(homePath: String = MacEnvironment.homePath) {
        self.homePath = homePath
    }

    public func makeRequest() -> ScanRequest {
        let candidates = [
            ScanRoot(path: homePath + "/Library", displayName: "Your hidden application data"),
            ScanRoot(path: "/Library", displayName: "Shared application data"),
            ScanRoot(path: "/private/var", displayName: "macOS runtime data"),
            ScanRoot(path: "/opt/homebrew", displayName: "Homebrew"),
            ScanRoot(path: "/usr/local/Homebrew", displayName: "Homebrew"),
            ScanRoot(path: homePath + "/.gradle", displayName: "Gradle"),
            ScanRoot(path: homePath + "/.android", displayName: "Android development"),
            ScanRoot(path: homePath + "/.docker", displayName: "Docker"),
            ScanRoot(path: homePath + "/.npm", displayName: "Node development"),
            ScanRoot(path: homePath + "/.vscode", displayName: "Visual Studio Code extensions"),
            ScanRoot(path: homePath + "/Parallels", displayName: "Parallels virtual machines"),
            ScanRoot(path: homePath + "/Virtual Machines.localized", displayName: "VMware virtual machines"),
            ScanRoot(path: homePath + "/VirtualBox VMs", displayName: "VirtualBox machines")
        ]

        // Absence is normal; access failures must be reported by the reader, not filtered out.
        return ScanRequest(roots: candidates.map {
            ScanRoot(path: $0.path, displayName: $0.displayName, isOptional: true)
        }, stayOnVolume: true)
    }
}
