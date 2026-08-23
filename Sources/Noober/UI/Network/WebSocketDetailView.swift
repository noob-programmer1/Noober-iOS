import SwiftUI
import UIKit

// MARK: - Connection Detail

struct WebSocketDetailView: View {

    let connection: WebSocketConnectionModel

    @ObservedObject private var store = NetworkActivityStore.shared
    @State private var directionFilter: WebSocketFrameModel.Direction?
    @State private var copiedField: String?

    /// Live connection from the store so frames keep streaming in while this view is open.
    /// Falls back to the snapshot we were pushed with if the log was cleared.
    private var live: WebSocketConnectionModel {
        store.webSocketConnections.first { $0.id == connection.id } ?? connection
    }

    /// Newest first, optionally filtered by direction.
    private var frames: [WebSocketFrameModel] {
        let all = Array(live.frames.reversed())
        guard let direction = directionFilter else { return all }
        return all.filter { $0.direction == direction }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if !live.frames.isEmpty {
                    filterBar
                }

                if live.frames.isEmpty {
                    emptyLabel("No frames captured yet")
                } else if frames.isEmpty {
                    emptyLabel("No \(directionFilter?.rawValue.lowercased() ?? "") frames")
                } else {
                    NooberLazyVStack(spacing: 1) {
                        ForEach(frames) { frame in
                            NavigationLink(destination: WebSocketFrameDetailView(frame: frame)) {
                                WebSocketFrameRow(frame: frame)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                if !frame.copyText.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = frame.copyText
                                        NooberTheme.hapticSuccess()
                                    } label: {
                                        NooberLabel("Copy Payload", systemImage: "doc.on.doc")
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(16)
        }
        .nooberNavigationBarTitle(live.displayName)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                WebSocketBadge(status: live.status)
                Text(live.status.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NooberTheme.wsStatusColor(live.status))
                Spacer()
                Text("\(live.frames.count) frames")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text(live.url)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary.opacity(0.8))
                .nooberTextSelection()

            if let code = live.closeCode {
                Text("Closed: \(code)\(live.closeReason.map { " — \($0)" } ?? "")")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                copyButton("URL", value: live.url)
                if !live.frames.isEmpty {
                    copyButton("Transcript", value: transcript)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func copyButton(_ label: String, value: String) -> some View {
        let isCopied = copiedField == label
        return Button {
            UIPasteboard.general.string = value
            NooberTheme.hapticSuccess()
            withAnimation(.spring(response: 0.3)) { copiedField = label }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedField == label {
                    withAnimation { copiedField = nil }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                Text(isCopied ? "Copied" : "Copy \(label)")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isCopied ? NooberTheme.success : NooberTheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill((isCopied ? NooberTheme.success : NooberTheme.accent).opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip(title: "All (\(live.frames.count))", isSelected: directionFilter == nil, color: NooberTheme.accent) {
                directionFilter = nil
            }
            filterChip(title: "Sent (\(live.sentCount))", isSelected: directionFilter == .sent, color: NooberTheme.warning) {
                directionFilter = directionFilter == .sent ? nil : .sent
            }
            filterChip(title: "Received (\(live.receivedCount))", isSelected: directionFilter == .received, color: NooberTheme.info) {
                directionFilter = directionFilter == .received ? nil : .received
            }
            Spacer()
        }
    }

    private func filterChip(title: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(isSelected ? color : color.opacity(0.12)))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    // MARK: - Transcript

    /// The whole conversation as plain text, oldest first — handy to paste into a bug report.
    private var transcript: String {
        let lines = live.frames.map { frame -> String in
            let arrow = frame.direction == .sent ? "→ SENT" : "← RECV"
            let header = "[\(WebSocketFormatters.time(frame.timestamp))] \(arrow) \(frame.frameType.rawValue) (\(frame.sizeText))"
            return "\(header)\n\(frame.copyText)"
        }
        return ([live.url] + lines).joined(separator: "\n\n")
    }
}

// MARK: - Frame Row

private struct WebSocketFrameRow: View {

    let frame: WebSocketFrameModel

    /// Row preview is capped so a multi-megabyte frame doesn't get laid out just to be clipped.
    private var preview: String {
        guard let str = frame.payloadString, !str.isEmpty else { return frame.payloadPreview }
        return str.count > 300 ? String(str.prefix(300)) + "…" : str
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: frame.direction == .sent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(frame.direction == .sent ? NooberTheme.warning : NooberTheme.info)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(frame.frameType.rawValue)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(frame.isJSON ? NooberTheme.success : .secondary)
                    if frame.isJSON {
                        Text("JSON")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(NooberTheme.success)
                    }
                    Spacer()
                    Text(WebSocketFormatters.time(frame.timestamp))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(.tertiaryLabel))
                    Text(frame.sizeText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                Text(preview)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
}

// MARK: - Frame Detail

struct WebSocketFrameDetailView: View {

    let frame: WebSocketFrameModel

    @State private var showRaw = false

    /// Full payload — pretty-printed JSON by default, raw on request, hex for binary.
    private var displayText: String {
        if let str = frame.payloadString, !str.isEmpty {
            return (frame.isJSON && !showRaw) ? frame.prettyPayload : str
        }
        if let data = frame.payload, !data.isEmpty {
            return WebSocketFormatters.hexDump(data)
        }
        return "(empty payload)"
    }

    var body: some View {
        VStack(spacing: 0) {
            metaBar

            Divider()

            if frame.isJSON {
                Picker("Format", selection: $showRaw) {
                    Text("Pretty").tag(false)
                    Text("Raw").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            CopyableText(text: displayText)
        }
        .nooberNavigationBarTitle(frame.direction == .sent ? "Sent Frame" : "Received Frame")
    }

    private var metaBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: frame.direction == .sent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(frame.direction == .sent ? NooberTheme.warning : NooberTheme.info)
                Text(frame.direction.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(frame.frameType.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color(.tertiarySystemBackground)))
                if frame.isJSON {
                    Text("JSON")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(NooberTheme.success)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(NooberTheme.success.opacity(0.12)))
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Text(WebSocketFormatters.time(frame.timestamp))
                Text(frame.sizeText)
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Formatters

enum WebSocketFormatters {

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Classic `offset  hex bytes  ascii` dump, capped so huge binary frames stay renderable.
    static func hexDump(_ data: Data, maxBytes: Int = 4096) -> String {
        let slice = data.prefix(maxBytes)
        var lines: [String] = []

        for (row, chunk) in stride(from: 0, to: slice.count, by: 16).enumerated() {
            let bytes = Array(slice[slice.startIndex.advanced(by: chunk)..<slice.startIndex.advanced(by: min(chunk + 16, slice.count))])
            let hex = bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
            let ascii = String(bytes.map { $0 >= 32 && $0 < 127 ? Character(UnicodeScalar($0)) : "." })
            let offset = String(format: "%08x", row * 16)
            lines.append("\(offset)  \(hex.padding(toLength: 47, withPad: " ", startingAt: 0))  \(ascii)")
        }

        if data.count > maxBytes {
            lines.append("… \(data.count - maxBytes) more bytes")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Copy Text

extension WebSocketFrameModel {
    /// What lands on the pasteboard: pretty JSON when we can, raw text otherwise, hex for binary.
    var copyText: String {
        if let str = payloadString, !str.isEmpty {
            return isJSON ? prettyPayload : str
        }
        if let data = payload, !data.isEmpty {
            return WebSocketFormatters.hexDump(data)
        }
        return ""
    }
}
