public enum StorageCategory: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case developerTools
    case deviceBackups
    case creativeData
    case applicationData
    case cloudData
    case messagesAndMail
    case cachesAndLogs
    case virtualMachines
    case systemManaged
    case packagesAndArchives
    case unclassified

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .developerTools: "Developer Tools"
        case .deviceBackups: "iPhone & iPad Backups"
        case .creativeData: "Creative App Files"
        case .applicationData: "Apps & Their Data"
        case .cloudData: "Cloud Files on This Mac"
        case .messagesAndMail: "Messages & Mail"
        case .cachesAndLogs: "Temporary App Files & Logs"
        case .virtualMachines: "Virtual Computers"
        case .systemManaged: "Files macOS Manages"
        case .packagesAndArchives: "Installers & Archives"
        case .unclassified: "Needs a Closer Look"
        }
    }

    public var summary: String {
        switch self {
        case .developerTools: "Files created by developer tools, simulators, build systems, and package managers."
        case .deviceBackups: "Local backups and support files for iPhone and iPad devices."
        case .creativeData: "Project helpers, previews, media caches, and downloaded content used by creative apps."
        case .applicationData: "Settings, saved work, downloads, and databases. Changing these folders directly can disrupt an app or lose data."
        case .cloudData: "Cloud files and working copies that are also taking space on this Mac."
        case .messagesAndMail: "Messages, attachments, and local mail data."
        case .cachesAndLogs: "Files apps can often make again, plus records used when something goes wrong."
        case .virtualMachines: "Whole virtual computers, including their operating systems and files."
        case .systemManaged: "Files macOS uses while your Mac is running."
        case .packagesAndArchives: "App installers, disk images, and compressed downloads."
        case .unclassified: "Storage the app measured but does not understand well enough to recommend changing."
        }
    }

    public var symbolName: String {
        switch self {
        case .developerTools: "hammer"
        case .deviceBackups: "iphone.and.arrow.forward"
        case .creativeData: "paintpalette"
        case .applicationData: "app.dashed"
        case .cloudData: "cloud"
        case .messagesAndMail: "message"
        case .cachesAndLogs: "clock.arrow.circlepath"
        case .virtualMachines: "rectangle.3.group"
        case .systemManaged: "gearshape.2"
        case .packagesAndArchives: "shippingbox"
        case .unclassified: "questionmark.folder"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .developerTools: 0
        case .deviceBackups: 1
        case .creativeData: 2
        case .applicationData: 3
        case .cloudData: 4
        case .messagesAndMail: 5
        case .cachesAndLogs: 6
        case .virtualMachines: 7
        case .systemManaged: 8
        case .packagesAndArchives: 9
        case .unclassified: 10
        }
    }
}
