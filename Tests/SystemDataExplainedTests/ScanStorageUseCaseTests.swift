import XCTest
import SDEApplication
import SDEDomain

final class ScanStorageUseCaseTests: XCTestCase {
    func testPermissionIssueDoesNotDiscardObservedResults() async throws {
        let issue = ScanIssue(
            kind: .permissionDenied,
            path: "~/Library/Protected",
            message: "macOS kept this private."
        )
        let reader = FixtureReader(issue: issue)
        let useCase = ScanStorageUseCase(
            fileSystem: reader,
            volumeReader: FixtureVolumeReader(),
            classifier: FixtureClassifier()
        )

        let report = try await useCase.execute(ScanRequest(roots: [
            ScanRoot(path: "/fixture", displayName: "Fixture"),
            ScanRoot(path: "/fixture/nested", displayName: "Nested duplicate")
        ]))

        XCTAssertEqual(report.scan.summary.roots.map(\.path), ["/fixture"])
        XCTAssertEqual(report.scan.measuredBytes, 4_096)
        XCTAssertEqual(report.explainedBytes, 4_096)
        XCTAssertTrue(report.isPartial)
        XCTAssertEqual(report.scan.summary.issues, [issue])
    }
}

private struct FixtureReader: FileSystemReading {
    let issue: ScanIssue

    func scan(
        _ request: ScanRequest,
        onObservation: @escaping @Sendable (StorageObservation) -> Void,
        onProgress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> ScanSummary {
        let observation = StorageObservation(
            path: "/fixture/known.data",
            rootPath: "/fixture",
            logicalBytes: 4_096,
            allocatedBytes: 4_096,
            kind: .file
        )
        onObservation(observation)
        onProgress(ScanProgress(
            filesObserved: 1,
            directoriesObserved: 0,
            measuredBytes: 4_096,
            currentArea: "Fixture"
        ))
        return ScanSummary(
            roots: request.roots,
            filesObserved: 1,
            directoriesObserved: 0,
            symbolicLinksSkipped: 0,
            measuredBytes: 4_096,
            logicalBytes: 4_096,
            issues: [issue],
            duration: 0.1
        )
    }
}

private struct FixtureVolumeReader: VolumeReading {
    func snapshot(forPath path: String) async -> VolumeSnapshot? {
        VolumeSnapshot(totalBytes: 1_000_000, freeBytes: 500_000)
    }
}

private struct FixtureClassifier: StorageClassifying {
    func classify(_ observation: StorageObservation) -> Classification {
        Classification(
            ruleID: "fixture.known",
            category: .applicationData,
            displayName: "Fixture Data",
            explanation: "Known fixture data.",
            whyLarge: "The fixture has a known size.",
            risk: .expected,
            confidence: .high,
            level: .known,
            evidence: [StorageEvidence(kind: .path, value: "/fixture")]
        )
    }
}
