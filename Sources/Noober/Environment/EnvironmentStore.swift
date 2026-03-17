import Foundation

// MARK: - Thread-safe snapshot for NetworkInterceptor

enum EnvironmentSnapshot: Sendable {

    struct Rewrite: Sendable {
        let fromHost: String
        let toScheme: String
        let toHost: String
        let toPort: Int?
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var _rewrites: [Rewrite] = []

    /// Rewrite URL if environment rewrite is active and host matches any registered pair.
    /// Replaces scheme + host + port, preserves path/query/fragment.
    static func rewriteURL(for url: URL) -> URL? {
        lock.lock()
        let rewrites = _rewrites
        lock.unlock()

        guard let host = url.host else { return nil }

        for rw in rewrites {
            if host.caseInsensitiveCompare(rw.fromHost) == .orderedSame,
               var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.scheme = rw.toScheme
                components.host = rw.toHost
                components.port = rw.toPort
                return components.url
            }
        }
        return nil
    }

    static func sync(rewrites: [Rewrite]) {
        lock.lock()
        _rewrites = rewrites
        lock.unlock()
    }
}

// MARK: - EnvironmentStore

@MainActor
final class EnvironmentStore: ObservableObject {

    static let shared = EnvironmentStore()

    @Published private(set) var environments: [NooberEnvironment] = []
    @Published private(set) var activeEnvironmentId: UUID?

    private let environmentsKey = "com.noober.environments"
    private let activeIdKey = "com.noober.activeEnvironmentId"

    private init() {
        loadFromDisk()
        syncSnapshot()
    }

    /// The currently active environment.
    var activeEnvironment: NooberEnvironment? {
        environments.first { $0.id == activeEnvironmentId }
    }

    /// The default (first) environment.
    var defaultEnvironment: NooberEnvironment? {
        environments.first
    }

    /// Whether a non-default environment is active (i.e., rewriting is happening).
    var isRewriting: Bool {
        guard let activeId = activeEnvironmentId,
              let defaultEnv = environments.first else { return false }
        return activeId != defaultEnv.id
    }

    // MARK: - Registration

    func register(_ envs: [NooberEnvironment]) {
        environments = envs
        saveEnvironments()

        // Restore previously active env if it still exists, otherwise default to first
        if let savedId = loadActiveId(), envs.contains(where: { $0.id == savedId }) {
            activeEnvironmentId = savedId
        } else {
            activeEnvironmentId = envs.first?.id
            saveActiveId()
        }
        syncSnapshot()
    }

    // MARK: - Switching

    func activate(id: UUID) {
        guard environments.contains(where: { $0.id == id }) else { return }
        activeEnvironmentId = id
        saveActiveId()
        syncSnapshot()
    }

    // MARK: - Cleanup

    func clearAll() {
        environments.removeAll()
        activeEnvironmentId = nil
        UserDefaults.standard.removeObject(forKey: environmentsKey)
        UserDefaults.standard.removeObject(forKey: activeIdKey)
        EnvironmentSnapshot.sync(rewrites: [])
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: environmentsKey),
           let envs = try? JSONDecoder().decode([NooberEnvironment].self, from: data) {
            environments = envs
        }
        if let savedId = loadActiveId() {
            activeEnvironmentId = savedId
        }
    }

    private func loadActiveId() -> UUID? {
        guard let str = UserDefaults.standard.string(forKey: activeIdKey) else { return nil }
        return UUID(uuidString: str)
    }

    private func saveEnvironments() {
        if let data = try? JSONEncoder().encode(environments) {
            UserDefaults.standard.set(data, forKey: environmentsKey)
        }
    }

    private func saveActiveId() {
        UserDefaults.standard.set(activeEnvironmentId?.uuidString, forKey: activeIdKey)
    }

    // MARK: - Snapshot Sync

    /// Builds positional rewrite pairs: defaultEnv.baseURLs[i] → activeEnv.baseURLs[i]
    private func syncSnapshot() {
        guard let defaultEnv = environments.first,
              let activeEnv = activeEnvironment,
              activeEnv.id != defaultEnv.id
        else {
            EnvironmentSnapshot.sync(rewrites: [])
            return
        }

        var rewrites: [EnvironmentSnapshot.Rewrite] = []
        let count = min(defaultEnv.baseURLs.count, activeEnv.baseURLs.count)

        for i in 0..<count {
            guard let fromURL = URL(string: defaultEnv.baseURLs[i]),
                  let toURL = URL(string: activeEnv.baseURLs[i]),
                  let fromHost = fromURL.host,
                  let toHost = toURL.host,
                  let toScheme = toURL.scheme
            else { continue }

            rewrites.append(.init(
                fromHost: fromHost,
                toScheme: toScheme,
                toHost: toHost,
                toPort: toURL.port
            ))
        }

        EnvironmentSnapshot.sync(rewrites: rewrites)
    }
}
