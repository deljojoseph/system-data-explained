import XCTest
import SwiftUI
import AppKit
import SDEDomain
import SDEApplication
import SDEEngine
@testable import SystemDataExplained

final class PresentationTests: XCTestCase {
    @MainActor
    func testBeforeAfterExampleOrderAssetsAndCompactLayout() throws {
        XCTAssertEqual(SystemDataExample.allCases, [.before, .after])
        XCTAssertEqual(SystemDataExample.before.size, "130.03 GB")
        XCTAssertEqual(SystemDataExample.after.size, "75.34 GB")
        for example in SystemDataExample.allCases {
            let image = try XCTUnwrap(example.image)
            XCTAssertGreaterThan(image.size.width, image.size.height * 3)
        }
        let panel = SystemDataSample().frame(width: 370).background(.white)
        let renderer = ImageRenderer(content: panel)
        let image = try XCTUnwrap(renderer.nsImage)
        XCTAssertLessThanOrEqual(image.size.height, 400)
        try render(panel, name: "before-after")
        try render(panel.environment(\.readingScale, 2), name: "before-after-200")
    }

    @MainActor
    func testRenderGuidanceAtStandardAndLargestText() throws {
        let path = "/Users/example/Library/Developer/CoreSimulator/Devices/11111111-1111-1111-1111-111111111111/data/file"
        let classification = ClassificationEngine(homePath: "/Users/example").classify(StorageObservation(
            path: path, rootPath: "/Users/example/Library", logicalBytes: 0, allocatedBytes: 0, kind: .file))
        let item = ExplanationItem(id: "fixture", classification: classification, measuredBytes: 12_000_000_000,
            logicalBytes: 12_000_000_000, fileCount: 10, technicalPaths: [],
            location: ObservedLocation(path: classification.reviewPath!, identity: FileIdentity(device: 1, inode: 1)),
            simulator: SimulatorMetadata(name: "iPhone 16 Pro", runtime: "iOS 26.0"))
        for scale in [1.0, 2.0] {
            try render(InlineItemDetail(item: item, revealInFinder: { _ in })
                .environment(\.readingScale, scale).padding(24).frame(width: 820).background(.white),
                name: "guidance-\(Int(scale * 100))")
        }
        try render(WorkingState(progress: ScanProgress(filesObserved: 987654, directoriesObserved: 123456,
            measuredBytes: 24_800_000_000, currentArea: "not displayed"))
            .padding(24).frame(width: 1000).background(.white), name: "working")
        try render(OpeningState(begin: {}).padding(24).frame(width: 1000).background(.white), name: "opening")
    }

    @MainActor
    func testModelRetainsResultsWhenRecheckIsCancelled() async throws {
        let report = BuildReportUseCase().build(summary: ScanSummary(roots: [], filesObserved: 0,
            directoriesObserved: 0, symbolicLinksSkipped: 0, measuredBytes: 0, logicalBytes: 0, issues: [], duration: 0), volume: nil)
        let model = AppModel(useCase: ScanStorageUseCase(fileSystem: WaitingReader(), volumeReader: NoVolume(),
            classifier: ClassificationEngine(homePath: "/test")),
            request: ScanRequest(roots: [ScanRoot(path: "/test", displayName: "Fixture")]),
            locationRevealer: NoReveal(), initialReport: report)
        model.startExplanation()
        XCTAssertEqual(model.phase, .working)
        model.stopExplanation()
        for _ in 0..<100 { if model.phase != .working { break }; await Task.yield() }
        XCTAssertEqual(model.phase, .results)
        XCTAssertEqual(model.report, report)
    }

    @MainActor
    func testRenderResultsAsFixedCockpitAtStandardTextSize() throws {
        let classification = Classification(
            ruleID: "fixture.app-data", category: .applicationData, displayName: "Example App",
            owner: "Example App", explanation: "Files kept by this app.", whyLarge: "Saved work can grow.",
            risk: .review, confidence: .high, level: .known,
            evidence: [StorageEvidence(kind: .path, value: "~/Library/Application Support/Example")],
            reviewPath: "~/Library/Application Support/Example",
            guidance: ReviewGuidance(kind: .persistentData, summary: "Settings and saved work used by Example App.",
                consequence: "The app may stop working or lose saved work.",
                recovery: "A verified backup is needed for work that exists only here.",
                nextStep: "Open Example App and review its storage settings first."))
        let item = ExplanationItem(id: "fixture", classification: classification, measuredBytes: 28_000_000_000,
            logicalBytes: 28_000_000_000, fileCount: 1, technicalPaths: [])
        let report = ExplanationReport(createdAt: Date(), scan: ScanReport(summary: ScanSummary(roots: [],
            filesObserved: 1, directoriesObserved: 1, symbolicLinksSkipped: 0, measuredBytes: 28_000_000_000,
            logicalBytes: 28_000_000_000, issues: [], duration: 1),
            volume: VolumeSnapshot(totalBytes: 500_000_000_000, freeBytes: 80_000_000_000),
            measuredBytes: 28_000_000_000, logicalBytes: 28_000_000_000),
            categories: [CategorySummary(category: .applicationData, measuredBytes: 28_000_000_000,
                logicalBytes: 28_000_000_000, items: [item])], explainedBytes: 28_000_000_000,
            genericBytes: 0, unclassifiedBytes: 0)
        let model = AppModel(useCase: ScanStorageUseCase(fileSystem: WaitingReader(), volumeReader: NoVolume(),
            classifier: ClassificationEngine(homePath: "/test")), request: ScanRequest(roots: []),
            locationRevealer: NoReveal(), initialReport: report)
        try render(CockpitView(model: model).frame(width: 1000, height: 700), name: "results-cockpit")
        try render(CockpitView(model: model).frame(width: 1000, height: 700), name: "results-cockpit-dark", colorScheme: .dark)
    }

    func testSupportEmailContainsOnlyBasicNonSensitiveContext() throws {
        let details = SupportDetails(
            appVersion: "1.2",
            build: "7",
            macOSVersion: "27.0.0",
            macModel: "MacBookAir15,2",
            processor: "Apple silicon"
        )
        let url = try XCTUnwrap(SupportEmail.url(details: details))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, SupportEmail.address)
        XCTAssertEqual(query["subject"], "System Data Explained support")
        XCTAssertTrue(query["body"]?.contains("System Data Explained: 1.2 (7)") == true)
        XCTAssertTrue(query["body"]?.contains("MacBookAir15,2") == true)
        XCTAssertFalse(query["body"]?.contains("/Users/") == true)
    }

    @MainActor
    func testRenderHelpAtStandardAndLargestText() throws {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: "readingScale")
        defer {
            if let previous {
                defaults.set(previous, forKey: "readingScale")
            } else {
                defaults.removeObject(forKey: "readingScale")
            }
        }

        defaults.set(1.0, forKey: "readingScale")
        try render(SystemDataHelpView().background(.white), name: "help")
        defaults.set(2.0, forKey: "readingScale")
        try render(SystemDataHelpView().background(.white), name: "help-200")
    }

    @MainActor
    private func render<V: View>(_ view: V, name: String, colorScheme: ColorScheme = .light) throws {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, colorScheme))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.nsImage)
        let tiff = try XCTUnwrap(image.tiffRepresentation)
        let rep = try XCTUnwrap(NSBitmapImageRep(data: tiff))
        let png = try XCTUnwrap(rep.representation(using: .png, properties: [:]))
        let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent(".build/visual-checks")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try png.write(to: directory.appendingPathComponent(name + ".png"))
        XCTAssertGreaterThan(image.size.height, 200)
    }
}

private struct WaitingReader: FileSystemReading {
    func scan(_ request: ScanRequest, onObservation: @escaping @Sendable (StorageObservation) -> Void,
              onProgress: @escaping @Sendable (ScanProgress) -> Void) async throws -> ScanSummary {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw CancellationError()
    }
}
private struct NoVolume: VolumeReading { func snapshot(forPath path: String) async -> VolumeSnapshot? { nil } }
@MainActor private struct NoReveal: LocationRevealing { func reveal(_ location: ObservedLocation) -> Bool { false } }
