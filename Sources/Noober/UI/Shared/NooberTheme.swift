import SwiftUI
import UIKit

enum NooberTheme {

    // MARK: - Haptics

    static func hapticLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func hapticMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func hapticError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    // MARK: - Colors

    static let accent = Color(red: 0.25, green: 0.48, blue: 1.0)
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let separator = Color(uiColor: .separator)

    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let error = Color(red: 0.95, green: 0.26, blue: 0.21)
    static let info = Color(red: 0.25, green: 0.48, blue: 1.0)
    static let webSocket = Color(red: 0.61, green: 0.35, blue: 0.96)

    static func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET":    return Color(red: 0.25, green: 0.48, blue: 1.0)
        case "POST":   return Color(red: 0.20, green: 0.78, blue: 0.35)
        case "PUT":    return Color(red: 1.0, green: 0.62, blue: 0.04)
        case "PATCH":  return Color(red: 0.61, green: 0.35, blue: 0.96)
        case "DELETE": return Color(red: 0.95, green: 0.26, blue: 0.21)
        case "HEAD":   return Color(red: 0.55, green: 0.55, blue: 0.58)
        default:       return Color(red: 0.55, green: 0.55, blue: 0.58)
        }
    }

    static func statusColor(_ category: NetworkRequestModel.StatusCodeCategory) -> Color {
        switch category {
        case .success:     return success
        case .redirect:    return info
        case .clientError: return warning
        case .serverError: return error
        case .unknown:     return Color(red: 0.55, green: 0.55, blue: 0.58)
        }
    }

    static func contentTypeColor(_ type: NetworkRequestModel.ContentType) -> Color {
        switch type {
        case .json:    return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .image:   return Color(red: 0.85, green: 0.55, blue: 0.20)
        case .xml:     return Color(red: 0.61, green: 0.35, blue: 0.96)
        case .html:    return Color(red: 0.95, green: 0.40, blue: 0.50)
        case .text:    return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .pdf:     return Color(red: 0.90, green: 0.25, blue: 0.20)
        case .binary:  return Color(red: 0.45, green: 0.45, blue: 0.50)
        case .unknown: return Color(red: 0.55, green: 0.55, blue: 0.58)
        }
    }

    static func wsStatusColor(_ status: WebSocketConnectionModel.Status) -> Color {
        switch status {
        case .connecting:    return warning
        case .connected:     return success
        case .disconnected:  return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .error:         return error
        }
    }

    // MARK: - UserDefaults

    static func userDefaultsTypeColor(_ type: UserDefaultsEntry.ValueType) -> Color {
        switch type {
        case .string:              return info
        case .int, .double:        return success
        case .bool:                return warning
        case .array, .dictionary:  return webSocket
        case .data:                return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .date:                return Color(red: 0.85, green: 0.55, blue: 0.20)
        case .unknown:             return Color(red: 0.55, green: 0.55, blue: 0.58)
        }
    }

    // MARK: - Rules

    static let mock = Color(red: 0.61, green: 0.35, blue: 0.96)
    static let rewrite = Color(red: 1.0, green: 0.62, blue: 0.04)

    static func matchModeColor(_ mode: URLMatchMode) -> Color {
        switch mode {
        case .host:     return accent
        case .contains: return success
        case .prefix:   return warning
        case .exact:    return info
        case .regex:    return error
        }
    }

    // MARK: - Logs

    static let logCategoryColor = Color(red: 0.45, green: 0.65, blue: 0.85)

    static func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug:   return Color(red: 0.55, green: 0.55, blue: 0.58)
        case .info:    return info
        case .warning: return warning
        case .error:   return error
        }
    }

    // MARK: - Keychain

    // MARK: - Button Styles

    /// A button style that scales down slightly on press for tactile feedback.
    struct PressScale: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }

    static func keychainClassColor(_ itemClass: KeychainEntry.ItemClass) -> Color {
        switch itemClass {
        case .genericPassword:  return accent
        case .internetPassword: return webSocket
        }
    }
}
