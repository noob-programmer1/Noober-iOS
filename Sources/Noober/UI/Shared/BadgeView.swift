import SwiftUI

struct MethodBadge: View {
    let method: String

    var body: some View {
        Text(method)
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(NooberTheme.methodColor(method))
            )
    }
}

struct StatusBadge: View {
    let statusCode: Int?
    let category: NetworkRequestModel.StatusCodeCategory

    var body: some View {
        Text(statusCode.map(String.init) ?? "ERR")
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(NooberTheme.statusColor(category))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(NooberTheme.statusColor(category).opacity(0.15))
            )
    }
}

struct ContentTypeBadge: View {
    let contentType: NetworkRequestModel.ContentType

    var body: some View {
        Text(contentType.rawValue)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(NooberTheme.contentTypeColor(contentType))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(NooberTheme.contentTypeColor(contentType).opacity(0.12))
            )
    }
}

struct WebSocketBadge: View {
    let status: WebSocketConnectionModel.Status

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(NooberTheme.wsStatusColor(status))
                .frame(width: 6, height: 6)
            Text("WS")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
        }
        .foregroundColor(NooberTheme.webSocket)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(NooberTheme.webSocket.opacity(0.12))
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            NooberTheme.hapticLight()
            action()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? NooberTheme.accent : Color(uiColor: .tertiarySystemFill))
                )
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

struct DurationLabel: View {
    let duration: TimeInterval

    private var text: String {
        let ms = duration * 1000
        if ms < 1000 {
            return String(format: "%.0fms", ms)
        } else {
            return String(format: "%.1fs", duration)
        }
    }

    private var color: Color {
        let ms = duration * 1000
        if ms < 300 { return NooberTheme.success }
        if ms < 1000 { return NooberTheme.warning }
        return NooberTheme.error
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(color)
    }
}
