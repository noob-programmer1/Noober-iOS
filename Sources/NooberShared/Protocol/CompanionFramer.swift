import Foundation
import Network

public class CompanionFramer: NWProtocolFramerImplementation {
    public static let label = "NooberCompanion"

    public static let definition = NWProtocolFramer.Definition(implementation: CompanionFramer.self)

    // Length prefix size: 4 bytes (UInt32, big-endian)
    private static let headerSize = 4

    public required init(framer: NWProtocolFramer.Instance) {}

    public func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        .ready
    }

    public func stop(framer: NWProtocolFramer.Instance) -> Bool {
        true
    }

    public func wakeup(framer: NWProtocolFramer.Instance) {}

    public func cleanup(framer: NWProtocolFramer.Instance) {}

    public func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            // Peek at the 4-byte length header to determine message size.
            var messageLength: UInt32 = 0
            let headerParsed = framer.parseInput(
                minimumIncompleteLength: Self.headerSize,
                maximumLength: Self.headerSize
            ) { buffer, _ in
                guard let buffer, buffer.count >= Self.headerSize else {
                    return 0
                }
                messageLength = buffer.loadUnaligned(as: UInt32.self).bigEndian
                // Consume the 4-byte header.
                return Self.headerSize
            }

            guard headerParsed, messageLength > 0 else {
                return Self.headerSize
            }

            // Now deliver the message body (without the header) to the application.
            let message = NWProtocolFramer.Message(definition: Self.definition)
            if !framer.deliverInputNoCopy(
                length: Int(messageLength),
                message: message,
                isComplete: true
            ) {
                return 0
            }
        }
    }

    public func handleOutput(
        framer: NWProtocolFramer.Instance,
        message: NWProtocolFramer.Message,
        messageLength: Int,
        isComplete: Bool
    ) {
        // Write the 4-byte big-endian length prefix.
        var length = UInt32(messageLength).bigEndian
        let header = Data(bytes: &length, count: Self.headerSize)

        framer.writeOutput(data: header)

        // Write the actual message body by passing through the content.
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        } catch {
            // If writeOutputNoCopy fails, the connection will report the error.
        }
    }
}
