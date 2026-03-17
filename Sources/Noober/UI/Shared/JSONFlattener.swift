import Foundation

/// Flattens nested JSON into dot-notation key-value pairs for browseable display.
enum JSONFlattener {

    struct KeyValue: Identifiable, Sendable {
        let id: String  // full key path, used as identity
        let key: String
        let value: String
        let depth: Int
        let isLeaf: Bool
    }

    /// Flattens JSON data into an array of key-value pairs with dot-notation keys.
    static func flatten(_ data: Data) -> [KeyValue] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return [] }
        var result: [KeyValue] = []
        flattenValue(json, prefix: "", depth: 0, into: &result)
        return result
    }

    /// Flattens a JSON string into an array of key-value pairs.
    static func flatten(_ string: String) -> [KeyValue] {
        guard let data = string.data(using: .utf8) else { return [] }
        return flatten(data)
    }

    private static func flattenValue(_ value: Any, prefix: String, depth: Int, into result: inout [KeyValue]) {
        if let dict = value as? [String: Any] {
            if dict.isEmpty {
                result.append(KeyValue(id: prefix.isEmpty ? "{}" : prefix, key: prefix.isEmpty ? "(root)" : prefix, value: "{}", depth: depth, isLeaf: true))
                return
            }
            for key in dict.keys.sorted() {
                let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
                let child = dict[key]!
                if child is [String: Any] || child is [Any] {
                    // Add a group header
                    let summary = child is [String: Any]
                        ? "{\((child as! [String: Any]).count) keys}"
                        : "[\((child as! [Any]).count) items]"
                    result.append(KeyValue(id: fullKey, key: fullKey, value: summary, depth: depth, isLeaf: false))
                    flattenValue(child, prefix: fullKey, depth: depth + 1, into: &result)
                } else {
                    result.append(KeyValue(id: fullKey, key: fullKey, value: stringValue(child), depth: depth, isLeaf: true))
                }
            }
        } else if let array = value as? [Any] {
            if array.isEmpty {
                result.append(KeyValue(id: prefix.isEmpty ? "[]" : prefix, key: prefix.isEmpty ? "(root)" : prefix, value: "[]", depth: depth, isLeaf: true))
                return
            }
            for (index, element) in array.enumerated() {
                let fullKey = prefix.isEmpty ? "[\(index)]" : "\(prefix)[\(index)]"
                if element is [String: Any] || element is [Any] {
                    let summary = element is [String: Any]
                        ? "{\((element as! [String: Any]).count) keys}"
                        : "[\((element as! [Any]).count) items]"
                    result.append(KeyValue(id: fullKey, key: fullKey, value: summary, depth: depth, isLeaf: false))
                    flattenValue(element, prefix: fullKey, depth: depth + 1, into: &result)
                } else {
                    result.append(KeyValue(id: fullKey, key: fullKey, value: stringValue(element), depth: depth, isLeaf: true))
                }
            }
        } else {
            let key = prefix.isEmpty ? "(value)" : prefix
            result.append(KeyValue(id: key, key: key, value: stringValue(value), depth: depth, isLeaf: true))
        }
    }

    private static func stringValue(_ value: Any) -> String {
        switch value {
        case is NSNull:
            return "null"
        case let bool as Bool:
            return bool ? "true" : "false"
        case let number as NSNumber:
            // Check if it's actually a boolean (NSNumber wraps bools)
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        case let string as String:
            return string
        default:
            return String(describing: value)
        }
    }
}
