import Foundation
import Network
import Combine
import UIKit

@MainActor
final class CompanionServer {

    static let shared = CompanionServer()

    private var listener: NWListener?
    private var activeConnection: NWConnection?
    private var observer: StoreObserver?
    private let queue = DispatchQueue(label: "com.noober.companion", qos: .userInitiated)

    private var heartbeatTimer: Timer?
    private var pendingSendCount: Int = 0
    private let maxPendingSends = 64

    private(set) var isConnected = false

    private init() {}

    // MARK: - Start / Stop

    func startAdvertising() {
        guard listener == nil else { return }

        do {
            let parameters = NWParameters.companionTCP
            let listener = try NWListener(using: parameters)

            let serviceName = UIDevice.current.name
            listener.service = NWListener.Service(name: serviceName, type: "_noober._tcp")

            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    self?.handleListenerState(state)
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleNewConnection(connection)
                }
            }

            self.listener = listener
            listener.start(queue: queue)
        } catch {
            // Failed to create listener - silently ignore.
            // Companion is a nice-to-have feature.
        }
    }

    func stopAdvertising() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        observer?.cancel()
        observer = nil

        activeConnection?.cancel()
        activeConnection = nil

        listener?.cancel()
        listener = nil

        isConnected = false
        pendingSendCount = 0
    }

    // MARK: - Send

    func send(_ message: CompanionMessage) {
        guard let connection = activeConnection, isConnected else { return }

        // Back-pressure: skip non-critical messages if too many are in flight
        if pendingSendCount >= maxPendingSends {
            // Drop non-heartbeat, non-sync messages under pressure
            if message.type != .heartbeat && message.type != .syncFull {
                return
            }
        }

        pendingSendCount += 1
        connection.sendCompanionMessage(message, on: queue) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.pendingSendCount = max(0, self.pendingSendCount - 1)
                if error != nil {
                    self.handleConnectionLost()
                }
            }
        }
    }

    // MARK: - Listener State

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            break
        case .failed:
            // Restart after a brief delay
            listener?.cancel()
            listener = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.startAdvertising()
            }
        case .cancelled:
            break
        default:
            break
        }
    }

    // MARK: - Connection Handling

    private func handleNewConnection(_ connection: NWConnection) {
        // If we already have an active connection, cancel it
        if let existing = activeConnection {
            existing.cancel()
            observer?.cancel()
            observer = nil
        }

        activeConnection = connection
        pendingSendCount = 0

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleConnectionState(state)
            }
        }

        connection.start(queue: queue)
    }

    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isConnected = true
            sendFullSync()
            observer = StoreObserver(server: self)
            startHeartbeat()
        case .failed, .cancelled:
            handleConnectionLost()
        case .waiting:
            // Network path changed, connection waiting to try again
            break
        default:
            break
        }
    }

    private func handleConnectionLost() {
        guard isConnected || activeConnection != nil else { return }

        isConnected = false
        pendingSendCount = 0

        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        observer?.cancel()
        observer = nil

        activeConnection?.cancel()
        activeConnection = nil
    }

    // MARK: - Receive

    private func receiveNextMessage() {
        guard let connection = activeConnection else { return }

        connection.receiveCompanionMessage(on: queue) { [weak self] message, error in
            Task { @MainActor in
                guard let self else { return }

                if let error = error as? NWError {
                    self.handleConnectionLost()
                    return
                }

                if let error {
                    // Decode errors (e.g. unknown message type) are NOT fatal —
                    // skip the bad message and keep the connection alive.
                    if error is DecodingError {
                        // Continue receiving
                    } else {
                        self.handleConnectionLost()
                        return
                    }
                }

                if let message {
                    if message.type == .heartbeat {
                        // Heartbeat received - connection is alive
                    } else {
                        CommandHandler.handle(message)
                    }
                }

                // Schedule next receive
                self.receiveNextMessage()
            }
        }
    }

    // MARK: - Full Sync

    private func sendFullSync() {
        let networkStore = NetworkActivityStore.shared
        let logStore = LogStore.shared
        let envStore = EnvironmentStore.shared
        let rulesStore = RulesStore.shared
        let qaStore = QAChecklistStore.shared
        let userDefaultsStore = UserDefaultsStore.shared
        let keychainStore = KeychainStore.shared

        // Refresh stores that need it
        userDefaultsStore.refresh()
        keychainStore.refresh()

        let payload = FullSyncPayload(
            httpRequests: networkStore.requests.map { $0.toTransferable() },
            wsConnections: networkStore.webSocketConnections.map { $0.toTransferable() },
            logEntries: logStore.entries.map { $0.toTransferable() },
            environmentState: TransferableEnvironmentState(
                environments: envStore.environments.map { $0.toTransferable() },
                activeEnvironmentId: envStore.activeEnvironmentId
            ),
            rulesState: TransferableRulesState(
                rewriteRules: rulesStore.rewriteRules.map { $0.toTransferable() },
                mockRules: rulesStore.mockRules.map { $0.toTransferable() },
                interceptRules: rulesStore.interceptRules.map { $0.toTransferable() }
            ),
            qaState: TransferableQAState(
                results: qaStore.results.map { $0.toTransferable() },
                buildNumber: qaStore.buildNumber
            ),
            userDefaultsEntries: userDefaultsStore.entries.map { $0.toTransferable() },
            keychainEntries: keychainStore.entries.map { $0.toTransferable() },
            currentScreen: ScreenTracker.shared.currentScreen,
            deviceName: UIDevice.current.name,
            appName: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? "Unknown",
            appVersion: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"))",
            recordedFlows: FlowRecorder.shared.savedFlows
        )

        if let message = try? CompanionMessage(type: .syncFull, payload: payload) {
            send(message)
        }

        // Start receiving commands after sync
        receiveNextMessage()
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isConnected else { return }
                let heartbeat = CompanionMessage(type: .heartbeat)
                self.send(heartbeat)
            }
        }
    }
}
