import Foundation
import SDEDomain

/// Purpose matching and removal advice are deliberately separate decisions.
enum ReviewPlanner {
    static func enrich(_ base: Classification, observation: StorageObservation, homePath: String) -> Classification {
        let evidencePath = base.evidence.first { $0.kind == .path || $0.kind == .storageFamily }?.value
        let anchor = evidencePath.map { $0.hasPrefix("~/") ? homePath + $0.dropFirst() : $0 } ?? observation.rootPath
        let relative = observation.path.hasPrefix(anchor + "/") ? String(observation.path.dropFirst(anchor.count + 1)) : ""
        let components = relative.split(separator: "/").map(String.init)
        var target = anchor
        var name: String?
        var guidance = recipe(base)
        let devices = ["developer.xcode.simulator-devices", "developer.xcode.test-devices"]
        let independentChildren: Set<String> = [
            "developer.xcode.derived-data", "developer.xcode.device-support", "developer.android.virtual-devices",
            "apple.mobile-device-backups", "virtualization.parallels", "virtualization.vmware", "virtualization.virtualbox",
            "developer.xcode.runtimes", "developer.xcode.runtime-images"
        ]
        if let child = components.first, devices.contains(base.ruleID) {
            target += "/" + child
            if UUID(uuidString: child) != nil {
                name = "Test device · " + String(child.prefix(8))
            } else {
                name = "Simulator support file · " + child
                guidance = inspection(base, summary: "Supporting simulator files, not an identified test device.")
            }
        } else if let child = components.first, independentChildren.contains(base.ruleID) {
            target += "/" + child
            name = child
        } else if base.ruleID == "developer.xcode.archives", !components.isEmpty {
            target += "/" + components.prefix(2).joined(separator: "/")
            name = components.prefix(2).last
        }
        // A broad Devices directory itself is never a single device review target.
        if devices.contains(base.ruleID), components.isEmpty { guidance = inspection(base) }
        return Classification(ruleID: base.ruleID, category: base.category, displayName: base.displayName,
            owner: base.owner, explanation: base.explanation, whyLarge: base.whyLarge, nextStep: guidance.nextStep,
            risk: base.risk, confidence: base.confidence, level: base.level, evidence: base.evidence,
            reviewPath: target, reviewName: name, guidance: guidance)
    }

    private static func recipe(_ c: Classification) -> ReviewGuidance {
        switch c.ruleID {
        case "developer.xcode.simulator-devices", "developer.xcode.test-devices":
            return ReviewGuidance(kind: .simulatorDevice, summary: "Apps and saved files inside one test iPhone or iPad.",
                consequence: "You lose this device’s apps, accounts, databases, and test files.",
                recovery: "A fresh device is empty. Old test data needs a usable backup; its software must still be available.",
                nextStep: "Need anything saved inside this device? Keep it. Otherwise, find the matching device in Xcode’s Devices and Simulators window.",
                fallbackTitle: "Not showing in Xcode?", fallbackSteps: [
                    "This folder still takes space even if Xcode does not list it. That alone does not mean it is unused.",
                    "Compare the device name and software below with the Xcode version you use. Another Xcode, missing software, or test tools may explain the mismatch.",
                    "Show in Finder selects this device only. Its data folder can contain unique test work; do not remove the enclosing Devices folder.",
                    "If the saved state matters, keep a verified backup on another disk. A new empty simulator is not a recovery of this data.",
                    "Manual removal and restore are not validated for this device. Do not move it while simulator services may be running; quitting Xcode alone may not stop them. Use Apple’s support guidance to resolve the mismatch before removal."
                ], sourceURL: "https://developer.apple.com/documentation/safari-developer-tools/adding-additional-simulators")
        case "developer.xcode.runtimes", "developer.xcode.runtime-images", "developer.android.sdk", "developer.xcode.device-support":
            return ReviewGuidance(kind: .simulatorRuntime, summary: "Software used to run or debug particular device versions.",
                consequence: "Projects or test devices that need this version may stop working.",
                recovery: "You need compatible tools and the same download. Older versions may no longer be available.",
                nextStep: c.owner == "Android Studio" ? "Review installed versions in Android Studio’s SDK Manager." : "Review installed versions in Xcode Settings → Components.",
                fallbackTitle: "Version missing from the app?", fallbackSteps: [
                    "Compare the version or file name here with every tool version you still use. Shared software can serve several devices.",
                    "Keep it if you cannot establish what depends on it. Do not remove shared software folders manually."
                ], sourceURL: c.owner == "Android Studio" ? "https://developer.android.com/studio/intro/update" : "https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components")
        case "developer.xcode.derived-data":
            return ReviewGuidance(kind: .buildFiles, summary: "Working copies Xcode made while building this project.",
                consequence: "The next build takes longer and may fail offline if packages must be downloaded again.",
                recovery: "Keep your source project, required package versions, and working access to dependencies.",
                nextStep: "If you can build this project again, quit Xcode and review this project’s folder in Finder.",
                fallbackTitle: "How to make room", fallbackSteps: [
                    "Verify your source project is saved outside this DerivedData folder and can be opened.",
                    "Quit Xcode and any running builds. Move only this project’s DerivedData folder to Trash if its generated files are no longer needed.",
                    "Reopen the source project and build the workflows you need before permanent removal. Restore from backup if unique files were put here by mistake.",
                    "Files in Trash still take space. Emptying Trash removes the easy recovery path; do not empty unrelated items."
                ], sourceURL: "https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes")
        case "developer.gradle.caches", "developer.gradle-wrapper-downloads", "developer.gradle-downloaded-jdks",
             "developer.npm-cache", "developer.homebrew.caches", "developer.swift-package-manager", "developer.cocoapods-cache":
            return ReviewGuidance(kind: .downloads, summary: c.explanation,
                consequence: "Builds may take longer or fail until the exact packages and tools are downloaded again.",
                recovery: "Check network access, credentials, and availability of required versions first. Offline copies may be valuable.",
                nextStep: "Review old downloads using \(c.owner ?? "the tool")’s storage controls. Keep versions still needed by your projects.",
                fallbackTitle: "No storage control available?", fallbackSteps: [
                    "The folder shown here contains downloads, not proof that every version is unnecessary.",
                    "Check your projects and tool documentation before changing it. Do not delete neighboring settings, keys, or source files.",
                    "If a required version cannot be downloaded again, preserve a usable copy on another disk."
                ], sourceURL: downloadSource(c.ruleID))
        case "creative.adobe.common-media-cache", "creative.final-cut.caches":
            return ReviewGuidance(kind: .generatedMedia, summary: c.explanation,
                consequence: "Previews and media processing may need to be generated again, slowing your next edit.",
                recovery: "Your project and original media must still be available. Generated files cannot replace missing originals.",
                nextStep: "Confirm your originals open, then use the editor’s media or generated-file controls.",
                fallbackTitle: "Before removing generated files", fallbackSteps: [
                    "Keep original recordings, project libraries, and exports you cannot reproduce.",
                    "If the editor cannot identify these files, inspect this exact location and consult its support instructions. A folder name alone does not prove every file is replaceable."
                ], sourceURL: c.ruleID == "creative.final-cut.caches" ? "https://support.apple.com/guide/final-cut-pro/manage-render-files-ver68a8c250/mac" : "https://helpx.adobe.com/premiere/desktop/troubleshooting/media-issues/manage-media-cache.html")
        case "apple.mobile-device-backups":
            return ReviewGuidance(kind: .backup, summary: "A saved copy of an iPhone or iPad.",
                consequence: "You lose the ability to restore the device to this backup’s point in time.",
                recovery: "A new backup does not bring back old history. Preserve and verify another copy if this one matters.",
                nextStep: "Connect your device, then in Finder choose Manage Backups and match the backup before deleting it.",
                fallbackTitle: "Backup not listed?", fallbackSteps: [
                    "Inspect only this backup folder. Do not remove individual files inside it; that can make the whole backup unusable.",
                    "Keep it if you cannot match its device or date. Apple’s backup-location guide explains how to locate and archive backups."
                ], sourceURL: "https://support.apple.com/108809")
        case "developer.xcode.archives":
            return ReviewGuidance(kind: .archive, summary: "A saved release build of your app, with information for investigating crashes.",
                consequence: "You may lose the exact shipped build and the information needed to interpret its crash reports.",
                recovery: "Rebuilding source may not reproduce this archive. Preserve the original if you still support that release.",
                nextStep: "Match the app and version in Xcode’s Organizer before removing an old archive.")
        default: break
        }
        if c.category == .cloudData {
            return ReviewGuidance(kind: .cloudFiles, summary: c.explanation,
                consequence: "Deleting a synced file may delete it on your other devices too.",
                recovery: "Check that upload has finished and the online copy opens. Recovery periods vary by provider.",
                nextStep: "For synced files, use the provider’s Remove Download or online-only option, not Delete.",
                fallbackTitle: "No Remove Download option?", fallbackSteps: [
                    "This may be app support data rather than a downloadable file. Keep it; do not delete the provider’s support folder.",
                    "Open the provider’s storage settings and review offline files there. Pending uploads may be the only copy."
                ], sourceURL: "https://support.apple.com/guide/mac-help/work-with-folders-and-files-in-icloud-drive-mchl1a02d711/mac")
        }
        if c.category == .virtualMachines || c.ruleID.contains("docker") || c.ruleID == "developer.android.virtual-devices" {
            return ReviewGuidance(kind: .persistentData, summary: c.explanation,
                consequence: "This can contain an entire computer’s files or a project’s only database, not just downloaded software.",
                recovery: "Reinstalling the app does not restore these files. Export valuable data and verify a backup first.",
                nextStep: "Open \(c.owner ?? "the owning app") and match this device or project before removing it.",
                fallbackTitle: "The app does not list it?", fallbackSteps: [
                    "Inspect the selected item’s name. Do not remove one file from the middle of a virtual disk or device folder.",
                    "If you cannot reconnect or identify it, keep it and use the app’s backup or recovery instructions. Missing from a list does not mean empty."
                ], sourceURL: c.ruleID.contains("docker") ? "https://docs.docker.com/desktop/settings-and-maintenance/backup-and-restore/" : nil)
        }
        if c.category == .systemManaged {
            return ReviewGuidance(kind: .system, summary: c.explanation,
                consequence: "Removing these files manually can disrupt macOS or other apps.",
                recovery: "Recovery may require system repair. A restart is not a guarantee of restoring missing files.",
                nextStep: "Leave these files to macOS. Review your personal app data for space instead.")
        }
        if c.category == .packagesAndArchives {
            return ReviewGuidance(kind: .archive, summary: c.explanation,
                consequence: "An archive may be your only copy. A file extension does not establish whether it is an expendable installer.",
                recovery: "Verify another usable copy or an available download before permanent removal.",
                nextStep: "Inspect this file. If it is only an installer for an app already installed, confirm you can download it again.",
                fallbackTitle: "If you choose to remove it", fallbackSteps: [
                    "Move only the file you recognized to Trash in Finder. Keep it there while you verify the app or extracted files work.",
                    "Trash still takes space. Permanent removal ends easy recovery; do not empty unrelated items."
                ])
        }
        return inspection(c)
    }

    private static func inspection(_ c: Classification, summary: String? = nil) -> ReviewGuidance {
        ReviewGuidance(kind: c.level == .unknown ? .unknown : .persistentData,
            summary: summary ?? c.explanation,
            consequence: "This folder may mix temporary files with settings or saved work. Removing the whole folder could lose data.",
            recovery: "The app cannot confirm these files can be recreated. Important work needs a usable backup, not just the app installer.",
            nextStep: "Inspect this location to identify what you recognize. Use \(c.owner ?? "the owning app")’s storage controls for items you no longer need.",
            fallbackTitle: "Still unsure?", fallbackSteps: [
                "Keep files you cannot identify. Being old, large, or in a folder called Cache does not prove they are unnecessary.",
                "Check the app’s help for downloads, saved history, or storage settings. Avoid removing a whole app folder to make room.",
                "If you need space but must preserve the data, verify a backup on another disk before any permanent removal."
            ])
    }

    private static func downloadSource(_ id: String) -> String? {
        if id.contains("gradle") { return "https://docs.gradle.org/current/userguide/directory_layout.html" }
        if id.contains("npm") { return "https://docs.npmjs.com/cli/commands/npm-cache" }
        if id.contains("homebrew") { return "https://docs.brew.sh/Manpage" }
        return nil
    }
}
