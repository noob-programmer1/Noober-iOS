import SwiftUI
import UIKit

// MARK: - Noober V2 Design System
// Inspired by Linear, Warp, Proxyman, Raycast.
// Dark-first. One accent. Opacity elevation. Dense data.

enum DS {

    // MARK: - Colors

    /// Base backgrounds — opacity-based elevation on #1A1A1A
    enum Background {
        static let primary   = Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A
        static let elevated  = Color(red: 0.133, green: 0.133, blue: 0.133) // #222222
        static let surface   = Color(red: 0.165, green: 0.165, blue: 0.165) // #2A2A2A
        static let hover     = Color.white.opacity(0.04)
        static let selected  = Color.white.opacity(0.06)
        static let overlay   = Color.black.opacity(0.6)
    }

    /// Text colors — white at varying opacity
    enum Text {
        static let primary   = Color.white.opacity(0.88)
        static let secondary = Color.white.opacity(0.56)
        static let tertiary  = Color.white.opacity(0.36)
        static let disabled  = Color.white.opacity(0.20)
        static let inverse   = Color.black
    }

    /// Accent — single green throughout
    enum Accent {
        static let primary   = Color(red: 0.133, green: 0.773, blue: 0.369) // #22C55E
        static let muted     = Color(red: 0.133, green: 0.773, blue: 0.369).opacity(0.15)
        static let subtle    = Color(red: 0.133, green: 0.773, blue: 0.369).opacity(0.08)
    }

    /// Semantic status colors
    enum Status {
        static let success = Color(red: 0.133, green: 0.773, blue: 0.369) // green
        static let warning = Color(red: 0.957, green: 0.639, blue: 0.180) // amber
        static let error   = Color(red: 0.937, green: 0.267, blue: 0.267) // red
        static let info    = Color(red: 0.337, green: 0.533, blue: 0.937) // blue
        static let purple  = Color(red: 0.608, green: 0.349, blue: 0.961) // purple
    }

    /// Borders — barely visible
    enum Border {
        static let subtle    = Color.white.opacity(0.06)
        static let regular   = Color.white.opacity(0.10)
        static let focused   = Color.white.opacity(0.20)
    }

    // MARK: - Typography

    enum Font {
        /// UI text — SF Pro
        static func label(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight)
        }

        /// Data / code — SF Mono
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        /// Heading sizes
        static let heading    = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let subheading = SwiftUI.Font.system(size: 13, weight: .semibold)
        static let body       = SwiftUI.Font.system(size: 13, weight: .regular)
        static let caption    = SwiftUI.Font.system(size: 11, weight: .medium)
        static let micro      = SwiftUI.Font.system(size: 10, weight: .medium)

        /// Mono sizes
        static let monoBody   = SwiftUI.Font.system(size: 12, weight: .regular, design: .monospaced)
        static let monoSmall  = SwiftUI.Font.system(size: 11, weight: .regular, design: .monospaced)
        static let monoMicro  = SwiftUI.Font.system(size: 10, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing

    enum Space {
        static let xs:  CGFloat = 2
        static let s:   CGFloat = 4
        static let m:   CGFloat = 8
        static let l:   CGFloat = 12
        static let xl:  CGFloat = 16
        static let xxl: CGFloat = 24
    }

    // MARK: - Radii

    enum Radius {
        static let xs: CGFloat = 3
        static let s:  CGFloat = 4
        static let m:  CGFloat = 6
        static let l:  CGFloat = 8
    }

    // MARK: - HTTP Method Colors

    static func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET":    return Status.info
        case "POST":   return Status.success
        case "PUT":    return Status.warning
        case "PATCH":  return Status.purple
        case "DELETE": return Status.error
        default:       return Text.tertiary
        }
    }

    /// Status code → color
    static func statusCodeColor(_ code: Int?) -> Color {
        guard let code else { return Status.error }
        switch code {
        case 200..<300: return Status.success
        case 300..<400: return Status.info
        case 400..<500: return Status.warning
        case 500..<600: return Status.error
        default:        return Text.tertiary
        }
    }

    /// Log level → color
    static func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug:   return Text.tertiary
        case .info:    return Status.info
        case .warning: return Status.warning
        case .error:   return Status.error
        }
    }

    // MARK: - Haptics

    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func hapticNotify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    // MARK: - Animation

    static let snappy = Animation.easeOut(duration: 0.15)
    static let smooth = Animation.easeInOut(duration: 0.2)
}

// MARK: - Dark Container Modifier

/// Forces dark appearance on any view
struct DarkContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .background(DS.Background.primary.ignoresSafeArea())
    }
}

extension View {
    func darkContainer() -> some View {
        modifier(DarkContainer())
    }
}
