import Foundation
import Network

// MARK: - Message Types

enum CompanionMessageType: String, Codable, Sendable {
    // Sync
    case syncFull = "sync.full"

    // Events (iOS -> macOS)
    case eventHttpRequest = "event.httpRequest"
    case eventWsConnection = "event.wsConnection"
    case eventWsFrame = "event.wsFrame"
    case eventWsStatusChange = "event.wsStatusChange"
    case eventLog = "event.log"
    case eventEnvironmentChange = "event.environmentChange"
    case eventRulesChange = "event.rulesChange"
    case eventQAUpdate = "event.qaUpdate"
    case eventUserDefaultsChange = "event.userDefaultsChange"
    case eventKeychainChange = "event.keychainChange"

    // Commands (macOS -> iOS)
    case commandSwitchEnvironment = "command.switchEnvironment"
    case commandClearStore = "command.clearStore"
    case commandToggleRule = "command.toggleRule"
    case commandReplayRequest = "command.replayRequest"
    case commandFireDeepLink = "command.fireDeepLink"
    case commandMarkQAPassed = "command.markQAPassed"
    case commandMarkQAFailed = "command.markQAFailed"
    case commandResetQAItem = "command.resetQAItem"

    // Heartbeat
    case heartbeat = "heartbeat"
}

// MARK: - Message Envelope

struct CompanionMessage: Codable, Sendable {
    let type: CompanionMessageType
    let payload: Data
    let timestamp: Date

    init(type: CompanionMessageType, payload: Data = Data(), timestamp: Date = Date()) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
    }

    init<T: Encodable>(type: CompanionMessageType, payload: T) throws {
        self.type = type
        self.payload = try JSONEncoder().encode(payload)
        self.timestamp = Date()
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: payload)
    }
}

// MARK: - NWProtocolFramer: Length-Prefixed JSON

/// Wire format: [4 bytes big-endian UInt32 length][JSON bytes of CompanionMessage]
final class CompanionFramer: NWProtocolFramerImplementation {

    static let definition = NWProtocolFramer.Definition(implementation: CompanionFramer.self)
    static let label = "CompanionFramer"

    required init(framer: NWProtocolFramer.Instance) {}

    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        .ready
    }

    func stop(framer: NWProtocolFramer.Instance) -> Bool {
        true
    }

    func wakeup(framer: NWProtocolFramer.Instance) {}

    func cleanup(framer: NWProtocolFramer.Instance) {}

    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            var lengthBuffer = Data(count: 4)
            var tempLength: UInt32 = 0

            let parsed = framer.parseInput(minimumIncompleteLength: 4, maximumLength: 4) { buffer, _ in
                guard let buffer, buffer.count >= 4 else { return 0 }
                lengthBuffer = Data(buffer.prefix(4))
                tempLength = lengthBuffer.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                return 4
            }

            guard parsed, tempLength > 0 else {
                return 4
            }

            let messageLength = Int(tempLength)

            let message = NWProtocolFramer.Message(companionMessageType: "data")
            if !framer.deliverInputNoCopy(length: messageLength, message: message, isComplete: true) {
                return 0
            }
        }
    }

    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        // Write the length prefix
        var length = UInt32(messageLength).bigEndian
        framer.writeOutput(data: Data(bytes: &length, count: 4))

        // Write the message body
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        } catch {
            // If writeOutputNoCopy fails, the connection will handle the error
        }
    }
}

// MARK: - NWProtocolFramer.Message helpers

extension NWProtocolFramer.Message {
    convenience init(companionMessageType: String) {
        self.init(definition: CompanionFramer.definition)
        self["CompanionMessageType"] = companionMessageType
    }
}

// MARK: - NWParameters helper

extension NWParameters {
    static var companionTCP: NWParameters {
        let tcp = NWProtocolTCP.Options()
        tcp.enableKeepalive = true
        tcp.keepaliveIdle = 5

        let params = NWParameters(tls: nil, tcp: tcp)
        let framerOptions = NWProtocolFramer.Options(definition: CompanionFramer.definition)
        params.defaultProtocolStack.applicationProtocols.insert(framerOptions, at: 0)
        return params
    }
}

// MARK: - Connection send/receive helpers

extension NWConnection {
    func sendCompanionMessage(_ message: CompanionMessage, on queue: DispatchQueue, completion: @escaping @Sendable (Error?) -> Void) {
        do {
            let data = try JSONEncoder().encode(message)
            let metadata = NWProtocolFramer.Message(companionMessageType: message.type.rawValue)
            let context = NWConnection.ContentContext(
                identifier: "CompanionMessage",
                metadata: [metadata]
            )
            self.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
                completion(error as Error?)
            }))
        } catch {
            completion(error)
        }
    }

    func receiveCompanionMessage(on queue: DispatchQueue, handler: @escaping @Sendable (CompanionMessage?, Error?) -> Void) {
        self.receiveMessage { data, context, _, error in
            if let error {
                handler(nil, error)
                return
            }
            guard let data else {
                handler(nil, nil)
                return
            }
            do {
                let message = try JSONDecoder().decode(CompanionMessage.self, from: data)
                handler(message, nil)
            } catch {
                handler(nil, error)
            }
        }
    }
}
