import XCTest
import SDEApplication
import SDEDomain

final class ReportAndRootTests: XCTestCase {
    func testNestedAndDuplicateRootsAreRemoved() {
        let roots = [
            ScanRoot(path: "/Users/test/Library/Developer", displayName: "Developer"),
            ScanRoot(path: "/Users/test/Library", displayName: "Library"),
            ScanRoot(path: "/Users/test/Library", displayName: "Library duplicate"),
            ScanRoot(path: "/private/var", displayName: "Runtime")
        ]

        let normalized = ScanRootNormalizer.normalize(roots)

        XCTAssertEqual(normalized.map(\.path), ["/Users/test/Library", "/private/var"])
    }

    func testReportSeparatesKnownGenericAndUnknownCoverage() {
        let builder = BuildReportUseCase()
        builder.observe(observation(bytes: 60), as: classification(id: "known", level: .known, category: .developerTools))
        builder.observe(observation(bytes: 30), as: classification(id: "generic", level: .ownerKnown, category: .applicationData))
        builder.observe(observation(bytes: 10), as: classification(id: "unknown", level: .unknown, category: .unclassified))

        let summary = ScanSummary(
            roots: [ScanRoot(path: "/test", displayName: "Test")],
            filesObserved: 3,
            directoriesObserved: 1,
            symbolicLinksSkipped: 0,
            measuredBytes: 100,
            logicalBytes: 100,
            issues: [],
            duration: 1
        )
        let report = builder.build(summary: summary, volume: nil)

        XCTAssertEqual(report.scan.measuredBytes, 100)
        XCTAssertEqual(report.explainedBytes, 60)
        XCTAssertEqual(report.genericBytes, 30)
        XCTAssertEqual(report.unclassifiedBytes, 10)
        XCTAssertEqual(report.explanationCoverage, 0.6, accuracy: 0.0001)
        XCTAssertFalse(report.isPartial)
    }

    func testAllocatedSizeIsPreferredWithoutHidingLogicalSize() {
        let builder = BuildReportUseCase()
        let observation = StorageObservation(
            path: "/test/sparse-image",
            rootPath: "/test",
            logicalBytes: 1_000,
            allocatedBytes: 250,
            kind: .file
        )
        builder.observe(observation, as: classification(id: "item", level: .known, category: .virtualMachines))

        let summary = ScanSummary(
            roots: [],
            filesObserved: 1,
            directoriesObserved: 0,
            symbolicLinksSkipped: 0,
            measuredBytes: 250,
            logicalBytes: 1_000,
            issues: [],
            duration: 0
        )
        let report = builder.build(summary: summary, volume: nil)

        XCTAssertEqual(report.scan.measuredBytes, 250)
        XCTAssertEqual(report.scan.logicalBytes, 1_000)
        XCTAssertEqual(report.categories.first?.items.first?.measuredBytes, 250)
        XCTAssertEqual(report.categories.first?.items.first?.logicalBytes, 1_000)
    }

    func testIssuesMarkAReportPartialWithoutChangingMeasuredTotals() {
        let builder = BuildReportUseCase()
        builder.observe(observation(bytes: 42), as: classification(id: "known", level: .known, category: .systemManaged))
        let issue = ScanIssue(kind: .permissionDenied, path: "~/Library/Mail", message: "Private")
        let summary = ScanSummary(
            roots: [],
            filesObserved: 1,
            directoriesObserved: 0,
            symbolicLinksSkipped: 0,
            measuredBytes: 42,
            logicalBytes: 42,
            issues: [issue],
            duration: 0
        )

        let report = builder.build(summary: summary, volume: nil)

        XCTAssertTrue(report.isPartial)
        XCTAssertEqual(report.scan.measuredBytes, 42)
        XCTAssertEqual(report.unclassifiedBytes, 0)
    }

    func testSameRuleAtDifferentLocationsRemainsSeparatelyActionable() {
        let builder = BuildReportUseCase()
        builder.observe(
            observation(path: "/test/one/file", bytes: 30),
            as: classification(id: "unknown", level: .unknown, category: .unclassified, path: "/test/one")
        )
        builder.observe(
            observation(path: "/test/two/file", bytes: 70),
            as: classification(id: "unknown", level: .unknown, category: .unclassified, path: "/test/two")
        )

        let summary = ScanSummary(
            roots: [ScanRoot(path: "/test", displayName: "Test")],
            filesObserved: 2,
            directoriesObserved: 2,
            symbolicLinksSkipped: 0,
            measuredBytes: 100,
            logicalBytes: 100,
            issues: [],
            duration: 1
        )
        let report = builder.build(summary: summary, volume: nil)
        let items = report.categories.first?.items ?? []

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(Set(items.flatMap(\.technicalPaths)), ["/test/one", "/test/two"])
    }

    private func observation(bytes: Int64) -> StorageObservation {
        observation(path: "/test/file", bytes: bytes)
    }

    private func observation(path: String, bytes: Int64) -> StorageObservation {
        StorageObservation(
            path: path,
            rootPath: "/test",
            logicalBytes: bytes,
            allocatedBytes: bytes,
            kind: .file
        )
    }

    private func classification(
        id: String,
        level: ExplanationLevel,
        category: StorageCategory,
        path: String = "/test"
    ) -> Classification {
        Classification(
            ruleID: id,
            category: category,
            displayName: id,
            explanation: "Explanation",
            whyLarge: "Reason",
            risk: level == .unknown ? .unknown : .review,
            confidence: level == .known ? .high : (level == .ownerKnown ? .medium : .low),
            level: level,
            evidence: [StorageEvidence(kind: .path, value: path)]
        )
    }
}
