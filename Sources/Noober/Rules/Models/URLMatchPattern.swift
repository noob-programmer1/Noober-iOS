import Foundation

enum URLMatchMode: String, Codable, CaseIterable, Sendable {
    case host = "Host"
    case contains = "Contains"
    case prefix = "Prefix"
    case exact = "Exact"
    case regex = "Regex"
}

struct URLMatchPattern: Codable, Sendable, Hashable {
    let mode: URLMatchMode
    let pattern: String

    func matches(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        switch mode {
        case .host:
            return url.host?.lowercased() == pattern.lowercased()
        case .contains:
            return urlString.localizedCaseInsensitiveContains(pattern)
        case .prefix:
            return urlString.lowercased().hasPrefix(pattern.lowercased())
        case .exact:
            return urlString == pattern
        case .regex:
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return false
            }
            return regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) != nil
        }
    }
}
