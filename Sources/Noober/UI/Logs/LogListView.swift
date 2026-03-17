import SwiftUI

struct LogListView: View {

    @ObservedObject var store: LogStore
    @State private var searchText = ""
    @State private var selectedLevels: Set<LogLevel> = []
    @State private var selectedCategories: Set<LogCategory> = []

    // MARK: - Computed

    private var filteredEntries: [LogEntry] {
        store.entries.filter { entry in
            if !selectedLevels.isEmpty && !selectedLevels.contains(entry.level) { return false }
            if !selectedCategories.isEmpty && !selectedCategories.contains(entry.category) { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let matches = entry.message.lowercased().contains(q)
                    || entry.level.rawValue.lowercased().contains(q)
                    || entry.category.rawValue.lowercased().contains(q)
                if !matches { return false }
            }
            return true
        }
    }

    private var levelCounts: [LogLevel: Int] {
        Dictionary(grouping: store.entries, by: \.level).mapValues(\.count)
    }

    private var activeFilterCount: Int {
        selectedLevels.count + selectedCategories.count + (searchText.isEmpty ? 0 : 1)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchAndClearBar
            levelChips
            if store.seenCategories.count > 1 { categoryChips }
            if !store.entries.isEmpty {
                statsBar
                Divider()
            }
            if filteredEntries.isEmpty { emptyState }
            else { entryList }
        }
    }

    // MARK: - Search + Clear

    private var searchAndClearBar: some View {
        HStack(spacing: 10) {
            NooberSearchBar(text: $searchText, placeholder: "Search logs...")

            if !store.entries.isEmpty {
                Button {
                    NooberTheme.hapticMedium()
                    withAnimation(.spring(response: 0.3)) { store.clearAll() }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(NooberTheme.error.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Level Chips

    private var levelChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(title: "All", isSelected: selectedLevels.isEmpty) {
                    selectedLevels.removeAll()
                }
                ForEach(LogLevel.allCases, id: \.self) { level in
                    let count = levelCounts[level] ?? 0
                    FilterChip(
                        title: "\(level.rawValue) (\(count))",
                        isSelected: selectedLevels.contains(level)
                    ) {
                        if selectedLevels.contains(level) { selectedLevels.remove(level) }
                        else { selectedLevels.insert(level) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(title: "All Categories", isSelected: selectedCategories.isEmpty) {
                    selectedCategories.removeAll()
                }
                ForEach(store.seenCategories, id: \.self) { cat in
                    FilterChip(
                        title: cat.rawValue,
                        isSelected: selectedCategories.contains(cat)
                    ) {
                        if selectedCategories.contains(cat) { selectedCategories.remove(cat) }
                        else { selectedCategories.insert(cat) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statsItem(count: store.entries.count, label: "Total", color: .primary)
            statsItemDivider
            statsItem(count: levelCounts[.error] ?? 0, label: "Error", color: NooberTheme.error)
            statsItemDivider
            statsItem(count: levelCounts[.warning] ?? 0, label: "Warn", color: NooberTheme.warning)
            statsItemDivider
            statsItem(count: levelCounts[.info] ?? 0, label: "Info", color: NooberTheme.info)

            Spacer()

            Text("\(filteredEntries.count) shown")
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func statsItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
    }

    private var statsItemDivider: some View {
        Rectangle().fill(Color(uiColor: .separator)).frame(width: 1, height: 22).padding(.horizontal, 6)
    }

    // MARK: - Entry List

    private var entryList: some View {
        List {
            ForEach(filteredEntries) { entry in
                NavigationLink(destination: LogDetailView(entry: entry)) {
                    LogRowView(entry: entry)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = entry.message
                        NooberTheme.hapticSuccess()
                    } label: {
                        Label("Copy Message", systemImage: "doc.on.doc")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: store.entries.isEmpty
                    ? "doc.text.magnifyingglass" : "line.3.horizontal.decrease")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text(store.entries.isEmpty ? "No logs yet" : "No matching logs")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text(store.entries.isEmpty
                ? "Custom logs from your app\nwill appear here."
                : "Try adjusting your search or filters.")
                .font(.system(size: 14)).foregroundColor(Color(uiColor: .tertiaryLabel)).multilineTextAlignment(.center)
            if activeFilterCount > 0 {
                Button {
                    withAnimation {
                        searchText = ""
                        selectedLevels.removeAll()
                        selectedCategories.removeAll()
                    }
                } label: {
                    Text("Clear Filters")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(NooberTheme.accent)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Row

private struct LogRowView: View {

    let entry: LogEntry

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Level color strip
            RoundedRectangle(cornerRadius: 2)
                .fill(NooberTheme.logLevelColor(entry.level))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 5) {
                // Row 1: Level + Category + Time
                HStack(spacing: 4) {
                    LogLevelBadge(level: entry.level)
                    TypeBadge(text: entry.category.rawValue.uppercased(), color: NooberTheme.logCategoryColor)
                    Spacer()
                    Text(Self.timeFormatter.string(from: entry.timestamp))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }

                // Row 2: Message
                Text(entry.message)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Row 3: File:line
                if !entry.file.isEmpty {
                    Text("\((entry.file as NSString).lastPathComponent):\(entry.line)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(.leading, 10)
            .padding(.vertical, 8)
        }
        .padding(.leading, 16)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 30) }
    }
}

// MARK: - Log Level Badge

struct LogLevelBadge: View {
    let level: LogLevel

    var body: some View {
        Text(level.rawValue)
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(NooberTheme.logLevelColor(level))
            )
    }
}
