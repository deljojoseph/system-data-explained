import Darwin
import Foundation
import SDEDomain

/// Opens one component at a time: no alias or symbolic-link substitution is accepted.
enum ObservedFileAccess {
    static func openPath(_ path: String) -> Int32? {
        guard path.hasPrefix("/"), !path.utf8.contains(0) else { return nil }
        let parts = path.split(separator: "/").map(String.init)
        guard !parts.isEmpty, !parts.contains(".."), !parts.contains(".") else { return nil }
        var descriptor = open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard descriptor >= 0 else { return nil }
        for (index, part) in parts.enumerated() {
            let flags = O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK | (index < parts.count - 1 ? O_DIRECTORY : 0)
            let next = openat(descriptor, part, flags)
            let failure = errno
            close(descriptor)
            guard next >= 0 else { errno = failure; return nil }
            descriptor = next
        }
        return descriptor
    }

    static func identity(_ info: stat) -> FileIdentity {
        FileIdentity(device: UInt64(UInt32(bitPattern: info.st_dev)), inode: UInt64(info.st_ino))
    }

    static func verifiedDescriptor(_ location: ObservedLocation) -> Int32? {
        guard let descriptor = openPath(location.path) else { return nil }
        var info = stat()
        guard fstat(descriptor, &info) == 0, identity(info) == location.identity,
              (info.st_mode & S_IFMT) == S_IFDIR || (info.st_mode & S_IFMT) == S_IFREG else {
            close(descriptor)
            return nil
        }
        return descriptor
    }
}
