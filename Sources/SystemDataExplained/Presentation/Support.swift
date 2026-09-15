import AppKit
import Darwin
import SwiftUI

struct SupportDetails: Equatable {
    let appVersion: String
    let build: String
    let macOSVersion: String
    let macModel: String
    let processor: String

    static var current: SupportDetails {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = info["CFBundleVersion"] as? String ?? "Unknown"
        let os = ProcessInfo.processInfo.operatingSystemVersion

        return SupportDetails(
            appVersion: version,
            build: build,
            macOSVersion: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            macModel: machineModel(),
            processor: processorName
        )
    }

    private static var processorName: String {
        #if arch(arm64)
        return "Apple silicon"
        #elseif arch(x86_64)
        return "Intel"
        #else
        return "Unknown"
        #endif
    }

    private static func machineModel() -> String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 1 else {
            return "Unknown"
        }

        var value = [CChar](repeating: 0, count: size)
        let result = value.withUnsafeMutableBufferPointer { buffer in
            sysctlbyname("hw.model", buffer.baseAddress, &size, nil, 0)
        }
        guard result == 0 else { return "Unknown" }
        return String(cString: value)
    }
}

enum SupportEmail {
    static let address = "dj@deljojoseph.com"

    static func url(details: SupportDetails) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: "System Data Explained support"),
            URLQueryItem(name: "body", value: body(details: details))
        ]
        return components.url
    }

    static func body(details: SupportDetails) -> String {
        """
        Hi DJ,

        What happened?


        App details
        System Data Explained: \(details.appVersion) (\(details.build))
        macOS: \(details.macOSVersion)
        Mac: \(details.macModel)
        Processor: \(details.processor)

        Please do not include private filenames or personal information.
        """
    }
}

enum DevelopmentSupport {
    static let url = URL(string: "https://deljojoseph.com/mac-system-data/checkout")!

    @MainActor
    static func open() {
        NSWorkspace.shared.open(url)
    }
}

@MainActor
enum SupportContact {
    static func composeEmail() {
        guard let url = SupportEmail.url(details: .current), NSWorkspace.shared.open(url) else {
            showCopyFallback()
            return
        }
    }

    private static func showCopyFallback() {
        let alert = NSAlert()
        alert.messageText = "Email could not be opened"
        alert.informativeText = "You can contact support at \(SupportEmail.address)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Email Address")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(SupportEmail.address, forType: .string)
        }
    }
}

struct SystemDataHelpView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @AppStorage("readingScale") private var readingScale = 1.0

    var body: some View {
        let details = SupportDetails.current

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("System Data Explained Help")
                        .sdeFont(17, weight: .medium)
                        .foregroundStyle(Color.sdeInk)
                    Text("Understand the result without becoming a storage expert.")
                        .sdeFont(13)
                        .foregroundStyle(Color.sdeMuted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    helpSection("How it works", icon: "questionmark.circle") {
                        Text("The app measures storage information on this Mac, groups what it recognizes, and explains what deserves attention.")
                    }

                    helpSection("What the labels mean", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 8) {
                            label("Keep", "The app or macOS likely relies on it.")
                            label("Check first", "Its value depends on your apps, work, or history.")
                            label("Recreatable", "Its owner can usually make or download it again.")
                            label("Not understood", "There is not enough evidence to guide removal.")
                        }
                    }

                    helpSection("Your privacy", icon: "hand.raised") {
                        Text("The app cannot delete your files. Everything is checked locally. No filenames or storage information leave your Mac.")
                    }

                    helpSection("Folder access", icon: "folder.badge.questionmark") {
                        Text("macOS may ask for access to some folders. You may decline. Those locations may be missing from the result.")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
            }
            .scrollIndicators(.automatic)

            VStack(spacing: 4) {
                HStack {
                    Button("Close") { dismissWindow(id: "system-data-help") }
                        .keyboardShortcut(.cancelAction)
                        .sdeFont(13)
                        .frame(minHeight: 44)
                    Spacer()
                    Button("Contact Support") { SupportContact.composeEmail() }
                        .keyboardShortcut(.defaultAction)
                        .sdeFont(13)
                        .frame(minHeight: 44)
                }

                Text("Version \(details.appVersion) (\(details.build))")
                    .sdeFont(12)
                    .foregroundStyle(Color.sdeMuted)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 520, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.readingScale, min(2, max(1, readingScale)))
    }

    private func helpSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .sdeFont(15)
                .foregroundStyle(Color.sdeBlue)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .sdeFont(14, weight: .medium)
                    .foregroundStyle(Color.sdeInk)
                content()
                    .sdeFont(13)
                    .foregroundStyle(Color.sdeMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func label(_ name: String, _ explanation: String) -> some View {
        Text("**\(name):** \(explanation)")
    }
}

struct SupportCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("System Data Explained Help") {
                openWindow(id: "system-data-help")
            }
            .keyboardShortcut("?", modifiers: .command)

            Divider()

            Button("Contact Support…") {
                SupportContact.composeEmail()
            }

            Button("Support Development…") {
                DevelopmentSupport.open()
            }
        }
    }
}
