// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SystemDataExplained",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SystemDataExplained", targets: ["SystemDataExplained"])
    ],
    targets: [
        .target(name: "SDEDomain"),
        .target(
            name: "SDEApplication",
            dependencies: ["SDEDomain"]
        ),
        .target(
            name: "SDEEngine",
            dependencies: ["SDEDomain", "SDEApplication"]
        ),
        .target(
            name: "SDEInfrastructure",
            dependencies: ["SDEDomain", "SDEApplication"]
        ),
        .executableTarget(
            name: "SystemDataExplained",
            dependencies: [
                "SDEDomain",
                "SDEApplication",
                "SDEEngine",
                "SDEInfrastructure"
            ],
            exclude: ["Resources/my-system-sample.png"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["SystemDataExplained", "SDEDomain", "SDEApplication", "SDEEngine"]
        ),
        .testTarget(
            name: "SystemDataExplainedTests",
            dependencies: [
                "SDEDomain",
                "SDEApplication",
                "SDEEngine",
                "SDEInfrastructure"
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
