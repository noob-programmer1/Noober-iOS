import Foundation

@MainActor
final class QAChecklistStore: ObservableObject {

    static let shared = QAChecklistStore()

    @Published private(set) var results: [QAChecklistResult] = []
    @Published private(set) var buildNumber: String = ""

    private let resultsKeyPrefix = "com.noober.qaChecklist.results."
    private let buildKey = "com.noober.qaChecklist.buildNumber"

    private init() {
        loadCurrentBuild()
    }

    // MARK: - Computed

    var sortedResults: [QAChecklistResult] {
        results.sorted { $0.priority < $1.priority }
    }

    var totalCount: Int { results.count }
    var passedCount: Int { results.filter { $0.status == .passed }.count }
    var failedCount: Int { results.filter { $0.status == .failed }.count }
    var pendingCount: Int { results.filter { $0.status == .pending }.count }

    var isEmpty: Bool { results.isEmpty }

    // MARK: - Registration

    func register(_ items: [QAChecklistItem]) {
        let currentBuild = Self.currentAppBuild()

        if currentBuild != buildNumber {
            clearPersistedResults(for: buildNumber)
            buildNumber = currentBuild
            UserDefaults.standard.set(currentBuild, forKey: buildKey)
            results = items.map { QAChecklistResult(from: $0) }
        } else {
            let existingByTitle: [String: QAChecklistResult] = Dictionary(
                results.map { ($0.title, $0) },
                uniquingKeysWith: { first, _ in first }
            )

            results = items.map { item in
                if let existing = existingByTitle[item.title] {
                    return QAChecklistResult(preservingStatusFrom: existing, updatingMetadataFrom: item)
                }
                return QAChecklistResult(from: item)
            }
        }
        save()
    }

    // MARK: - Status Updates

    func markPassed(id: UUID) {
        guard let index = results.firstIndex(where: { $0.id == id }) else { return }
        results[index].status = .passed
        results[index].failNotes = ""
        results[index].attachedRequestIds = []
        save()
    }

    func markFailed(id: UUID, notes: String, requestIds: [UUID]) {
        guard let index = results.firstIndex(where: { $0.id == id }) else { return }
        results[index].status = .failed
        results[index].failNotes = notes
        results[index].attachedRequestIds = requestIds
        save()
    }

    func resetItem(id: UUID) {
        guard let index = results.firstIndex(where: { $0.id == id }) else { return }
        results[index].status = .pending
        results[index].failNotes = ""
        results[index].attachedRequestIds = []
        save()
    }

    // MARK: - Cleanup

    func clearAll() {
        clearPersistedResults(for: buildNumber)
        results.removeAll()
        buildNumber = ""
        UserDefaults.standard.removeObject(forKey: buildKey)
    }

    // MARK: - Persistence

    private var resultsKey: String {
        resultsKeyPrefix + buildNumber
    }

    private func save() {
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: resultsKey)
        }
    }

    private func loadCurrentBuild() {
        guard let saved = UserDefaults.standard.string(forKey: buildKey) else { return }
        let current = Self.currentAppBuild()
        if saved == current {
            buildNumber = saved
            if let data = UserDefaults.standard.data(forKey: resultsKeyPrefix + saved),
               let loaded = try? JSONDecoder().decode([QAChecklistResult].self, from: data) {
                results = loaded
            }
        } else {
            clearPersistedResults(for: saved)
            UserDefaults.standard.removeObject(forKey: buildKey)
        }
    }

    private func clearPersistedResults(for build: String) {
        guard !build.isEmpty else { return }
        UserDefaults.standard.removeObject(forKey: resultsKeyPrefix + build)
    }

    // MARK: - Build Number

    private static func currentAppBuild() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }
}
