import Foundation
import Darwin
import SDEApplication
import SDEDomain

public struct MacFileSystemReader: FileSystemReading, Sendable {
    public init() {}

    public func scan(
        _ request: ScanRequest,
        onObservation: @escaping @Sendable (StorageObservation) -> Void,
        onProgress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> ScanSummary {
        let worker = Task.detached(priority: .userInitiated) {
            try Self.performScan(
                request,
                onObservation: onObservation,
                onProgress: onProgress
            )
        }

        return try await withTaskCancellationHandler(
            operation: { try await worker.value },
            onCancel: { worker.cancel() }
        )
    }

    private static func performScan(
        _ request: ScanRequest,
        onObservation: @escaping @Sendable (StorageObservation) -> Void,
        onProgress: @escaping @Sendable (ScanProgress) -> Void
    ) throws -> ScanSummary {
        let start = Date()
        let fileManager = FileManager()
        let keys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .isPackageKey,
            .fileSizeKey,
            .totalFileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
            .contentModificationDateKey,
            .volumeIdentifierKey
        ]

        var filesObserved = 0
        var directoriesObserved = 0
        var symbolicLinksSkipped = 0
        var measuredBytes: Int64 = 0
        var logicalBytes: Int64 = 0
        var issues: [ScanIssue] = []
        var issueCounts: [ScanIssueKind: Int] = [:]
        var lastProgress = Date.distantPast

        func appendIssue(_ issue: ScanIssue) {
            issueCounts[issue.kind, default: 0] += 1
            if issues.count < 250 {
                issues.append(issue)
            }
        }

        for root in request.roots {
            try Task.checkCancellation()

            guard let rootDescriptor = ObservedFileAccess.openPath(root.path) else {
                let failure = errno
                if root.isOptional && failure == ENOENT { continue }
                appendIssue(ScanIssue(
                    kind: failure == EACCES || failure == EPERM ? .permissionDenied : .unavailableRoot,
                    path: redacted(root.path),
                    message: "This scan area was not available."
                ))
                continue
            }
            var rootInfo = stat()
            let isDirectory = fstat(rootDescriptor, &rootInfo) == 0 && (rootInfo.st_mode & S_IFMT) == S_IFDIR
            close(rootDescriptor)
            guard isDirectory else {
                appendIssue(ScanIssue(kind: .unavailableRoot, path: redacted(root.path), message: "This location is not an available folder."))
                continue
            }
            onObservation(StorageObservation(path: root.path, rootPath: root.path, logicalBytes: 0,
                allocatedBytes: 0, kind: .directory, identity: ObservedFileAccess.identity(rootInfo)))

            let rootURL = URL(fileURLWithPath: root.path, isDirectory: true)
            let rootVolume = try? rootURL.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier
            let rootVolumeID = volumeIdentifier(rootVolume)

            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: keys,
                options: [],
                errorHandler: { url, error in
                    let cocoaError = error as NSError
                    let kind: ScanIssueKind = cocoaError.code == NSFileReadNoPermissionError
                        ? .permissionDenied
                        : .metadataUnavailable
                    appendIssue(ScanIssue(
                        kind: kind,
                        path: redacted(url.path),
                        message: kind == .permissionDenied
                            ? "macOS did not allow this location to be read."
                            : "This location could not be examined."
                    ))
                    return true
                }
            ) else {
                appendIssue(ScanIssue(
                    kind: .permissionDenied,
                    path: redacted(root.path),
                    message: "macOS did not allow this scan area to be enumerated."
                ))
                continue
            }

            while let entryURL = enumerator.nextObject() as? URL {
                if (filesObserved + directoriesObserved + symbolicLinksSkipped) % 256 == 0 {
                    try Task.checkCancellation()
                }

                do {
                    let values = try entryURL.resourceValues(forKeys: Set(keys))

                    if values.isSymbolicLink == true {
                        symbolicLinksSkipped += 1
                        enumerator.skipDescendants()
                        continue
                    }

                    let entryVolumeID = volumeIdentifier(values.volumeIdentifier)
                    if request.stayOnVolume,
                       let rootVolumeID,
                       let entryVolumeID,
                       rootVolumeID != entryVolumeID {
                        enumerator.skipDescendants()
                        appendIssue(ScanIssue(
                            kind: .volumeBoundarySkipped,
                            path: redacted(entryURL.path),
                            message: "A different mounted volume was skipped to prevent accidental cross-volume scanning."
                        ))
                        continue
                    }

                    if values.isDirectory == true {
                        directoriesObserved += 1
                        var info = stat()
                        if lstat(entryURL.path, &info) == 0, (info.st_mode & S_IFMT) == S_IFDIR {
                            onObservation(StorageObservation(path: entryURL.path, rootPath: root.path,
                                logicalBytes: 0, allocatedBytes: 0, kind: .directory,
                                identity: ObservedFileAccess.identity(info)))
                        }
                    } else {
                        let logical = Int64(values.totalFileSize ?? values.fileSize ?? 0)
                        let allocatedValue = values.totalFileAllocatedSize ?? values.fileAllocatedSize
                        let allocated = allocatedValue.map(Int64.init)
                        let kind: StorageEntryKind = values.isPackage == true
                            ? .package
                            : (values.isRegularFile == true ? .file : .other)

                        var info = stat()
                        let identity = lstat(entryURL.path, &info) == 0 && (info.st_mode & S_IFMT) == S_IFREG
                            ? ObservedFileAccess.identity(info) : nil
                        let observation = StorageObservation(
                            path: entryURL.path,
                            rootPath: root.path,
                            logicalBytes: logical,
                            allocatedBytes: allocated,
                            kind: kind,
                            modificationDate: values.contentModificationDate,
                            volumeIdentifier: entryVolumeID,
                            identity: identity
                        )
                        onObservation(observation)
                        filesObserved += 1
                        measuredBytes += observation.measuredBytes
                        logicalBytes += observation.logicalBytes
                    }
                } catch {
                    let cocoaError = error as NSError
                    let kind: ScanIssueKind
                    if cocoaError.code == NSFileReadNoSuchFileError {
                        kind = .transientFileChange
                    } else if cocoaError.code == NSFileReadNoPermissionError {
                        kind = .permissionDenied
                    } else {
                        kind = .metadataUnavailable
                    }
                    appendIssue(ScanIssue(
                        kind: kind,
                        path: redacted(entryURL.path),
                        message: kind == .transientFileChange
                            ? "A file changed while the scan was running."
                            : "Metadata for this item could not be read."
                    ))
                    continue
                }

                let now = Date()
                if now.timeIntervalSince(lastProgress) >= 0.2 {
                    lastProgress = now
                    onProgress(ScanProgress(
                        filesObserved: filesObserved,
                        directoriesObserved: directoriesObserved,
                        measuredBytes: measuredBytes,
                        currentArea: root.displayName
                    ))
                }
            }
        }

        try Task.checkCancellation()
        onProgress(ScanProgress(
            filesObserved: filesObserved,
            directoriesObserved: directoriesObserved,
            measuredBytes: measuredBytes,
            currentArea: "Building your explanation"
        ))

        return ScanSummary(
            roots: request.roots,
            filesObserved: filesObserved,
            directoriesObserved: directoriesObserved,
            symbolicLinksSkipped: symbolicLinksSkipped,
            measuredBytes: measuredBytes,
            logicalBytes: logicalBytes,
            issues: issues,
            duration: Date().timeIntervalSince(start),
            issueCounts: issueCounts
        )
    }

    private static func volumeIdentifier(_ value: Any?) -> String? {
        guard let value else { return nil }
        return String(describing: value)
    }

    private static func redacted(_ path: String) -> String {
        let homePath = MacEnvironment.homePath
        if path == homePath { return "~" }
        if path.hasPrefix(homePath + "/") {
            return "~" + String(path.dropFirst(homePath.count))
        }
        return path
    }
}
