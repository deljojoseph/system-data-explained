import SDEDomain

enum DeveloperRules {
    static let all: [PathRule] = [
        PathRule(
            id: "developer.xcode.runtimes",
            matcher: .absolutePrefix("/Library/Developer/CoreSimulator/Profiles/Runtimes"),
            category: .developerTools, displayName: "Simulator Software", owner: "Xcode",
            explanation: "Shared software used by test devices running the same system version.",
            whyLarge: "Each installed system version can take several gigabytes.", risk: .review
        ),
        PathRule(
            id: "developer.xcode.runtime-images",
            matcher: .absolutePrefix("/Library/Developer/CoreSimulator/Images"),
            category: .developerTools, displayName: "Simulator Software Downloads", owner: "Xcode",
            explanation: "System software images managed by Xcode for its test devices.",
            whyLarge: "Several downloaded system versions can be kept here.", risk: .review
        ),
        PathRule(
            id: "developer.xcode.derived-data",
            matcher: .homePrefix("Library/Developer/Xcode/DerivedData"),
            category: .developerTools,
            displayName: "Xcode Derived Data",
            owner: "Xcode",
            explanation: "Files Xcode creates when it builds and searches an app project.",
            whyLarge: "Each project can keep its own built copies and search information.",
            nextStep: "Quit Xcode. In Finder, folders begin with project names. Remove only projects you can build again.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.xcode.archives",
            matcher: .homePrefix("Library/Developer/Xcode/Archives"),
            category: .developerTools,
            displayName: "Xcode Archives",
            owner: "Xcode",
            explanation: "Saved copies of apps you built for release or for your records.",
            whyLarge: "Every saved build contains a full copy of the app plus information needed to diagnose problems.",
            risk: .review
        ),
        PathRule(
            id: "developer.xcode.device-support",
            matcher: .homePrefix("Library/Developer/Xcode/iOS DeviceSupport"),
            category: .developerTools,
            displayName: "iPhone Device Support",
            owner: "Xcode",
            explanation: "Files Xcode needs to work with iPhones and iPads you connect.",
            whyLarge: "Xcode can keep a separate set for every iPhone or iPad software version it sees.",
            nextStep: "Quit Xcode. Folders are named by software version; older versions can return when you connect that device again.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.xcode.simulator-devices",
            matcher: .homePrefix("Library/Developer/CoreSimulator/Devices"),
            category: .developerTools,
            displayName: "iPhone & iPad Simulators",
            owner: "Xcode",
            explanation: "Copies of iPhones and iPads on your Mac that Xcode uses for testing.",
            whyLarge: "Each device keeps its own saved test data. Several devices may share the same system software.",
            nextStep: "Use Xcode → Window → Devices and Simulators → Simulators. Remove devices there; do not guess from the UUID folders in Finder.",
            risk: .review
        ),
        PathRule(
            id: "developer.xcode.simulator-caches",
            matcher: .homePrefix("Library/Developer/CoreSimulator/Caches"),
            category: .developerTools,
            displayName: "Simulator Caches",
            owner: "Xcode",
            explanation: "Temporary files made while Xcode runs pretend iPhones and iPads.",
            whyLarge: "Testing many device types and software versions creates more temporary copies.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.xcode.simulator-data",
            matcher: .homePrefix("Library/Developer/CoreSimulator"),
            category: .developerTools,
            displayName: "Simulator Support Data",
            owner: "Xcode",
            explanation: "Other files Xcode needs to run its test iPhones and iPads.",
            whyLarge: "Several device types and software versions can each keep their own files.",
            nextStep: "Use Xcode → Settings → Components to remove simulator software you no longer need. Use Xcode's Devices and Simulators window for individual test devices.",
            risk: .review
        ),
        PathRule(
            id: "developer.xcode.test-devices",
            matcher: .homePrefix("Library/Developer/XCTestDevices"),
            category: .developerTools,
            displayName: "Xcode Test Devices",
            owner: "Xcode",
            explanation: "Extra copies of test iPhones that Xcode makes while checking an app.",
            whyLarge: "Each test device keeps saved app data; its system software may be shared with other devices.",
            nextStep: "These folders have UUID names and are not meant for manual sorting. Quit Xcode and leave them alone unless you no longer use automated Xcode tests.",
            risk: .review
        ),
        PathRule(
            id: "developer.xcode.other",
            matcher: .homePrefix("Library/Developer/Xcode"),
            category: .developerTools,
            displayName: "Xcode Data",
            owner: "Xcode",
            explanation: "Other settings, built apps, help files, and tools kept by Xcode.",
            whyLarge: "Many projects and Apple software versions can leave separate files here.",
            risk: .review
        ),
        PathRule(
            id: "developer.docker.group-data",
            matcher: .homePrefix("Library/Group Containers/group.com.docker"),
            category: .developerTools,
            displayName: "Docker Data",
            owner: "Docker Desktop",
            explanation: "Downloaded software building blocks, saved project data, and the virtual drive used by Docker Desktop.",
            whyLarge: "Docker projects can keep whole operating-system parts, databases, and large saved files.",
            risk: .review
        ),
        PathRule(
            id: "developer.docker.container-data",
            matcher: .homePrefix("Library/Containers/com.docker.docker"),
            category: .developerTools,
            displayName: "Docker Desktop Data",
            owner: "Docker Desktop",
            explanation: "Files kept by Docker Desktop, including its virtual drive.",
            whyLarge: "The virtual drive grows as you download software and save data in Docker projects.",
            risk: .review
        ),
        PathRule(
            id: "developer.gradle.caches",
            matcher: .homePrefix(".gradle/caches"),
            category: .developerTools,
            displayName: "Gradle Caches",
            owner: "Gradle",
            explanation: "Downloaded code packages and temporary build files used by Android and Java projects.",
            whyLarge: "Many projects can keep different versions of the same packages and built files.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.android.sdk",
            matcher: .homePrefix("Library/Android/sdk"),
            category: .developerTools,
            displayName: "Android SDK",
            owner: "Android Studio",
            explanation: "Android platform tools, emulators, and system images used for app development.",
            whyLarge: "Each Android version and emulator system image can require several gigabytes.",
            risk: .review
        ),
        PathRule(
            id: "developer.android.virtual-devices",
            matcher: .homePrefix(".android/avd"),
            category: .developerTools,
            displayName: "Android Virtual Devices",
            owner: "Android Studio",
            explanation: "Virtual Android devices and their local data.",
            whyLarge: "Every virtual device includes a writable device image and snapshots.",
            risk: .review
        ),
        PathRule(
            id: "developer.homebrew.cellar",
            matcher: .absolutePrefix("/opt/homebrew/Cellar"),
            category: .developerTools,
            displayName: "Homebrew Packages",
            owner: "Homebrew",
            explanation: "Installed command-line tools and libraries managed by Homebrew.",
            whyLarge: "Multiple tools, libraries, and installed versions can occupy substantial storage.",
            nextStep: "Manage these through Homebrew. Do not delete package folders by hand because other tools may depend on them.",
            risk: .review
        ),
        PathRule(
            id: "developer.homebrew.intel-cellar",
            matcher: .absolutePrefix("/usr/local/Homebrew/Cellar"),
            category: .developerTools,
            displayName: "Homebrew Packages",
            owner: "Homebrew",
            explanation: "Installed command-line tools and libraries managed by Homebrew.",
            whyLarge: "Multiple tools, libraries, and installed versions can occupy substantial storage.",
            nextStep: "Manage these through Homebrew. Do not delete package folders by hand because other tools may depend on them.",
            risk: .review
        ),
        PathRule(
            id: "developer.homebrew.caches",
            matcher: .homePrefix("Library/Caches/Homebrew"),
            category: .developerTools,
            displayName: "Homebrew Downloads",
            owner: "Homebrew",
            explanation: "Downloaded package files retained by Homebrew.",
            whyLarge: "Package archives can accumulate across upgrades and installations.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.swift-package-manager",
            matcher: .homePrefix("Library/Caches/org.swift.swiftpm"),
            category: .developerTools,
            displayName: "Swift Package Caches",
            owner: "Swift Package Manager",
            explanation: "Downloaded source packages and repository data used by Swift projects.",
            whyLarge: "Many packages and version histories can be retained locally.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.gradle-wrapper-downloads",
            matcher: .homePrefix(".gradle/wrapper/dists"),
            category: .developerTools,
            displayName: "Downloaded Gradle Versions",
            owner: "Gradle",
            explanation: "Copies of Gradle downloaded to build Android and Java projects.",
            whyLarge: "Projects can request different Gradle versions, and each version is stored separately.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.gradle-downloaded-jdks",
            matcher: .homePrefix(".gradle/jdks"),
            category: .developerTools,
            displayName: "Java Versions Downloaded by Gradle",
            owner: "Gradle",
            explanation: "Java toolchains Gradle downloaded for specific projects.",
            whyLarge: "Each Java version is a complete development kit and can take hundreds of megabytes.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.gradle-other",
            matcher: .homePrefix(".gradle"),
            category: .developerTools,
            displayName: "Other Gradle Files",
            owner: "Gradle",
            explanation: "Settings, logs, downloaded tools, and other files Gradle uses for builds.",
            whyLarge: "Multiple projects and Gradle versions can leave files here over time.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.android-other",
            matcher: .homePrefix(".android"),
            category: .developerTools,
            displayName: "Other Android Development Files",
            owner: "Android Studio",
            explanation: "Settings and support files used by Android Studio and Android emulators.",
            whyLarge: "Emulator settings, snapshots, keys, and tool data can build up across projects.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.npm-cache",
            matcher: .homePrefix(".npm/_cacache"),
            category: .developerTools,
            displayName: "npm Package Downloads",
            owner: "npm",
            explanation: "Verified copies of packages downloaded while building JavaScript projects.",
            whyLarge: "Every package version used across many projects can remain available for faster installs.",
            nextStep: "Quit developer tools. The _cacache folder is the recreatable download cache; avoid changing the other npm files.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.npm-other",
            matcher: .homePrefix(".npm"),
            category: .developerTools,
            displayName: "Other npm Files",
            owner: "npm",
            explanation: "Logs and support files created while installing JavaScript packages.",
            whyLarge: "Many package installs and old log files can accumulate here.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.docker-home",
            matcher: .homePrefix(".docker"),
            category: .developerTools,
            displayName: "Docker Settings & Support Files",
            owner: "Docker",
            explanation: "Local settings, command-line plug-ins, and support files used by Docker.",
            whyLarge: "Plug-ins, build settings, and support data can grow across Docker projects.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.homebrew.caskroom",
            matcher: .absolutePrefix("/opt/homebrew/Caskroom"),
            category: .developerTools,
            displayName: "Apps Installed by Homebrew",
            owner: "Homebrew",
            explanation: "App packages installed and tracked by Homebrew.",
            whyLarge: "Homebrew may keep installed app packages and versions here.",
            risk: .review
        ),
        PathRule(
            id: "developer.homebrew.other",
            matcher: .absolutePrefix("/opt/homebrew"),
            category: .developerTools,
            displayName: "Other Homebrew Files",
            owner: "Homebrew",
            explanation: "Libraries, shared resources, services, and package-manager files used by Homebrew.",
            whyLarge: "Installed tools share libraries and may keep databases or service data outside the main package folder.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.homebrew.intel-other",
            matcher: .absolutePrefix("/usr/local/Homebrew"),
            category: .developerTools,
            displayName: "Other Homebrew Files",
            owner: "Homebrew",
            explanation: "Libraries, shared resources, services, and package-manager files used by Homebrew.",
            whyLarge: "Installed tools share libraries and may keep databases or service data outside the main package folder.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.cocoapods-cache",
            matcher: .homePrefix("Library/Caches/CocoaPods"),
            category: .developerTools,
            displayName: "CocoaPods Downloads",
            owner: "CocoaPods",
            explanation: "Downloaded iOS and macOS code libraries used by app projects.",
            whyLarge: "Many projects and library versions can remain cached for faster installs.",
            risk: .rebuildable
        ),
        PathRule(
            id: "developer.user-library-other",
            matcher: .homePrefix("Library/Developer"),
            category: .developerTools,
            displayName: "Other Developer Tool Files",
            explanation: "Files created by Xcode or other developer tools.",
            whyLarge: "Build tools, device support, documentation, and testing tools can keep large working sets.",
            risk: .review,
            confidence: .medium
        ),
        PathRule(
            id: "developer.shared-library",
            matcher: .absolutePrefix("/Library/Developer"),
            category: .developerTools,
            displayName: "Shared Developer Tools",
            explanation: "Developer tools and support files installed for every user on this Mac.",
            whyLarge: "SDKs, command-line tools, simulators, and device support can span several platform versions.",
            risk: .review,
            confidence: .medium
        )
    ]
}
