import SDEDomain

enum SystemRules {
    static let all: [PathRule] = [
        PathRule(
            id: "system.virtual-memory",
            matcher: .absolutePrefix("/private/var/vm"),
            category: .systemManaged,
            displayName: "Extra Working Memory for macOS",
            owner: "macOS",
            explanation: "Disk space macOS borrows when running apps need more memory.",
            whyLarge: "It grows when many apps are open or an app needs more memory than is available.",
            risk: .expected
        ),
        PathRule(
            id: "system.logs",
            matcher: .absolutePrefix("/private/var/log"),
            category: .systemManaged,
            displayName: "macOS Activity Records",
            owner: "macOS",
            explanation: "Records macOS keeps to help explain problems and system activity.",
            whyLarge: "A repeating problem or a service that runs often can create many records.",
            risk: .expected
        ),
        PathRule(
            id: "system.temporary-caches",
            matcher: .absolutePrefix("/private/var/folders"),
            category: .systemManaged,
            displayName: "macOS Temporary Data",
            owner: "macOS and Applications",
            explanation: "Temporary working files that macOS keeps for you and your apps.",
            whyLarge: "Many apps use this shared area while they are running.",
            risk: .expected
        ),
        PathRule(
            id: "system.databases",
            matcher: .absolutePrefix("/private/var/db"),
            category: .systemManaged,
            displayName: "macOS Search & Service Records",
            owner: "macOS",
            explanation: "Records macOS uses for search, updates, security, and other built-in features.",
            whyLarge: "These records grow as macOS learns about more files, apps, and activity.",
            risk: .expected
        ),
        PathRule(
            id: "system.runtime-other",
            matcher: .absolutePrefix("/private/var"),
            category: .systemManaged,
            displayName: "Other Files macOS Is Using",
            owner: "macOS",
            explanation: "Other working and temporary files used by macOS.",
            whyLarge: "Many parts of macOS and installed apps share this area while they run.",
            risk: .expected,
            confidence: .medium
        ),
        PathRule(
            id: "system.library-caches",
            matcher: .absolutePrefix("/Library/Caches"),
            category: .cachesAndLogs,
            displayName: "Shared Application Caches",
            explanation: "Temporary copies that help apps work faster for every user on this Mac.",
            whyLarge: "Apps can keep generated or downloaded copies here for later use.",
            risk: .rebuildable
        ),
        PathRule(
            id: "system.update-files",
            matcher: .absolutePrefix("/Library/Updates"),
            category: .systemManaged,
            displayName: "macOS Update Files",
            owner: "macOS",
            explanation: "Downloaded files used while preparing macOS and system-component updates.",
            whyLarge: "Operating-system updates can require several gigabytes of staged data.",
            risk: .expected
        ),
        PathRule(
            id: "system.shared-frameworks",
            matcher: .absolutePrefix("/Library/Frameworks"),
            category: .applicationData,
            displayName: "Shared Software Parts",
            explanation: "Reusable software parts installed for apps on this Mac.",
            whyLarge: "Creative tools, developer tools, and device software can install large shared frameworks.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "system.shared-fonts",
            matcher: .absolutePrefix("/Library/Fonts"),
            category: .applicationData,
            displayName: "Fonts for All Users",
            explanation: "Fonts installed so every user and app can use them.",
            whyLarge: "Professional font collections can contain thousands of font files.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "system.shared-audio",
            matcher: .absolutePrefix("/Library/Audio"),
            category: .creativeData,
            displayName: "Shared Audio Tools & Sounds",
            explanation: "Audio plug-ins, loops, and device support available to music and video apps.",
            whyLarge: "Sound libraries and professional audio plug-ins can include large sample collections.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "system.background-app-helpers",
            matcher: .absolutePrefix("/Library/LaunchAgents"),
            category: .applicationData,
            displayName: "Background App Helpers",
            explanation: "Small instructions that let installed apps start helper processes in the background.",
            whyLarge: "This area normally stays small; many installed apps can leave helpers behind.",
            risk: .expected,
            confidence: .medium
        ),
        PathRule(
            id: "system.background-service-helpers",
            matcher: .absolutePrefix("/Library/LaunchDaemons"),
            category: .systemManaged,
            displayName: "Background System Helpers",
            explanation: "Small instructions that start services needed by macOS or installed apps.",
            whyLarge: "This area normally stays small and may include services from many apps.",
            risk: .expected,
            confidence: .medium
        ),
        PathRule(
            id: "system.java-tools",
            matcher: .absolutePrefix("/Library/Java"),
            category: .developerTools,
            displayName: "Java Development Tools",
            owner: "Java tools",
            explanation: "Java runtimes and development kits installed for apps and software projects.",
            whyLarge: "Several Java versions can be installed side by side, each with a complete runtime and tools.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "packages.installers-and-archives",
            matcher: .fileExtensions(["dmg", "pkg", "zip", "xip"]),
            category: .packagesAndArchives,
            displayName: "Installers & Archives",
            explanation: "Downloaded installers, disk images, and compressed archives.",
            whyLarge: "Complete application installers and archived projects can each contain many gigabytes.",
            risk: .review
        )
    ]
}
