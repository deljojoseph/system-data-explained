import SwiftUI
import SDEApplication
import SDEEngine
import SDEInfrastructure

@main
struct SystemDataExplainedApp: App {
    @StateObject private var model: AppModel

    init() {
        let homePath = MacEnvironment.homePath
        let appIdentities = InstalledAppReader().readInstalledApplications(homePath: homePath)
        let classifier = ClassificationEngine(homePath: homePath, appIdentities: appIdentities)
        let useCase = ScanStorageUseCase(
            fileSystem: MacFileSystemReader(),
            volumeReader: MacVolumeReader(),
            classifier: classifier,
            simulatorReader: SimulatorMetadataReader(homePath: homePath)
        )
        let request = DefaultScanScope(homePath: homePath).makeRequest()
        _model = StateObject(wrappedValue: AppModel(
            useCase: useCase,
            request: request,
            locationRevealer: FinderLocationRevealer(homePath: homePath)
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .frame(minWidth: 900, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 820)
        .commands {
            SupportCommands()
        }

        Window("System Data Explained Help", id: "system-data-help") {
            SystemDataHelpView()
        }
        .defaultSize(width: 600, height: 620)
        .windowResizability(.contentMinSize)
        .defaultPosition(.center)
    }
}
