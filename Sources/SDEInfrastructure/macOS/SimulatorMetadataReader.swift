import Darwin
import Foundation
import SDEApplication
import SDEDomain

public struct SimulatorMetadataReader: SimulatorMetadataReading {
    private let homePath: String
    public init(homePath: String = MacEnvironment.homePath) { self.homePath = homePath }

    public func read(_ location: ObservedLocation) -> SimulatorMetadata? {
        let url = URL(fileURLWithPath: location.path)
        let allowed = [homePath + "/Library/Developer/CoreSimulator/Devices", homePath + "/Library/Developer/XCTestDevices"]
        guard allowed.contains(url.deletingLastPathComponent().path),
              let directoryID = UUID(uuidString: url.lastPathComponent),
              let directory = ObservedFileAccess.verifiedDescriptor(location) else { return nil }
        defer { close(directory) }
        let descriptor = openat(directory, "device.plist", O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard descriptor >= 0 else { return nil }
        defer { close(descriptor) }
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_size > 0, info.st_size <= 65_536 else { return nil }
        var bytes = [UInt8](repeating: 0, count: Int(info.st_size))
        let count = bytes.withUnsafeMutableBytes { buffer in Darwin.read(descriptor, buffer.baseAddress, buffer.count) }
        guard count == bytes.count,
              let plist = try? PropertyListSerialization.propertyList(from: Data(bytes), options: [], format: nil),
              let fields = plist as? [String: Any],
              let identifier = fields["UDID"] as? String, UUID(uuidString: identifier) == directoryID,
              let name = safeString(fields["name"], limit: 120) else { return nil }
        return SimulatorMetadata(name: name, runtime: safeString(fields["runtime"], limit: 200))
    }

    private func safeString(_ value: Any?, limit: Int) -> String? {
        guard let value = value as? String, !value.isEmpty, value.count <= limit,
              value.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) && $0.properties.generalCategory != .format }) else { return nil }
        return value
    }
}
