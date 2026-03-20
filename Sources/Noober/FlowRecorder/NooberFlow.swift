import Foundation

/// A recorded user flow — replayable sequence of interactions.
public struct NooberFlow: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public var description: String
    public let steps: [NooberFlowStep]
    public let recordedAt: Date
    public let device: DeviceInfo?

    public struct DeviceInfo: Codable, Sendable {
        public let name: String        // "iPhone 16e"
        public let screenWidth: Int    // 393
        public let screenHeight: Int   // 852
        public let scale: Int          // 3

        public init(name: String, screenWidth: Int, screenHeight: Int, scale: Int) {
            self.name = name
            self.screenWidth = screenWidth
            self.screenHeight = screenHeight
            self.scale = scale
        }
    }

    public init(name: String, description: String = "", steps: [NooberFlowStep], recordedAt: Date = Date(), device: DeviceInfo? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.steps = steps
        self.recordedAt = recordedAt
        self.device = device
    }
}

/// A single interaction step in a recorded flow.
public struct NooberFlowStep: Codable, Sendable {

    public enum Action: String, Codable, Sendable {
        case tap
        case swipe
        case typeText = "type_text"
        case longPress = "long_press"
    }

    public struct Coordinates: Codable, Sendable {
        public let x: Double
        public let y: Double

        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }

        public init(x: CGFloat, y: CGFloat) {
            self.x = Double(x)
            self.y = Double(y)
        }
    }

    public let action: Action
    public let screen: String
    public let label: String?
    public let text: String?
    public let startCoordinates: Coordinates?
    public let endCoordinates: Coordinates?  // for swipes
    public let extra: [String: String]?

    public init(
        action: Action,
        screen: String,
        label: String? = nil,
        text: String? = nil,
        startCoordinates: Coordinates? = nil,
        endCoordinates: Coordinates? = nil,
        extra: [String: String]? = nil
    ) {
        self.action = action
        self.screen = screen
        self.label = label
        self.text = text
        self.startCoordinates = startCoordinates
        self.endCoordinates = endCoordinates
        self.extra = extra
    }
}
