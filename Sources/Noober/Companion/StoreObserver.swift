import Foundation
import Combine

@MainActor
final class StoreObserver {
    private var cancellables = Set<AnyCancellable>()
    private weak var server: CompanionServer?

    // Tracking state for diffing
    private var lastSeenHTTPRequestId: UUID?
    private var lastSeenWSConnectionIds: Set<UUID> = []
    private var lastSeenWSFrameCounts: [UUID: Int] = [:]
    private var lastSeenLogEntryId: UUID?
    private var lastSeenActiveEnvironmentId: UUID?
    private var lastSeenRewriteRuleCount: Int = 0
    private var lastSeenMockRuleCount: Int = 0
    private var lastSeenInterceptRuleCount: Int = 0
    private var lastSeenQAResults: [UUID: String] = [:]

    init(server: CompanionServer) {
        self.server = server
        snapshotCurrentState()
        observeNetworkStore()
        observeLogStore()
        observeEnvironmentStore()
        observeRulesStore()
        observeQAStore()
        observeUserDefaultsStore()
        observeKeychainStore()
    }

    /// Capture the current state so we only send incremental updates going forward.
    private func snapshotCurrentState() {
        let networkStore = NetworkActivityStore.shared
        lastSeenHTTPRequestId = networkStore.requests.first?.id
        lastSeenWSConnectionIds = Set(networkStore.webSocketConnections.map(\.id))
        for conn in networkStore.webSocketConnections {
            lastSeenWSFrameCounts[conn.id] = conn.frames.count
        }

        lastSeenLogEntryId = LogStore.shared.entries.first?.id

        lastSeenActiveEnvironmentId = EnvironmentStore.shared.activeEnvironmentId

        let rulesStore = RulesStore.shared
        lastSeenRewriteRuleCount = rulesStore.rewriteRules.count
        lastSeenMockRuleCount = rulesStore.mockRules.count
        lastSeenInterceptRuleCount = rulesStore.interceptRules.count

        for result in QAChecklistStore.shared.results {
            lastSeenQAResults[result.id] = result.status.rawValue
        }
    }

    // MARK: - Network

    private func observeNetworkStore() {
        let store = NetworkActivityStore.shared

        store.$requests
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requests in
                guard let self, let server = self.server else { return }
                let newRequests = self.findNewItems(in: requests, lastSeenId: self.lastSeenHTTPRequestId)
                if !newRequests.isEmpty {
                    self.lastSeenHTTPRequestId = requests.first?.id
                    for request in newRequests.reversed() {
                        let transferable = request.toTransferable()
                        if let message = try? CompanionMessage(type: .eventHttpRequest, payload: transferable) {
                            server.send(message)
                        }
                    }
                }
            }
            .store(in: &cancellables)

        store.$webSocketConnections
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connections in
                guard let self, let server = self.server else { return }

                let currentIds = Set(connections.map(\.id))

                // Detect new connections
                let newConnectionIds = currentIds.subtracting(self.lastSeenWSConnectionIds)
                for conn in connections where newConnectionIds.contains(conn.id) {
                    let transferable = conn.toTransferable()
                    if let message = try? CompanionMessage(type: .eventWsConnection, payload: transferable) {
                        server.send(message)
                    }
                    self.lastSeenWSFrameCounts[conn.id] = conn.frames.count
                }

                // Detect new frames on existing connections
                for conn in connections where !newConnectionIds.contains(conn.id) {
                    let previousFrameCount = self.lastSeenWSFrameCounts[conn.id] ?? 0
                    if conn.frames.count > previousFrameCount {
                        let newFrames = conn.frames[previousFrameCount...]
                        for frame in newFrames {
                            let transferable = frame.toTransferable(connectionId: conn.id)
                            if let message = try? CompanionMessage(type: .eventWsFrame, payload: transferable) {
                                server.send(message)
                            }
                        }
                    }
                    self.lastSeenWSFrameCounts[conn.id] = conn.frames.count
                }

                // Detect status changes for existing connections
                for conn in connections where !newConnectionIds.contains(conn.id) {
                    let statusChange = TransferableWSStatusChange(
                        connectionId: conn.id,
                        status: conn.status.rawValue,
                        closeCode: conn.closeCode,
                        closeReason: conn.closeReason
                    )
                    if let message = try? CompanionMessage(type: .eventWsStatusChange, payload: statusChange) {
                        server.send(message)
                    }
                }

                self.lastSeenWSConnectionIds = currentIds
            }
            .store(in: &cancellables)
    }

    // MARK: - Logs

    private func observeLogStore() {
        LogStore.shared.$entries
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                guard let self, let server = self.server else { return }
                let newEntries = self.findNewItems(in: entries, lastSeenId: self.lastSeenLogEntryId)
                if !newEntries.isEmpty {
                    self.lastSeenLogEntryId = entries.first?.id
                    for entry in newEntries.reversed() {
                        let transferable = entry.toTransferable()
                        if let message = try? CompanionMessage(type: .eventLog, payload: transferable) {
                            server.send(message)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Environment

    private func observeEnvironmentStore() {
        let store = EnvironmentStore.shared

        store.$activeEnvironmentId
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeId in
                guard let self, let server = self.server else { return }
                if activeId != self.lastSeenActiveEnvironmentId {
                    self.lastSeenActiveEnvironmentId = activeId
                    let state = TransferableEnvironmentState(
                        environments: store.environments.map { $0.toTransferable() },
                        activeEnvironmentId: activeId
                    )
                    if let message = try? CompanionMessage(type: .eventEnvironmentChange, payload: state) {
                        server.send(message)
                    }
                }
            }
            .store(in: &cancellables)

        store.$environments
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] environments in
                guard let self, let server = self.server else { return }
                let state = TransferableEnvironmentState(
                    environments: environments.map { $0.toTransferable() },
                    activeEnvironmentId: store.activeEnvironmentId
                )
                if let message = try? CompanionMessage(type: .eventEnvironmentChange, payload: state) {
                    server.send(message)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Rules

    private func observeRulesStore() {
        let store = RulesStore.shared

        // Observe all three rule types with a merged publisher
        store.$rewriteRules
            .combineLatest(store.$mockRules, store.$interceptRules)
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rewrite, mock, intercept in
                guard let self, let server = self.server else { return }
                let changed = rewrite.count != self.lastSeenRewriteRuleCount
                    || mock.count != self.lastSeenMockRuleCount
                    || intercept.count != self.lastSeenInterceptRuleCount
                    || true // Always send on any publish event since toggling doesn't change count
                if changed {
                    self.lastSeenRewriteRuleCount = rewrite.count
                    self.lastSeenMockRuleCount = mock.count
                    self.lastSeenInterceptRuleCount = intercept.count
                    let state = TransferableRulesState(
                        rewriteRules: rewrite.map { $0.toTransferable() },
                        mockRules: mock.map { $0.toTransferable() },
                        interceptRules: intercept.map { $0.toTransferable() }
                    )
                    if let message = try? CompanionMessage(type: .eventRulesChange, payload: state) {
                        server.send(message)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - QA Checklist

    private func observeQAStore() {
        QAChecklistStore.shared.$results
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self, let server = self.server else { return }
                // Check if any status changed
                var changed = results.count != self.lastSeenQAResults.count
                if !changed {
                    for result in results {
                        if self.lastSeenQAResults[result.id] != result.status.rawValue {
                            changed = true
                            break
                        }
                    }
                }
                if changed {
                    self.lastSeenQAResults = Dictionary(
                        uniqueKeysWithValues: results.map { ($0.id, $0.status.rawValue) }
                    )
                    let store = QAChecklistStore.shared
                    let state = TransferableQAState(
                        results: results.map { $0.toTransferable() },
                        buildNumber: store.buildNumber
                    )
                    if let message = try? CompanionMessage(type: .eventQAUpdate, payload: state) {
                        server.send(message)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UserDefaults

    private func observeUserDefaultsStore() {
        UserDefaultsStore.shared.$entries
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                guard let self, let server = self.server else { return }
                let transferable = entries.map { $0.toTransferable() }
                if let message = try? CompanionMessage(type: .eventUserDefaultsChange, payload: transferable) {
                    server.send(message)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Keychain

    private func observeKeychainStore() {
        KeychainStore.shared.$entries
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                guard let self, let server = self.server else { return }
                let transferable = entries.map { $0.toTransferable() }
                if let message = try? CompanionMessage(type: .eventKeychainChange, payload: transferable) {
                    server.send(message)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Diffing Helper

    /// Finds new items inserted at the front of the array since the last known first ID.
    /// Items are inserted at index 0, so everything before the old first item is new.
    private func findNewItems<T: Identifiable>(in items: [T], lastSeenId: T.ID?) -> [T] {
        guard let lastSeenId else {
            // First time observing - everything is new
            return items
        }
        guard let anchorIndex = items.firstIndex(where: { $0.id as AnyHashable == lastSeenId as AnyHashable }) else {
            // Old anchor not found (possibly cleared) - treat all as new
            return items
        }
        if anchorIndex == 0 {
            return []
        }
        return Array(items[0..<anchorIndex])
    }

    func cancel() {
        cancellables.removeAll()
    }
}
