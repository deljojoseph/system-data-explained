import Foundation
import SDEDomain

public struct InstalledAppReader: Sendable {
    public init() {}

    public func readInstalledApplications(homePath: String = MacEnvironment.homePath) -> [String: AppIdentity] {
        let roots = [
            "/Applications",
            "/System/Applications",
            homePath + "/Applications"
        ]
        let fileManager = FileManager()
        var identities: [String: AppIdentity] = [:]

        for root in roots where fileManager.fileExists(atPath: root) {
            let rootURL = URL(fileURLWithPath: root, isDirectory: true)
            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                if enumerator.level > 3 {
                    enumerator.skipDescendants()
                    continue
                }
                guard url.pathExtension.lowercased() == "app" else { continue }
                enumerator.skipDescendants()

                guard let bundle = Bundle(url: url),
                      let identifier = bundle.bundleIdentifier,
                      !identifier.isEmpty else { continue }

                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent

                identities[identifier.lowercased()] = AppIdentity(
                    bundleIdentifier: identifier,
                    displayName: displayName
                )
            }
        }

        return identities
    }
}
