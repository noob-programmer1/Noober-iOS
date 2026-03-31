import SwiftUI
import UIKit

// MARK: - Status Dot (6px colored circle — replaces emoji)

struct StatusDot: View {
    let color: Color
    var size: CGFloat = 6

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Method Badge (compact monospace label)

struct V2MethodBadge: View {
    let method: String

    var body: some View {
        Text(method)
            .font(DS.Font.mono(10, weight: .bold))
            .foregroundColor(DS.methodColor(method))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill(DS.methodColor(method).opacity(0.12))
            )
    }
}

// MARK: - Status Code Badge

struct V2StatusBadge: View {
    let code: Int?

    var body: some View {
        let text = code.map(String.init) ?? "ERR"
        Text(text)
            .font(DS.Font.mono(10, weight: .semibold))
            .foregroundColor(DS.statusCodeColor(code))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill(DS.statusCodeColor(code).opacity(0.12))
            )
    }
}

// MARK: - Tag Badge (generic small label)

struct V2Tag: View {
    let text: String
    var color: Color = DS.Text.tertiary

    var body: some View {
        Text(text)
            .font(DS.Font.mono(9, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill(color.opacity(0.12))
            )
    }
}

// MARK: - Inline Duration

struct V2Duration: View {
    let duration: TimeInterval

    private var text: String {
        let ms = duration * 1000
        if ms < 1000 { return String(format: "%.0fms", ms) }
        return String(format: "%.1fs", duration)
    }

    private var color: Color {
        let ms = duration * 1000
        if ms < 300 { return DS.Status.success }
        if ms < 1000 { return DS.Status.warning }
        return DS.Status.error
    }

    var body: some View {
        Text(text)
            .font(DS.Font.mono(10, weight: .medium))
            .foregroundColor(color)
    }
}

// MARK: - Section Header

struct V2SectionHeader: View {
    let title: String
    var count: Int?
    var trailing: AnyView?

    init(_ title: String, count: Int? = nil) {
        self.title = title
        self.count = count
        self.trailing = nil
    }

    init(_ title: String, count: Int? = nil, @ViewBuilder trailing: () -> some View) {
        self.title = title
        self.count = count
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: DS.Space.s) {
            Text(title.uppercased())
                .font(DS.Font.caption)
                .foregroundColor(DS.Text.tertiary)
                .tracking(0.5)

            if let count {
                Text("\(count)")
                    .font(DS.Font.mono(10, weight: .semibold))
                    .foregroundColor(DS.Accent.primary)
            }

            Spacer()

            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
    }
}

// MARK: - Key-Value Row (dense, monospace)

struct V2KeyValueRow: View {
    let key: String
    let value: String
    var valueColor: Color = DS.Text.primary
    var onTap: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            Text(key)
                .font(DS.Font.mono(11, weight: .medium))
                .foregroundColor(DS.Text.secondary)
                .frame(minWidth: 80, alignment: .trailing)

            Text(value)
                .font(DS.Font.monoSmall)
                .foregroundColor(valueColor)
                .textSelection(.enabled)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, DS.Space.xl)
        .contentShape(Rectangle())
        .onTapGesture {
            if let onTap {
                onTap()
            } else {
                UIPasteboard.general.string = value
                DS.hapticNotify(.success)
            }
        }
    }
}

// MARK: - Separator

struct V2Separator: View {
    var leading: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(DS.Border.subtle)
            .frame(height: 0.5)
            .padding(.leading, leading)
    }
}

// MARK: - Empty State

struct V2EmptyState: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: DS.Space.l) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(DS.Text.tertiary)
            Text(title)
                .font(DS.Font.subheading)
                .foregroundColor(DS.Text.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Toolbar Button

struct V2ToolbarButton: View {
    let icon: String
    var color: Color = DS.Text.secondary
    let action: () -> Void

    var body: some View {
        Button(action: {
            DS.haptic()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Field (dark, inline)

struct V2SearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DS.Text.tertiary)

            TextField(placeholder, text: $text)
                .font(DS.Font.body)
                .foregroundColor(DS.Text.primary)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button {
                    DS.haptic()
                    withAnimation(DS.snappy) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DS.Text.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DS.Space.l)
        .padding(.vertical, DS.Space.m)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Background.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .stroke(DS.Border.subtle, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Filter Chip (V2)

struct V2FilterChip: View {
    let title: String
    var isSelected: Bool
    var count: Int?
    let action: () -> Void

    var body: some View {
        Button {
            DS.haptic()
            action()
        } label: {
            HStack(spacing: DS.Space.s) {
                Text(title)
                    .font(DS.Font.caption)
                if let count {
                    Text("\(count)")
                        .font(DS.Font.mono(9, weight: .bold))
                }
            }
            .foregroundColor(isSelected ? DS.Accent.primary : DS.Text.secondary)
            .padding(.horizontal, DS.Space.m)
            .padding(.vertical, DS.Space.s)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.s)
                    .fill(isSelected ? DS.Accent.subtle : DS.Background.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.s)
                            .stroke(isSelected ? DS.Accent.primary.opacity(0.3) : DS.Border.subtle, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Nav Item

struct V2NavItem: View {
    let icon: String
    let label: String
    var count: Int?
    var dotColor: Color?
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            DS.haptic()
            action()
        }) {
            HStack(spacing: DS.Space.s) {
                if let dotColor {
                    StatusDot(color: dotColor, size: 5)
                }
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(DS.Font.caption)
                if let count, count > 0 {
                    Text("\(count)")
                        .font(DS.Font.mono(9, weight: .bold))
                        .foregroundColor(DS.Accent.primary)
                }
            }
            .foregroundColor(isSelected ? DS.Text.primary : DS.Text.secondary)
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, DS.Space.m)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.s)
                    .fill(isSelected ? DS.Background.selected : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Copy Flash Modifier

struct CopyFlash: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(isActive ? DS.Accent.subtle : Color.clear)
            .animation(DS.snappy, value: isActive)
    }
}

// MARK: - Press Scale (V2 — tighter)

struct V2PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
