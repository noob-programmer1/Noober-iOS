import Foundation

@MainActor
final class LogStore: ObservableObject {

    static let shared = LogStore()

    @Published private(set) var entries: [LogEntry] = []

    /// Categories seen so far, in order of first appearance — used for filter chips.
    @Published private(set) var seenCategories: [LogCategory] = []

    private let maxEntries = 500

    private init() {}

    func addEntry(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
        if !seenCategories.contains(entry.category) {
            seenCategories.append(entry.category)
        }
    }

    func clearAll() {
        entries.removeAll()
        seenCategories.removeAll()
    }
}
