import SwiftUI

// MARK: - Log Console (Warp / terminal-inspired)

struct V2LogConsole: View {

    @StateObject private var store = LogStore.shared
    @State private var searchText = ""
    @State private var selectedLevels: Set<LogLevel> = []
    @State private var selectedCategories: Set<String> = []
    @State private var autoScroll = true
    @State private var selectedLog: LogEntry?

    // MARK: - Computed

    private var filteredEntries: [LogEntry] {
        store.entries.filter { entry in
            if !selectedLevels.isEmpty && !selectedLevels.contains(entry.level) { return false }
            if !selectedCategories.isEmpty && !selectedCategories.contains(entry.category.rawValue) { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let matches = entry.message.lowercased().contains(q)
                    || entry.level.rawValue.lowercased().contains(q)
                    || entry.category.rawValue.lowercased().contains(q)
                    || entry.file.lowercased().contains(q)
                if !matches { return false }
            }
            return true
        }
    }

    private var levelCounts: [LogLevel: Int] {
        var counts: [LogLevel: Int] = [:]
        for entry in store.entries {
            counts[entry.level, default: 0] += 1
        }
        return counts
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            filterStrip
            levelBar
            V2Separator()

            if filteredEntries.isEmpty {
                emptyState
            } else {
                logList
            }
        }
        .background(DS.Background.primary)
        .sheet(item: $selectedLog) { entry in
            V2LogDetail(entry: entry)
                .darkContainer()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: DS.Space.m) {
            V2SearchField(text: $searchText, placeholder: "Filter logs...")

            // Auto-scroll toggle
            V2ToolbarButton(
                icon: autoScroll ? "arrow.down.to.line" : "arrow.down.to.line.compact",
                color: autoScroll ? DS.Accent.primary : DS.Text.tertiary
            ) {
                autoScroll.toggle()
            }

            if !store.entries.isEmpty {
                V2ToolbarButton(icon: "trash", color: DS.Status.error.opacity(0.7)) {
                    withAnimation(DS.snappy) { store.clearAll() }
                }
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
    }

    // MARK: - Filter Strip

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.s) {
                // Level filters
                ForEach(LogLevel.allCases, id: \.self) { level in
                    let count = levelCounts[level] ?? 0
                    V2FilterChip(
                        title: level.rawValue,
                        isSelected: selectedLevels.contains(level),
                        count: count > 0 ? count : nil
                    ) {
                        if selectedLevels.contains(level) { selectedLevels.remove(level) }
                        else { selectedLevels.insert(level) }
                    }
                }

                if !store.seenCategories.isEmpty {
                    Rectangle().fill(DS.Border.subtle).frame(width: 1, height: 16)

                    // Category filters
                    ForEach(store.seenCategories, id: \.rawValue) { cat in
                        V2FilterChip(
                            title: cat.rawValue,
                            isSelected: selectedCategories.contains(cat.rawValue)
                        ) {
                            if selectedCategories.contains(cat.rawValue) { selectedCategories.remove(cat.rawValue) }
                            else { selectedCategories.insert(cat.rawValue) }
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.s)
        }
    }

    // MARK: - Level Summary Bar

    private var levelBar: some View {
        HStack(spacing: DS.Space.l) {
            levelStat(.debug)
            levelStat(.info)
            levelStat(.warning)
            levelStat(.error)
            Spacer()
            Text("\(filteredEntries.count) shown")
                .font(DS.Font.monoMicro)
                .foregroundColor(DS.Text.tertiary)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.s + 2)
        .background(DS.Background.elevated)
    }

    private func levelStat(_ level: LogLevel) -> some View {
        HStack(spacing: DS.Space.xs) {
            StatusDot(color: DS.logLevelColor(level), size: 5)
            Text("\(levelCounts[level] ?? 0)")
                .font(DS.Font.mono(11, weight: .bold))
                .foregroundColor(DS.logLevelColor(level))
            Text(level.rawValue.lowercased())
                .font(DS.Font.monoMicro)
                .foregroundColor(DS.Text.tertiary)
        }
    }

    // MARK: - Log List (terminal-style)

    private var logList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredEntries) { entry in
                        V2LogRow(entry: entry)
                            .id(entry.id)
                            .onTapGesture {
                                DS.haptic()
                                selectedLog = entry
                            }
                    }
                }
            }
            .onChange(of: store.entries.count) { _ in
                if autoScroll, let last = filteredEntries.first {
                    withAnimation(DS.snappy) { proxy.scrollTo(last.id) }
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        V2EmptyState(
            icon: store.entries.isEmpty ? "text.alignleft" : "line.3.horizontal.decrease",
            title: store.entries.isEmpty ? "No logs yet" : "No matching logs",
            subtitle: store.entries.isEmpty ? "App logs will stream here" : "Try adjusting filters"
        )
    }
}

// MARK: - Log Row (dense, terminal-style)

private struct V2LogRow: View {
    let entry: LogEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            // Timestamp
            Text(Self.timeFormatter.string(from: entry.timestamp))
                .font(DS.Font.monoMicro)
                .foregroundColor(DS.Text.disabled)
                .frame(width: 72, alignment: .leading)

            // Level dot + badge
            StatusDot(color: DS.logLevelColor(entry.level))

            Text(entry.level.rawValue)
                .font(DS.Font.mono(9, weight: .bold))
                .foregroundColor(DS.logLevelColor(entry.level))
                .frame(width: 36, alignment: .leading)

            // Category
            if entry.category.rawValue != "general" {
                Text(entry.category.rawValue)
                    .font(DS.Font.mono(9, weight: .medium))
                    .foregroundColor(DS.Status.info.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.xs)
                            .fill(DS.Status.info.opacity(0.08))
                    )
            }

            // Message
            Text(entry.message)
                .font(DS.Font.monoSmall)
                .foregroundColor(messageColor)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.s + 1)
        .background(rowBackground)
        .overlay(alignment: .bottom) {
            V2Separator()
        }
        .contentShape(Rectangle())
    }

    private var messageColor: Color {
        switch entry.level {
        case .error:   return DS.Status.error
        case .warning: return DS.Status.warning
        case .debug:   return DS.Text.tertiary
        default:       return DS.Text.primary
        }
    }

    private var rowBackground: Color {
        switch entry.level {
        case .error:   return DS.Status.error.opacity(0.04)
        case .warning: return DS.Status.warning.opacity(0.02)
        default:       return Color.clear
        }
    }
}

// MARK: - Log Detail

struct V2LogDetail: View {
    let entry: LogEntry
    @Environment(\.dismiss) private var dismiss
    @State private var copiedField: String?

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    DS.haptic()
                    dismiss()
                } label: {
                    HStack(spacing: DS.Space.s) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Close")
                            .font(DS.Font.caption)
                    }
                    .foregroundColor(DS.Accent.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: DS.Space.s) {
                    StatusDot(color: DS.logLevelColor(entry.level))
                    Text(entry.level.rawValue)
                        .font(DS.Font.mono(11, weight: .bold))
                        .foregroundColor(DS.logLevelColor(entry.level))
                }

                Spacer()

                Button {
                    let text = "[\(entry.level.rawValue)] [\(entry.category.rawValue)] \(entry.message)\nFile: \(entry.file):\(entry.line)\nScreen: \(entry.screenName)"
                    UIPasteboard.general.string = text
                    flash("all")
                } label: {
                    Image(systemName: copiedField == "all" ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(copiedField == "all" ? DS.Status.success : DS.Text.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.l)
            .background(DS.Background.elevated)

            V2Separator()

            ScrollView {
                VStack(spacing: 0) {
                    V2SectionHeader("Details")
                    V2KeyValueRow(key: "Level", value: entry.level.rawValue, valueColor: DS.logLevelColor(entry.level))
                    V2KeyValueRow(key: "Category", value: entry.category.rawValue)
                    V2KeyValueRow(key: "Screen", value: entry.screenName)
                    V2KeyValueRow(key: "File", value: "\(entry.file):\(entry.line)")
                    V2KeyValueRow(key: "Time", value: formatTime(entry.timestamp))

                    V2SectionHeader("Message")
                    Text(entry.message)
                        .font(DS.Font.monoSmall)
                        .foregroundColor(DS.Text.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Space.xl)
                        .padding(.vertical, DS.Space.m)
                }
            }
        }
        .background(DS.Background.primary)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: date)
    }

    private func flash(_ field: String) {
        DS.hapticNotify(.success)
        withAnimation(DS.snappy) { copiedField = field }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copiedField = nil }
        }
    }
}
