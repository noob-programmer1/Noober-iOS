import SwiftUI

struct LogDetailView: View {

    let entry: LogEntry
    @State private var copiedField: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                headerCard

                // Message
                detailSection("Message") {
                    Text(entry.message)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Source
                if !entry.file.isEmpty {
                    detailSection("Source") {
                        detailRow("File", (entry.file as NSString).lastPathComponent)
                        Divider()
                        detailRow("Line", "\(entry.line)")
                    }
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(entry.level.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIPasteboard.general.string = entry.message
                    NooberTheme.hapticSuccess()
                    copiedField = "message"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedField = nil }
                } label: {
                    Image(systemName: copiedField == "message" ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(copiedField == "message" ? NooberTheme.success : NooberTheme.accent)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                LogLevelBadge(level: entry.level)
                TypeBadge(text: entry.category.rawValue.uppercased(), color: NooberTheme.logCategoryColor)
                Spacer()
                Text(Self.dateFormatter.string(from: entry.timestamp))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(NooberTheme.accent)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    private func detailRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}
