import Foundation
import XCTest
import SDEDomain
import SDEEngine
import SDEApplication
@testable import SDEInfrastructure

final class ReviewGuidanceTests: XCTestCase {
    let home = "/Users/review-test"
    let firstID = "11111111-1111-1111-1111-111111111111"
    let secondID = "22222222-2222-2222-2222-222222222222"
    private var fixtures: [URL] = []

    override func tearDownWithError() throws {
        for fixture in fixtures { try FileManager.default.removeItem(at: fixture) }
    }

    func testIndividualDevicesAreCountedOnceWithoutAnXcodeDeviceList() {
        let engine = ClassificationEngine(homePath: home)
        let builder = BuildReportUseCase()
        for (index, id) in [firstID, secondID].enumerated() {
            let path = home + "/Library/Developer/CoreSimulator/Devices/" + id
            let directory = observation(path, bytes: 0, kind: .directory)
            builder.observe(directory, as: engine.classify(directory))
            for leaf in ["data/a", "data/b"] {
                let file = observation(path + "/" + leaf, bytes: Int64((index + 1) * 100))
                builder.observe(file, as: engine.classify(file))
            }
        }
        let report = builder.build(summary: summary(), volume: nil)
        let items = report.categories.flatMap(\.items)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.map(\.measuredBytes), [400, 200])
        XCTAssertEqual(report.scan.measuredBytes, 600)
        XCTAssertTrue(items.allSatisfy { $0.location != nil && $0.fileCount == 2 })
        XCTAssertEqual(Set(items.compactMap { $0.location?.path }).count, 2)
        XCTAssertTrue(items.allSatisfy { $0.classification.guidance?.kind == .simulatorDevice })
    }

    func testSharedRuntimeIsNotDeviceState() {
        let engine = ClassificationEngine(homePath: home)
        let runtime = engine.classify(observation("/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/data"))
        XCTAssertEqual(runtime.guidance?.kind, .simulatorRuntime)
        XCTAssertEqual(runtime.reviewPath, "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime")
        let device = engine.classify(observation(home + "/Library/Developer/CoreSimulator/Devices/" + firstID + "/data"))
        XCTAssertTrue(device.guidance!.recovery.contains("fresh device is empty"))
        XCTAssertTrue(device.guidance!.fallbackSteps.joined().contains("not validated"))
    }

    func testMalformedDeviceDirectoryDoesNotReceiveDeviceRecipe() {
        let classification = ClassificationEngine(homePath: home).classify(observation(home + "/Library/Developer/CoreSimulator/Devices/device_set.plist"))
        XCTAssertNotEqual(classification.guidance?.kind, .simulatorDevice)
    }

    func testDifferentProjectsAreSeparateReviewUnits() {
        let engine = ClassificationEngine(homePath: home)
        let root = home + "/Library/Developer/Xcode/DerivedData/"
        XCTAssertEqual(engine.classify(observation(root + "App-a/Build/file")).reviewPath, root + "App-a")
        XCTAssertEqual(engine.classify(observation(root + "App-b/Build/file")).reviewPath, root + "App-b")
    }

    func testMixedCategoryDoesNotInheritMajorityRisk() {
        let engine = ClassificationEngine(homePath: home)
        let generated = engine.classify(observation(home + "/Library/Developer/Xcode/DerivedData/Project/a"))
        let archive = engine.classify(observation(home + "/Library/Developer/Xcode/Archives/2026/App.xcarchive/a"))
        let category = CategorySummary(category: .developerTools, measuredBytes: 100, logicalBytes: 100, items: [item(generated, bytes: 99), item(archive, bytes: 1)])
        XCTAssertEqual(category.decisionTitle, "Different kinds of data · review individually")
    }

    func testDownloadsWarnAboutOfflineAndUnavailableVersions() {
        let guidance = ClassificationEngine(homePath: home).classify(observation(home + "/.gradle/caches/modules/file")).guidance!
        XCTAssertEqual(guidance.kind, .downloads)
        XCTAssertTrue(guidance.consequence.contains("fail"))
        XCTAssertTrue(guidance.recovery.contains("availability"))
    }

    func testCloudAndPersistentDataDoNotPromiseRecoveryByReinstall() {
        let engine = ClassificationEngine(homePath: home)
        let cloud = engine.classify(observation(home + "/Library/CloudStorage/Provider/file")).guidance!
        XCTAssertTrue(cloud.consequence.contains("other devices"))
        XCTAssertTrue(cloud.nextStep.contains("not Delete"))
        let docker = engine.classify(observation(home + "/Library/Containers/com.docker.docker/Data/disk.raw")).guidance!
        XCTAssertTrue(docker.recovery.contains("does not restore"))
    }

    func testCreativeFilesRequireOriginalMediaAndGenericCacheRemainsConservative() {
        let engine = ClassificationEngine(homePath: home)
        let media = engine.classify(observation(home + "/Library/Application Support/Adobe/Common/Media Cache Files/video.cfa")).guidance!
        XCTAssertTrue(media.recovery.contains("original media"))
        let cache = engine.classify(observation(home + "/Library/Caches/Mystery/database")).guidance!
        XCTAssertEqual(cache.kind, .persistentData)
        XCTAssertTrue(cache.recovery.contains("cannot confirm"))
        let classification = engine.classify(observation(home + "/Library/Caches/Mystery/database"))
        XCTAssertEqual(classification.displayName, "Temporary Files from an Unidentified App")
        XCTAssertNil(classification.owner)
        XCTAssertTrue(classification.explanation.contains("could not be confirmed"))
    }

    func testVolumeSnapshotNamesFilesystemFreeSpaceTruthfully() {
        let volume = VolumeSnapshot(totalBytes: 1_000, freeBytes: 250)
        XCTAssertEqual(volume.freeBytes, 250)
        XCTAssertEqual(volume.usedBytes, 750)
    }

    func testKeepItemsNeverOfferFinderReveal() {
        let engine = ClassificationEngine(homePath: home)
        let keep = engine.classify(observation("/private/var/vm/swapfile0"))
        let review = engine.classify(observation(home + "/Library/Developer/Xcode/DerivedData/App/Build/file"))
        XCTAssertEqual(keep.risk, .expected)
        XCTAssertFalse(keep.allowsFinderReveal)
        XCTAssertTrue(review.allowsFinderReveal)
    }

    func testIssueTotalsAreIndependentOfSamples() async throws {
        let root = try fixture()
        let roots = (0..<300).map { ScanRoot(path: root.path + "/missing-\($0)", displayName: "Missing") }
        let report = try await MacFileSystemReader().scan(ScanRequest(roots: roots), onObservation: { _ in }, onProgress: { _ in })
        XCTAssertEqual(report.issues.count, 250)
        XCTAssertEqual(report.issueCount, 300)
        XCTAssertEqual(report.issueCounts[.unavailableRoot], 300)
    }

    func testAbsentOptionalRootDoesNotBecomePermissionFailure() async throws {
        let root = try fixture()
        let request = ScanRequest(roots: [ScanRoot(path: root.path + "/absent", displayName: "Optional", isOptional: true)])
        XCTAssertTrue(ScanRootNormalizer.normalize(request.roots)[0].isOptional)
        let report = try await MacFileSystemReader().scan(request, onObservation: { _ in }, onProgress: { _ in })
        XCTAssertEqual(report.issueCount, 0)
    }

    func testAllowlistedSimulatorMetadataAndWrongIdentifier() throws {
        let root = try fixture()
        let device = try makeDevice(root)
        let reader = SimulatorMetadataReader(homePath: root.path)
        let location = try observed(device)
        try plist(device, id: firstID)
        XCTAssertEqual(reader.read(location), SimulatorMetadata(name: "Test iPhone", runtime: "com.apple.CoreSimulator.SimRuntime.iOS-26-0"))
        try plist(device, id: secondID)
        XCTAssertNil(reader.read(location))
    }

    func testDeniedRootIsReportedWithoutDiscardingReadableFiles() async throws {
        let root = try fixture()
        let denied = root.appendingPathComponent("denied")
        let readable = root.appendingPathComponent("readable")
        try FileManager.default.createDirectory(at: denied, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(at: readable, withIntermediateDirectories: false)
        try Data(repeating: 1, count: 4096).write(to: readable.appendingPathComponent("sample"))
        XCTAssertEqual(chmod(denied.path, 0), 0)
        defer { chmod(denied.path, 0o700) }
        let report = try await MacFileSystemReader().scan(ScanRequest(roots: [
            ScanRoot(path: denied.path, displayName: "Denied", isOptional: true),
            ScanRoot(path: readable.path, displayName: "Readable")
        ]), onObservation: { _ in }, onProgress: { _ in })
        XCTAssertEqual(report.issueCounts[.permissionDenied], 1)
        XCTAssertEqual(report.filesObserved, 1)
        XCTAssertGreaterThan(report.measuredBytes, 0)
    }

    func testMetadataRejectsControlCharactersAndPreservesMissingRuntimeUncertainty() throws {
        let root = try fixture()
        let device = try makeDevice(root)
        let location = try observed(device)
        let reader = SimulatorMetadataReader(homePath: root.path)
        for name in ["spoof\nname", "spoof\u{202e}name"] {
            let data = try PropertyListSerialization.data(fromPropertyList: ["UDID": firstID, "name": name], format: .binary, options: 0)
            try data.write(to: device.appendingPathComponent("device.plist"))
            XCTAssertNil(reader.read(location))
        }
        let data = try PropertyListSerialization.data(fromPropertyList: ["UDID": firstID, "name": "Test device"], format: .xml, options: 0)
        try data.write(to: device.appendingPathComponent("device.plist"))
        XCTAssertEqual(reader.read(location)?.name, "Test device")
        XCTAssertNil(reader.read(location)?.runtime)
    }

    func testMetadataRejectsOversizeMalformedSymlinkAndOtherFolder() throws {
        let root = try fixture()
        let device = try makeDevice(root)
        let reader = SimulatorMetadataReader(homePath: root.path)
        let location = try observed(device)
        let metadata = device.appendingPathComponent("device.plist")
        try Data(repeating: 0, count: 65_537).write(to: metadata)
        XCTAssertNil(reader.read(location))
        try Data("not a plist".utf8).write(to: metadata)
        XCTAssertNil(reader.read(location))
        try FileManager.default.removeItem(at: metadata)
        let outside = root.appendingPathComponent("outside.plist")
        try Data("private work".utf8).write(to: outside)
        try FileManager.default.createSymbolicLink(at: metadata, withDestinationURL: outside)
        XCTAssertNil(reader.read(location))
        XCTAssertNil(reader.read(try observed(root)))
        XCTAssertEqual(try String(contentsOf: outside, encoding: .utf8), "private work")
    }

    func testIdentityAndAncestorSymlinkPreventSubstitution() throws {
        let root = try fixture()
        let device = try makeDevice(root)
        let location = try observed(device)
        let moved = device.deletingLastPathComponent().appendingPathComponent("moved")
        try FileManager.default.moveItem(at: device, to: moved)
        try FileManager.default.createDirectory(at: device, withIntermediateDirectories: false)
        XCTAssertNil(ObservedFileAccess.verifiedDescriptor(location))
        let link = root.appendingPathComponent("alias")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: device.deletingLastPathComponent())
        let substitute = ObservedLocation(path: link.appendingPathComponent(firstID).path, identity: try observed(device).identity)
        XCTAssertNil(ObservedFileAccess.verifiedDescriptor(substitute))
    }

    private func fixture() throws -> URL {
        let root = URL(fileURLWithPath: "/private/tmp").appendingPathComponent("sde-review-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        fixtures.append(root)
        return root
    }
    private func makeDevice(_ root: URL) throws -> URL {
        let device = root.appendingPathComponent("Library/Developer/CoreSimulator/Devices/" + firstID)
        try FileManager.default.createDirectory(at: device, withIntermediateDirectories: true)
        return device
    }
    private func observed(_ url: URL) throws -> ObservedLocation {
        var info = stat()
        XCTAssertEqual(lstat(url.path, &info), 0)
        return ObservedLocation(path: url.path, identity: ObservedFileAccess.identity(info))
    }
    private func plist(_ directory: URL, id: String) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: ["UDID": id, "name": "Test iPhone", "runtime": "com.apple.CoreSimulator.SimRuntime.iOS-26-0"], format: .binary, options: 0)
        try data.write(to: directory.appendingPathComponent("device.plist"))
    }
    private func observation(_ path: String, bytes: Int64 = 100, kind: StorageEntryKind = .file) -> StorageObservation {
        StorageObservation(path: path, rootPath: home + "/Library", logicalBytes: bytes, allocatedBytes: bytes,
            kind: kind, identity: FileIdentity(device: 1, inode: 1))
    }
    private func item(_ classification: Classification, bytes: Int64) -> ExplanationItem {
        ExplanationItem(id: classification.ruleID, classification: classification, measuredBytes: bytes, logicalBytes: bytes, fileCount: 1, technicalPaths: [])
    }
    private func summary() -> ScanSummary {
        ScanSummary(roots: [], filesObserved: 0, directoriesObserved: 0, symbolicLinksSkipped: 0, measuredBytes: 0, logicalBytes: 0, issues: [], duration: 0)
    }
}
