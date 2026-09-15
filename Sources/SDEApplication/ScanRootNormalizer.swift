import SDEDomain

public enum ScanRootNormalizer {
    public static func normalize(_ roots: [ScanRoot]) -> [ScanRoot] {
        var uniqueByPath: [String: ScanRoot] = [:]

        for root in roots {
            let standardized = LexicalPath.normalize(root.path)
            guard !standardized.isEmpty else { continue }
            uniqueByPath[standardized] = ScanRoot(path: standardized, displayName: root.displayName, isOptional: root.isOptional)
        }

        let shortestFirst = uniqueByPath.values.sorted {
            if $0.path.count == $1.path.count { return $0.path < $1.path }
            return $0.path.count < $1.path.count
        }

        var accepted: [ScanRoot] = []
        for candidate in shortestFirst {
            let isNested = accepted.contains { parent in
                candidate.path == parent.path || candidate.path.hasPrefix(parent.path + "/")
            }
            if !isNested {
                accepted.append(candidate)
            }
        }

        return accepted.sorted { $0.path < $1.path }
    }
}
