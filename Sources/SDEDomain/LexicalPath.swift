public enum LexicalPath {
    public static func normalize(_ path: String) -> String {
        guard !path.isEmpty else { return path }

        let isAbsolute = path.hasPrefix("/")
        var components: [Substring] = []

        for component in path.split(separator: "/", omittingEmptySubsequences: true) {
            if component == "." { continue }
            if component == ".." {
                if !components.isEmpty { components.removeLast() }
                continue
            }
            components.append(component)
        }

        let joined = components.joined(separator: "/")
        if isAbsolute {
            return joined.isEmpty ? "/" : "/" + joined
        }
        return joined
    }
}
