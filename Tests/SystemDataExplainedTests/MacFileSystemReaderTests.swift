import Foundation
import XCTest
import SDEDomain
import SDEInfrastructure

final class MacFileSystemReaderTests: XCTestCase {
    private final class LockedBox<Value>: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: Value

        init(_ value: Value) {
            storage = value
        }

        func withValue(_ body: (inout Value) -> Void) {
            lock.lock()
            defer { lock.unlock() }
            body(&storage)
        }

        var value: Value {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }
    }

    private var fixtureDirectories: [URL] = []

    override func tearDownWithError() throws {
        for directory in fixtureDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        fixtureDirectories.removeAll()
    }

    func testScannerNeverFollowsSymbolicLinks() async throws {
        let root = try makeFixtureDirectory(name: "scan-root")
        let outside = try makeFixtureDirectory(name: "outside-root")
        let outsideFile = outside.appendingPathComponent("large.data")
        try Data(repeating: 7, count: 128 * 1_024).write(to: outsideFile)

        let link = root.appendingPathComponent("linked-folder")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)

        let observations = LockedBox<[StorageObservation]>([])
        let summary = try await MacFileSystemReader().scan(
            ScanRequest(roots: [ScanRoot(path: root.path, displayName: "Fixture")]),
            onObservation: { observation in
                observations.withValue { $0.append(observation) }
            },
            onProgress: { _ in }
        )

        XCTAssertEqual(summary.symbolicLinksSkipped, 1)
        XCTAssertEqual(summary.filesObserved, 0)
        XCTAssertTrue(observations.value.allSatisfy { $0.kind == .directory })
        XCTAssertEqual(summary.measuredBytes, 0)
    }

    func testUnavailableRootBecomesRecoverableIssue() async throws {
        let path = NSTemporaryDirectory() + "/sde-does-not-exist-\(UUID().uuidString)"
        let summary = try await MacFileSystemReader().scan(
            ScanRequest(roots: [ScanRoot(path: path, displayName: "Missing")]),
            onObservation: { _ in XCTFail("No observation expected") },
            onProgress: { _ in }
        )

        XCTAssertEqual(summary.issues.first?.kind, .unavailableRoot)
        XCTAssertEqual(summary.filesObserved, 0)
    }

    func testScannerReportsLogicalAndAllocatedSizes() async throws {
        let root = try makeFixtureDirectory(name: "size-root")
        let file = root.appendingPathComponent("sample.bin")
        try Data(repeating: 1, count: 8_192).write(to: file)

        let observed = LockedBox<StorageObservation?>(nil)
        let summary = try await MacFileSystemReader().scan(
            ScanRequest(roots: [ScanRoot(path: root.path, displayName: "Fixture")]),
            onObservation: { value in
                observed.withValue { $0 = value }
            },
            onProgress: { _ in }
        )

        XCTAssertEqual(summary.filesObserved, 1)
        XCTAssertEqual(observed.value?.logicalBytes, 8_192)
        XCTAssertNotNil(observed.value?.allocatedBytes)
        XCTAssertGreaterThan(summary.measuredBytes, 0)
    }

    func testScannerRespondsToCancellation() async throws {
        let root = try makeFixtureDirectory(name: "cancellation-root")
        for index in 0..<1_000 {
            let directory = root.appendingPathComponent("folder-\(index)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        }

        let task = Task {
            try await MacFileSystemReader().scan(
                ScanRequest(roots: [ScanRoot(path: root.path, displayName: "Fixture")]),
                onObservation: { _ in },
                onProgress: { _ in }
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("A cancelled scan should throw CancellationError")
        } catch is CancellationError {
            // Expected: cancellation is cooperative and leaves the fixture untouched.
        }
    }

    private func makeFixtureDirectory(name: String) throws -> URL {
        let directory = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("sde-tests-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fixtureDirectories.append(directory)
        return directory
    }
}
