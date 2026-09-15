import SDEDomain

enum CloudAndOfficeRules {
    static let all: [PathRule] = [
        PathRule(
            id: "microsoft.outlook.data",
            matcher: .homePrefix("Library/Group Containers/UBF8T346G9.Office/Outlook"),
            category: .applicationData,
            displayName: "Microsoft Outlook",
            owner: "Microsoft Outlook",
            explanation: "Local mail databases, search indexes, and attachments owned by Outlook.",
            whyLarge: "Large mailboxes and downloaded attachments can create a substantial local database.",
            risk: .review
        ),
        PathRule(
            id: "microsoft.office.shared",
            matcher: .homePrefix("Library/Group Containers/UBF8T346G9.Office"),
            category: .applicationData,
            displayName: "Microsoft Office Data",
            owner: "Microsoft Office",
            explanation: "Shared settings, databases, and support files used by Microsoft Office applications.",
            whyLarge: "Several Office applications may share local databases, templates, and document support data.",
            risk: .expected
        ),
        PathRule(
            id: "cloud.dropbox.support",
            matcher: .homePrefix("Library/Application Support/Dropbox"),
            category: .cloudData,
            displayName: "Dropbox Data",
            owner: "Dropbox",
            explanation: "Local indexes, settings, and working data used by Dropbox.",
            whyLarge: "Local indexes and files selected for offline use can grow with the Dropbox account.",
            risk: .expected
        ),
        PathRule(
            id: "cloud.google-drive.support",
            matcher: .homePrefix("Library/Application Support/Google/DriveFS"),
            category: .cloudData,
            displayName: "Google Drive Data",
            owner: "Google Drive",
            explanation: "Local cache, indexes, and working data used by Google Drive for desktop.",
            whyLarge: "Offline files and streamed-file caches can retain substantial local data.",
            risk: .expected
        ),
        PathRule(
            id: "cloud.onedrive.support",
            matcher: .homePrefix("Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite"),
            category: .cloudData,
            displayName: "OneDrive Data",
            owner: "Microsoft OneDrive",
            explanation: "Local indexes, settings, and working data used by OneDrive.",
            whyLarge: "Files kept available offline and synchronization databases consume local storage.",
            risk: .expected
        ),
        PathRule(
            id: "office.slack.data",
            matcher: .homePrefix("Library/Containers/com.tinyspeck.slackmacgap"),
            category: .applicationData,
            displayName: "Slack Data",
            owner: "Slack",
            explanation: "Local application data, cached media, and databases used by Slack.",
            whyLarge: "Busy workspaces and shared media can accumulate local working data.",
            risk: .review
        )
    ]
}
