import Foundation
import Network

public enum CompanionConnection {
    public static let bonjourType = "_noober._tcp"

    public static func parameters() -> NWParameters {
        let tcp = NWProtocolTCP.Options()
        tcp.noDelay = true
        let params = NWParameters(tls: nil, tcp: tcp)
        let framerOptions = NWProtocolFramer.Options(definition: CompanionFramer.definition)
        params.defaultProtocolStack.applicationProtocols.insert(framerOptions, at: 0)
        return params
    }

    /// Sends a `CompanionMessage` over the given connection using the framer protocol.
    public static func send(
        _ message: CompanionMessage,
        on connection: NWConnection,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        do {
            let data = try JSONEncoder().encode(message)
            let metadata = NWProtocolFramer.Message(definition: CompanionFramer.definition)
            let context = NWConnection.ContentContext(
                identifier: "CompanionMessage",
                metadata: [metadata]
            )
            connection.send(
                content: data,
                contentContext: context,
                isComplete: true,
                completion: .contentProcessed { error in
                    completion(error)
                }
            )
        } catch {
            completion(error)
        }
    }

    /// Receives a single `CompanionMessage` from the connection. Call again inside
    /// the handler to receive subsequent messages (receive loop).
    public static func receive(
        on connection: NWConnection,
        handler: @escaping @Sendable (CompanionMessage?) -> Void
    ) {
        connection.receiveMessage { content, context, isComplete, error in
            guard error == nil,
                  let data = content,
                  !data.isEmpty else {
                handler(nil)
                return
            }

            do {
                let message = try JSONDecoder().decode(CompanionMessage.self, from: data)
                handler(message)
            } catch {
                handler(nil)
            }
        }
    }
}
