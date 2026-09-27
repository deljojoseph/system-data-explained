import Foundation
import SDEApplication
import SDEDomain

@MainActor
final class AppModel: ObservableObject {
    enum Phase: Equatable {
        case onboarding
        case working
        case results
        case failed
    }

    @Published private(set) var phase: Phase = .onboarding
    @Published private(set) var progress = ScanProgress(
        filesObserved: 0,
        directoriesObserved: 0,
        measuredBytes: 0,
        currentArea: "Preparing"
    )
    @Published private(set) var scanStartedAt: Date?
    @Published private(set) var isStopping = false
    @Published private(set) var report: ExplanationReport?
    @Published private(set) var errorMessage: String?

    private let useCase: ScanStorageUseCase
    private let request: ScanRequest
    private let locationRevealer: any LocationRevealing
    private var workTask: Task<Void, Never>?

    init(
        useCase: ScanStorageUseCase,
        request: ScanRequest,
        locationRevealer: any LocationRevealing,
        initialReport: ExplanationReport? = nil
    ) {
        self.useCase = useCase
        self.request = request
        self.locationRevealer = locationRevealer
        self.report = initialReport
        if initialReport != nil { self.phase = .results }
    }

    func startExplanation() {
        guard phase != .working else { return }

        errorMessage = nil
        isStopping = false
        progress = ScanProgress(
            filesObserved: 0,
            directoriesObserved: 0,
            measuredBytes: 0,
            currentArea: "Getting ready"
        )

        guard !request.roots.isEmpty else {
            errorMessage = "The app could not find any hidden storage locations this version understands."
            phase = .failed
            return
        }

        phase = .working
        scanStartedAt = Date()
        workTask = Task { [weak self] in
            guard let self else { return }
            do {
                let report = try await useCase.execute(request) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.progress = progress
                    }
                }
                guard !Task.isCancelled else {
                    self.scanStartedAt = nil
                    return
                }
                self.report = report
                self.scanStartedAt = nil
                self.isStopping = false
                self.phase = .results
            } catch let cancellation as ScanCancelledError {
                self.scanStartedAt = nil
                self.isStopping = false
                if cancellation.partialReport.scan.summary.filesObserved > 0 {
                    self.report = cancellation.partialReport
                }
                self.phase = self.report == nil ? .onboarding : .results
            } catch is CancellationError {
                self.scanStartedAt = nil
                self.isStopping = false
                self.phase = self.report == nil ? .onboarding : .results
            } catch {
                self.scanStartedAt = nil
                self.isStopping = false
                self.errorMessage = "The check could not finish. Nothing on your Mac was changed. \(error.localizedDescription)"
                self.phase = .failed
            }
            self.workTask = nil
        }
    }

    func stopExplanation() {
        guard phase == .working, !isStopping else { return }
        isStopping = true
        workTask?.cancel()
    }

    func returnToStart() {
        guard phase != .working else { return }
        phase = .onboarding
    }

    func revealInFinder(_ location: ObservedLocation) -> Bool {
        locationRevealer.reveal(location)
    }
}
