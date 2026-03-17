import Foundation

/// Thread-safe snapshot storage accessed from NetworkInterceptor (arbitrary threads).
enum RulesSnapshot: Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var _rewriteRules: [URLRewriteRule] = []
    private nonisolated(unsafe) static var _mockRules: [MockRule] = []
    private nonisolated(unsafe) static var _interceptRules: [InterceptRule] = []

    static func update(rewriteRules: [URLRewriteRule], mockRules: [MockRule], interceptRules: [InterceptRule]) {
        lock.lock()
        _rewriteRules = rewriteRules
        _mockRules = mockRules
        _interceptRules = interceptRules
        lock.unlock()
    }

    static func findMatchingMock(for request: URLRequest) -> MockRule? {
        lock.lock()
        let mocks = _mockRules
        lock.unlock()
        return mocks.first { $0.matches(request) }
    }

    static func findMatchingIntercept(for request: URLRequest) -> InterceptRule? {
        lock.lock()
        let rules = _interceptRules
        lock.unlock()
        return rules.first { $0.matches(request) }
    }

    static func findRewriteURL(for url: URL) -> URL? {
        lock.lock()
        let rules = _rewriteRules
        lock.unlock()
        for rule in rules {
            if let rewritten = rule.apply(to: url) { return rewritten }
        }
        return nil
    }
}

@MainActor
final class RulesStore: ObservableObject {

    static let shared = RulesStore()

    @Published private(set) var rewriteRules: [URLRewriteRule] = []
    @Published private(set) var mockRules: [MockRule] = []
    @Published private(set) var interceptRules: [InterceptRule] = []

    private let rewriteKey = "com.noober.rewriteRules"
    private let mockKey = "com.noober.mockRules"
    private let interceptKey = "com.noober.interceptRules"

    private init() {
        loadRules()
        syncSnapshots()
    }

    // MARK: - Rewrite Rules CRUD

    func addRewriteRule(_ rule: URLRewriteRule) {
        rewriteRules.insert(rule, at: 0)
        saveAndSync()
    }

    func updateRewriteRule(_ rule: URLRewriteRule) {
        if let index = rewriteRules.firstIndex(where: { $0.id == rule.id }) {
            rewriteRules[index] = rule
            saveAndSync()
        }
    }

    func deleteRewriteRule(_ rule: URLRewriteRule) {
        rewriteRules.removeAll { $0.id == rule.id }
        saveAndSync()
    }

    func toggleRewriteRule(_ rule: URLRewriteRule) {
        if let index = rewriteRules.firstIndex(where: { $0.id == rule.id }) {
            var updated = rewriteRules[index]
            updated.isEnabled.toggle()
            rewriteRules[index] = updated
            saveAndSync()
        }
    }

    func moveRewriteRule(from source: IndexSet, to destination: Int) {
        rewriteRules.move(fromOffsets: source, toOffset: destination)
        saveAndSync()
    }

    // MARK: - Mock Rules CRUD

    func addMockRule(_ rule: MockRule) {
        mockRules.insert(rule, at: 0)
        saveAndSync()
    }

    func updateMockRule(_ rule: MockRule) {
        if let index = mockRules.firstIndex(where: { $0.id == rule.id }) {
            mockRules[index] = rule
            saveAndSync()
        }
    }

    func deleteMockRule(_ rule: MockRule) {
        mockRules.removeAll { $0.id == rule.id }
        saveAndSync()
    }

    func toggleMockRule(_ rule: MockRule) {
        if let index = mockRules.firstIndex(where: { $0.id == rule.id }) {
            var updated = mockRules[index]
            updated.isEnabled.toggle()
            mockRules[index] = updated
            saveAndSync()
        }
    }

    func moveMockRule(from source: IndexSet, to destination: Int) {
        mockRules.move(fromOffsets: source, toOffset: destination)
        saveAndSync()
    }

    func clearAllRewriteRules() {
        rewriteRules.removeAll()
        saveAndSync()
    }

    func clearAllMockRules() {
        mockRules.removeAll()
        saveAndSync()
    }

    // MARK: - Intercept Rules CRUD

    func addInterceptRule(_ rule: InterceptRule) {
        interceptRules.insert(rule, at: 0)
        saveAndSync()
    }

    func updateInterceptRule(_ rule: InterceptRule) {
        if let index = interceptRules.firstIndex(where: { $0.id == rule.id }) {
            interceptRules[index] = rule
            saveAndSync()
        }
    }

    func deleteInterceptRule(_ rule: InterceptRule) {
        interceptRules.removeAll { $0.id == rule.id }
        saveAndSync()
    }

    func toggleInterceptRule(_ rule: InterceptRule) {
        if let index = interceptRules.firstIndex(where: { $0.id == rule.id }) {
            var updated = interceptRules[index]
            updated.isEnabled.toggle()
            interceptRules[index] = updated
            saveAndSync()
        }
    }

    func moveInterceptRule(from source: IndexSet, to destination: Int) {
        interceptRules.move(fromOffsets: source, toOffset: destination)
        saveAndSync()
    }

    func clearAllInterceptRules() {
        interceptRules.removeAll()
        saveAndSync()
    }

    // MARK: - Persistence

    private func loadRules() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: rewriteKey),
           let rules = try? decoder.decode([URLRewriteRule].self, from: data) {
            rewriteRules = rules
        }
        if let data = UserDefaults.standard.data(forKey: mockKey),
           let rules = try? decoder.decode([MockRule].self, from: data) {
            mockRules = rules
        }
        if let data = UserDefaults.standard.data(forKey: interceptKey),
           let rules = try? decoder.decode([InterceptRule].self, from: data) {
            interceptRules = rules
        }
    }

    private func saveAndSync() {
        saveRules()
        syncSnapshots()
    }

    private func saveRules() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(rewriteRules) {
            UserDefaults.standard.set(data, forKey: rewriteKey)
        }
        if let data = try? encoder.encode(mockRules) {
            UserDefaults.standard.set(data, forKey: mockKey)
        }
        if let data = try? encoder.encode(interceptRules) {
            UserDefaults.standard.set(data, forKey: interceptKey)
        }
    }

    private func syncSnapshots() {
        RulesSnapshot.update(
            rewriteRules: rewriteRules.filter(\.isEnabled),
            mockRules: mockRules.filter(\.isEnabled),
            interceptRules: interceptRules.filter(\.isEnabled)
        )
    }
}
