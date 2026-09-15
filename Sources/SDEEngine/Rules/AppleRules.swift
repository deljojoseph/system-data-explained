import SDEDomain

enum AppleRules {
    static let all: [PathRule] = [
        PathRule(
            id: "apple.mobile-device-backups",
            matcher: .homePrefix("Library/Application Support/MobileSync/Backup"),
            category: .deviceBackups,
            displayName: "iPhone & iPad Backups",
            owner: "Apple Devices",
            explanation: "Local device backups stored on this Mac.",
            whyLarge: "A backup can contain most of a device's settings and local data, and multiple backups may be present.",
            risk: .review
        ),
        PathRule(
            id: "apple.mobile-software-updates",
            matcher: .homePrefix("Library/iTunes/iPhone Software Updates"),
            category: .deviceBackups,
            displayName: "Device Software Updates",
            owner: "Apple Devices",
            explanation: "Downloaded iPhone or iPad system-update packages.",
            whyLarge: "Complete device software images are several gigabytes each.",
            risk: .rebuildable
        ),
        PathRule(
            id: "apple.messages.attachments",
            matcher: .homePrefix("Library/Messages/Attachments"),
            category: .messagesAndMail,
            displayName: "Messages Attachments",
            owner: "Messages",
            explanation: "Photos, videos, and files stored by Messages on this Mac.",
            whyLarge: "Conversation media accumulates over time, especially videos and shared photo libraries.",
            risk: .review
        ),
        PathRule(
            id: "apple.messages.data",
            matcher: .homePrefix("Library/Messages"),
            category: .messagesAndMail,
            displayName: "Messages Data",
            owner: "Messages",
            explanation: "Local databases and supporting data used by Messages.",
            whyLarge: "Long conversation histories and synced data can grow gradually.",
            risk: .expected
        ),
        PathRule(
            id: "apple.mail.data",
            matcher: .homePrefix("Library/Mail"),
            category: .messagesAndMail,
            displayName: "Mail Data",
            owner: "Mail",
            explanation: "Messages and attachments kept locally by Mail.",
            whyLarge: "Multiple accounts, long histories, and downloaded attachments can require substantial local storage.",
            risk: .review
        ),
        PathRule(
            id: "apple.icloud.mobile-documents",
            matcher: .homePrefix("Library/Mobile Documents"),
            category: .cloudData,
            displayName: "iCloud Local Data",
            owner: "iCloud",
            explanation: "Local working copies and support data for apps that use iCloud.",
            whyLarge: "Cloud files may remain downloaded locally for availability and performance.",
            risk: .expected
        ),
        PathRule(
            id: "apple.safari.caches",
            matcher: .homePrefix("Library/Caches/com.apple.Safari"),
            category: .cachesAndLogs,
            displayName: "Safari Caches",
            owner: "Safari",
            explanation: "Temporary website data used to make browsing faster.",
            whyLarge: "Media-heavy sites and long browsing histories can grow the cache.",
            risk: .rebuildable
        ),
        PathRule(
            id: "apple.user-logs",
            matcher: .homePrefix("Library/Logs"),
            category: .cachesAndLogs,
            displayName: "Application Logs",
            explanation: "Diagnostic records written by applications for troubleshooting.",
            whyLarge: "A frequently running or malfunctioning app can produce many log files over time.",
            risk: .review
        ),
        PathRule(
            id: "apple.webkit-data",
            matcher: .homePrefix("Library/WebKit"),
            category: .applicationData,
            displayName: "Web Content Used by Apps",
            owner: "Apps with web content",
            explanation: "Website data kept by apps that display web pages inside the app.",
            whyLarge: "Apps can save downloaded page data, images, sign-in state, and offline content here.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "apple.http-storage",
            matcher: .homePrefix("Library/HTTPStorages"),
            category: .applicationData,
            displayName: "Website Data Used by Apps",
            owner: "Apps with online features",
            explanation: "Downloaded website data and connection storage kept by apps.",
            whyLarge: "Apps that load a lot of online content can build up local website data.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "apple.preferences",
            matcher: .homePrefix("Library/Preferences"),
            category: .applicationData,
            displayName: "App Settings",
            explanation: "Small files that remember how apps are configured.",
            whyLarge: "This area normally stays small, but many installed apps leave settings behind.",
            risk: .expected,
            confidence: .medium
        ),
        PathRule(
            id: "apple.saved-application-state",
            matcher: .homePrefix("Library/Saved Application State"),
            category: .applicationData,
            displayName: "Saved App Windows",
            explanation: "Files that help apps restore their windows after reopening.",
            whyLarge: "Many apps can keep separate window-restoration data.",
            risk: .rebuildable,
            confidence: .medium
        ),
        PathRule(
            id: "apple.metadata-indexes",
            matcher: .homePrefix("Library/Metadata"),
            category: .systemManaged,
            displayName: "Search & App Indexes",
            owner: "macOS and Applications",
            explanation: "Indexes that help macOS and apps find information quickly.",
            whyLarge: "Indexes grow as more files, mail, photos, and app data become searchable.",
            risk: .rebuildable,
            confidence: .medium
        ),
        PathRule(
            id: "apple.autosave-information",
            matcher: .homePrefix("Library/Autosave Information"),
            category: .applicationData,
            displayName: "Unsaved Work Recovery",
            explanation: "Recovery copies that can help apps restore work after a crash or restart.",
            whyLarge: "Apps may keep recovery data for several open or recently edited documents.",
            risk: .expected,
            confidence: .medium
        )
    ]
}
