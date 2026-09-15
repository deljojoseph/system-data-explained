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
        workTask = Task { [weak self] in
            guard let self else { return }
            do {
                let report = try await useCase.execute(request) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.progress = progress
                    }
                }
                guard !Task.isCancelled else { return }
                self.report = report
                self.phase = .results
            } catch is CancellationError {
                self.phase = self.report == nil ? .onboarding : .results
            } catch {
                self.errorMessage = "The check could not finish. Nothing on your Mac was changed. \(error.localizedDescription)"
                self.phase = .failed
            }
            self.workTask = nil
        }
    }

    func stopExplanation() {
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
