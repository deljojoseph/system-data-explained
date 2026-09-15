public struct AppIdentity: Codable, Hashable, Sendable {
    public let bundleIdentifier: String
    public let displayName: String
    public let developer: String?

    public init(bundleIdentifier: String, displayName: String, developer: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.developer = developer
    }
}
