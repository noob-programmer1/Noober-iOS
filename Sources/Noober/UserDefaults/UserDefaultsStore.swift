import Foundation
import UIKit

@MainActor
final class UserDefaultsStore: ObservableObject {

    static let shared = UserDefaultsStore()

    @Published private(set) var entries: [UserDefaultsEntry] = []
    @Published var showSystemKeys = false {
        didSet { refresh() }
    }

    private let systemPrefixes = [
        "Apple", "NS", "com.apple.", "INNext", "AK", "PK",
        "AddingEmojiKeybordHandled", "UIKeyboard",
    ]

    private init() {}

    // MARK: - Read

    func refresh() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        entries = dict.keys.sorted().compactMap { key in
            if !showSystemKeys && isSystemKey(key) { return nil }
            let value = dict[key]!
            return UserDefaultsEntry(
                id: key,
                key: key,
                displayValue: stringRepresentation(value),
                valueType: detectType(value)
            )
        }
    }

    // MARK: - Write (smart type detection)

    func setValue(_ valueString: String, forKey key: String) {
        let parsed = parseSmartValue(valueString)
        UserDefaults.standard.set(parsed, forKey: key)
        refresh()
    }

    // MARK: - Delete

    func deleteEntry(_ entry: UserDefaultsEntry) {
        UserDefaults.standard.removeObject(forKey: entry.key)
        refresh()
    }

    func clearAll() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        for key in dict.keys where !isSystemKey(key) {
            UserDefaults.standard.removeObject(forKey: key)
        }
        refresh()
    }

    // MARK: - Duplicate

    func duplicateEntry(_ entry: UserDefaultsEntry) {
        var newKey = entry.key + "_copy"
        // Ensure uniqueness
        while UserDefaults.standard.object(forKey: newKey) != nil {
            newKey += "_copy"
        }
        if let value = UserDefaults.standard.object(forKey: entry.key) {
            UserDefaults.standard.set(value, forKey: newKey)
        }
        refresh()
    }

    // MARK: - Export

    func exportJSON() -> String {
        let dict = UserDefaults.standard.dictionaryRepresentation()
            .filter { !isSystemKey($0.key) }
        let serializable = dict.reduce(into: [String: Any]()) { result, pair in
            if JSONSerialization.isValidJSONObject([pair.key: pair.value]) {
                result[pair.key] = pair.value
            } else {
                result[pair.key] = String(describing: pair.value)
            }
        }
        guard let data = try? JSONSerialization.data(
            withJSONObject: serializable,
            options: [.prettyPrinted, .sortedKeys]
        ),
        let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    func shareExport() {
        let json = exportJSON()
        let av = UIActivityViewController(activityItems: [json], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            let topWindow = scene.windows
                .filter { !$0.isHidden }
                .sorted(by: { $0.windowLevel.rawValue < $1.windowLevel.rawValue })
                .last
            var vc = topWindow?.rootViewController
            while let presented = vc?.presentedViewController {
                vc = presented
            }
            vc?.present(av, animated: true)
        }
    }

    // MARK: - Editable value

    func editableValue(forKey key: String) -> String {
        guard let value = UserDefaults.standard.object(forKey: key) else { return "" }
        return stringRepresentation(value)
    }

    // MARK: - Smart type parsing

    private func parseSmartValue(_ string: String) -> Any {
        // 1. Bool (check before Int since "true"/"false" aren't valid ints)
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)
        if lower == "true" { return true }
        if lower == "false" { return false }
        // 2. Int
        if let intVal = Int(string) { return intVal }
        // 3. Double
        if let doubleVal = Double(string), string.contains(".") { return doubleVal }
        // 4. JSON (array or dictionary)
        if let data = string.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data),
           JSONSerialization.isValidJSONObject(json) {
            return json
        }
        // 5. Fallback: String
        return string
    }

    // MARK: - Helpers

    private func isSystemKey(_ key: String) -> Bool {
        if key.hasPrefix("_") { return true }
        return systemPrefixes.contains { key.hasPrefix($0) }
    }

    private func detectType(_ value: Any) -> UserDefaultsEntry.ValueType {
        // NSNumber wraps both Bool and numeric types — check Bool first
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool
            }
            // Check if it's an integer by comparing to its Int representation
            if number.doubleValue == Double(number.intValue) && !String(describing: value).contains(".") {
                return .int
            }
            return .double
        }
        switch value {
        case is String: return .string
        case is Data:   return .data
        case is Date:   return .date
        case is [Any]:  return .array
        case is [String: Any]: return .dictionary
        default: return .unknown
        }
    }

    private func stringRepresentation(_ value: Any) -> String {
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }
        switch value {
        case let string as String:
            return string
        case let data as Data:
            return "(Data, \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)))"
        case let date as Date:
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .medium
            return f.string(from: date)
        case let array as [Any]:
            if let jsonData = try? JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted]),
               let str = String(data: jsonData, encoding: .utf8) {
                return str
            }
            return "[\(array.count) items]"
        case let dict as [String: Any]:
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
               let str = String(data: jsonData, encoding: .utf8) {
                return str
            }
            return "{\(dict.count) keys}"
        default:
            return String(describing: value)
        }
    }
}
