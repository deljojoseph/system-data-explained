import XCTest
import SDEDomain
import SDEEngine

final class ClassificationEngineTests: XCTestCase {
    private let homePath = "/Users/tester"

    func testHighImpactDetectorPack() {
        let engine = ClassificationEngine(homePath: homePath)
        let cases: [(String, String, StorageCategory)] = [
            ("/Users/tester/Library/Application Support/MobileSync/Backup/device/file", "apple.mobile-device-backups", .deviceBackups),
            ("/Users/tester/Library/Messages/Attachments/a/b/photo.heic", "apple.messages.attachments", .messagesAndMail),
            ("/Users/tester/Library/Mail/V10/database", "apple.mail.data", .messagesAndMail),
            ("/Users/tester/Library/Mobile Documents/com~apple~CloudDocs/data", "apple.icloud.mobile-documents", .cloudData),
            ("/Users/tester/Library/Developer/Xcode/DerivedData/App/Build/file.o", "developer.xcode.derived-data", .developerTools),
            ("/Users/tester/Library/Developer/CoreSimulator/Devices/id/data.img", "developer.xcode.simulator-devices", .developerTools),
            ("/Users/tester/Library/Developer/XCTestDevices/id/data.img", "developer.xcode.test-devices", .developerTools),
            ("/Users/tester/Library/Group Containers/group.com.docker/settings.json", "developer.docker.group-data", .developerTools),
            ("/Users/tester/.gradle/caches/modules/file", "developer.gradle.caches", .developerTools),
            ("/Users/tester/.gradle/wrapper/dists/gradle.zip", "developer.gradle-wrapper-downloads", .developerTools),
            ("/Users/tester/.npm/_cacache/content-v2/file", "developer.npm-cache", .developerTools),
            ("/Users/tester/Library/Android/sdk/system-images/image", "developer.android.sdk", .developerTools),
            ("/Users/tester/.android/avd/Pixel.avd/userdata.img", "developer.android.virtual-devices", .developerTools),
            ("/opt/homebrew/Cellar/swift/1.0/bin/swift", "developer.homebrew.cellar", .developerTools),
            ("/opt/homebrew/share/man/man1/tool.1", "developer.homebrew.other", .developerTools),
            ("/Users/tester/Library/Caches/Adobe/Premiere/cache", "creative.adobe.caches", .creativeData),
            ("/Users/tester/Library/Caches/JetBrains/Idea/index", "productivity.jetbrains.caches", .developerTools),
            ("/Users/tester/Library/Application Support/Code/User/settings.json", "productivity.vscode.data", .developerTools),
            ("/Users/tester/.vscode/extensions/vendor.extension/file", "productivity.vscode-extensions", .developerTools),
            ("/Users/tester/Library/Group Containers/UBF8T346G9.Office/Outlook/profile.db", "microsoft.outlook.data", .applicationData),
            ("/Users/tester/Library/Application Support/Dropbox/index.db", "cloud.dropbox.support", .cloudData),
            ("/Users/tester/Parallels/Windows.pvm/disk.hdd", "virtualization.parallels", .virtualMachines),
            ("/Users/tester/Virtual Machines.localized/Test.vmwarevm/disk.vmdk", "virtualization.vmware", .virtualMachines),
            ("/private/var/vm/swapfile0", "system.virtual-memory", .systemManaged),
            ("/private/var/db/index", "system.databases", .systemManaged),
            ("/private/var/other/runtime", "system.runtime-other", .systemManaged),
            ("/Users/tester/Library/Other/installer.dmg", "packages.installers-and-archives", .packagesAndArchives)
        ]

        for (path, expectedID, expectedCategory) in cases {
            let result = engine.classify(observation(path: path))
            XCTAssertEqual(result.ruleID, expectedID, "Unexpected rule for \(path)")
            XCTAssertEqual(result.category, expectedCategory, "Unexpected category for \(path)")
            XCTAssertNotEqual(result.level, .unknown, "Known detector became unknown for \(path)")
        }
    }

    func testSpecificRuleWinsOverBroaderRule() {
        let engine = ClassificationEngine(homePath: homePath)
        let result = engine.classify(observation(
            path: "/Users/tester/Library/Developer/CoreSimulator/Devices/11111111-1111-1111-1111-111111111111/data"
        ))

        XCTAssertEqual(result.ruleID, "developer.xcode.simulator-devices")
        XCTAssertEqual(result.displayName, "iPhone & iPad Simulators")
        XCTAssertEqual(result.confidence, .high)
        XCTAssertTrue(result.nextStep.contains("Devices and Simulators"))
        XCTAssertEqual(result.guidance?.kind, .simulatorDevice)
        XCTAssertTrue(result.guidance?.consequence.contains("test files") == true)
    }

    func testNearbyPathDoesNotFalseMatchDerivedData() {
        let engine = ClassificationEngine(homePath: homePath)
        let result = engine.classify(observation(
            path: "/Users/tester/Library/Developer/Xcode/DerivedDatabase/file"
        ))

        XCTAssertEqual(result.ruleID, "developer.xcode.other")
        XCTAssertNotEqual(result.displayName, "Xcode Derived Data")
    }

    func testInstalledApplicationResolvesContainerOwner() {
        let identity = AppIdentity(
            bundleIdentifier: "com.example.notes",
            displayName: "Example Notes"
        )
        let engine = ClassificationEngine(
            homePath: homePath,
            appIdentities: [identity.bundleIdentifier: identity]
        )

        let result = engine.classify(observation(
            path: "/Users/tester/Library/Containers/com.example.notes/Data/database.sqlite"
        ))

        XCTAssertEqual(result.displayName, "Example Notes")
        XCTAssertEqual(result.owner, "Example Notes")
        XCTAssertEqual(result.level, .ownerKnown)
        XCTAssertTrue(result.evidence.contains { $0.kind == .bundleIdentifier })
    }

    func testUnknownRemainsExplicitlyUnknown() {
        let engine = ClassificationEngine(homePath: homePath)
        let result = engine.classify(observation(
            path: "/Users/tester/Library/MysteryArea/blob.bin"
        ))

        XCTAssertTrue(result.ruleID.hasPrefix("unknown."))
        XCTAssertEqual(result.category, .unclassified)
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.level, .unknown)
        XCTAssertEqual(result.risk, .unknown)
        XCTAssertEqual(result.guidance?.kind, .unknown)
        XCTAssertTrue(result.guidance?.recovery.contains("cannot confirm") == true)
        XCTAssertEqual(result.evidence, [
            StorageEvidence(kind: .path, value: "~/Library/MysteryArea")
        ])
    }

    func testUnknownFilesAreSplitIntoUsefulFolderGroups() {
        let engine = ClassificationEngine(homePath: homePath)
        let first = engine.classify(observation(
            path: "/Users/tester/Library/MysteryArea/blob.bin"
        ))
        let second = engine.classify(observation(
            path: "/Users/tester/Library/AnotherMystery/blob.bin"
        ))

        XCTAssertNotEqual(first.ruleID, second.ruleID)
        XCTAssertEqual(first.evidence.first?.value, "~/Library/MysteryArea")
        XCTAssertEqual(second.evidence.first?.value, "~/Library/AnotherMystery")
    }

    func testFileTypeRuleKeepsTheExactFileForFinder() {
        let engine = ClassificationEngine(homePath: homePath)
        let result = engine.classify(observation(
            path: "/Users/tester/Library/Other/installer.dmg"
        ))

        XCTAssertEqual(result.ruleID, "packages.installers-and-archives")
        XCTAssertTrue(result.evidence.contains {
            $0.kind == .path && $0.value == "~/Library/Other/installer.dmg"
        })
    }

    func testApplicationContainerKeepsTheSpecificFolderForFinder() {
        let engine = ClassificationEngine(homePath: homePath)
        let result = engine.classify(observation(
            path: "/Users/tester/Library/Containers/com.example.notes/Data/database.sqlite"
        ))

        XCTAssertTrue(result.evidence.contains {
            $0.kind == .storageFamily && $0.value == "~/Library/Containers/com.example.notes"
        })
    }

    func testClassificationIsDeterministicAndRedactsHomePath() {
        let engine = ClassificationEngine(homePath: homePath)
        let input = observation(path: "/Users/tester/Library/Developer/Xcode/DerivedData/App/file")

        let first = engine.classify(input)
        let second = engine.classify(input)

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.evidence.allSatisfy { !$0.value.contains("/Users/tester") })
    }

    private func observation(path: String) -> StorageObservation {
        StorageObservation(
            path: path,
            rootPath: homePath + "/Library",
            logicalBytes: 4_096,
            allocatedBytes: 4_096,
            kind: .file
        )
    }
}
