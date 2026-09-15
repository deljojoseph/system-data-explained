import SDEDomain

enum ProductivityRules {
    static let all: [PathRule] = [
        PathRule(
            id: "productivity.vscode.data",
            matcher: .homePrefix("Library/Application Support/Code"),
            category: .developerTools,
            displayName: "Visual Studio Code Data",
            owner: "Visual Studio Code",
            explanation: "Editor settings, workspace state, extensions, and files Visual Studio Code keeps locally.",
            whyLarge: "Extensions, workspace history, and local editor databases grow across projects.",
            risk: .review
        ),
        PathRule(
            id: "productivity.vscode-extensions",
            matcher: .homePrefix(".vscode/extensions"),
            category: .developerTools,
            displayName: "Visual Studio Code Extensions",
            owner: "Visual Studio Code",
            explanation: "Extra language and development tools installed in Visual Studio Code.",
            whyLarge: "Each extension ships code and may keep multiple installed versions.",
            nextStep: "Open Visual Studio Code → Extensions and uninstall extensions there. Use Finder only to confirm where they are stored.",
            risk: .review
        ),
        PathRule(
            id: "productivity.cursor.data",
            matcher: .homePrefix("Library/Application Support/Cursor"),
            category: .developerTools,
            displayName: "Cursor Editor Data",
            owner: "Cursor",
            explanation: "Editor settings, extensions, workspace state, and local working data used by Cursor.",
            whyLarge: "Extensions and workspace history grow as more projects are opened.",
            risk: .review
        ),
        PathRule(
            id: "productivity.jetbrains.caches",
            matcher: .homePrefix("Library/Caches/JetBrains"),
            category: .developerTools,
            displayName: "JetBrains IDE Caches",
            owner: "JetBrains IDEs",
            explanation: "Search indexes and generated files that make JetBrains editors faster.",
            whyLarge: "Each IDE version and project can create its own indexes and local history.",
            risk: .rebuildable
        ),
        PathRule(
            id: "productivity.jetbrains.support",
            matcher: .homePrefix("Library/Application Support/JetBrains"),
            category: .developerTools,
            displayName: "JetBrains IDE Settings & Plug-ins",
            owner: "JetBrains IDEs",
            explanation: "Editor settings, installed plug-ins, and local IDE support files.",
            whyLarge: "Several IDE versions can keep separate plug-ins and settings.",
            risk: .review
        ),
        PathRule(
            id: "productivity.chrome.data",
            matcher: .homePrefix("Library/Application Support/Google/Chrome"),
            category: .applicationData,
            displayName: "Google Chrome Data",
            owner: "Google Chrome",
            explanation: "Browser profiles, extensions, website data, and local Chrome settings.",
            whyLarge: "Multiple profiles, extensions, offline websites, and browsing data can grow over time.",
            risk: .review
        ),
        PathRule(
            id: "productivity.firefox.data",
            matcher: .homePrefix("Library/Application Support/Firefox"),
            category: .applicationData,
            displayName: "Firefox Data",
            owner: "Firefox",
            explanation: "Browser profiles, extensions, website data, and local Firefox settings.",
            whyLarge: "Multiple profiles, extensions, and offline website data can grow over time.",
            risk: .review
        ),
        PathRule(
            id: "productivity.notion.data",
            matcher: .homePrefix("Library/Application Support/Notion"),
            category: .applicationData,
            displayName: "Notion Data",
            owner: "Notion",
            explanation: "Local workspace data, downloaded images, and files used by Notion.",
            whyLarge: "Large workspaces and media-rich pages can keep substantial local copies.",
            risk: .review
        ),
        PathRule(
            id: "creative.figma.data",
            matcher: .homePrefix("Library/Application Support/Figma"),
            category: .creativeData,
            displayName: "Figma Data",
            owner: "Figma",
            explanation: "Local design previews, settings, and working data used by Figma.",
            whyLarge: "Large design files, previews, and many team projects can build up local data.",
            risk: .review
        )
    ]
}
