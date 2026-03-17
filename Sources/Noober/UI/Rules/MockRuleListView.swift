import SwiftUI

struct MockRuleListView: View {

    @ObservedObject var store: RulesStore
    @State private var searchText = ""
    @State private var editingRule: MockRule?
    @State private var showAddSheet = false

    private var filteredRules: [MockRule] {
        if searchText.isEmpty { return store.mockRules }
        let q = searchText.lowercased()
        return store.mockRules.filter {
            $0.name.lowercased().contains(q)
                || $0.matchPattern.pattern.lowercased().contains(q)
                || ($0.httpMethod?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if store.mockRules.isEmpty {
                emptyState
            } else {
                statsBar
                Divider()
                ruleList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MockRuleEditView(store: store)
        }
        .sheet(item: $editingRule) { rule in
            MockRuleEditView(store: store, existingRule: rule)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Search mocks...", text: $searchText)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .tertiarySystemFill)))

            Button { showAddSheet = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(NooberTheme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Stats

    private var statsBar: some View {
        HStack {
            let enabled = store.mockRules.filter(\.isEnabled).count
            Text("\(store.mockRules.count) mocks")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text("\(enabled) active")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(enabled > 0 ? NooberTheme.success : .secondary)
            Spacer()
            if !store.mockRules.isEmpty {
                Button {
                    NooberTheme.hapticMedium()
                    withAnimation { store.clearAllMockRules() }
                } label: {
                    Text("Clear All")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NooberTheme.error)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - List

    private var ruleList: some View {
        List {
            ForEach(filteredRules) { rule in
                MockRuleRow(rule: rule) {
                    NooberTheme.hapticLight()
                    store.toggleMockRule(rule)
                }
                .contextMenu {
                    Button { editingRule = rule } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        store.toggleMockRule(rule)
                    } label: {
                        Label(rule.isEnabled ? "Disable" : "Enable",
                              systemImage: rule.isEnabled ? "pause.circle" : "play.circle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation { store.deleteMockRule(rule) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        NooberTheme.hapticMedium()
                        store.deleteMockRule(rule)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onMove { store.moveMockRule(from: $0, to: $1) }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No Mock Rules")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text("Mock API responses without\nhitting the network.")
                .font(.system(size: 14)).foregroundColor(Color(uiColor: .tertiaryLabel)).multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Add Mock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(NooberTheme.accent)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(NooberTheme.accent.opacity(0.1)))
            }
            tipView
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var tipView: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)
            Text("Long press any request to prefill a mock rule.")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .tertiarySystemFill)))
    }
}

// MARK: - Row

private struct MockRuleRow: View {
    let rule: MockRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(rule.isEnabled ? NooberTheme.mock : Color(uiColor: .tertiaryLabel))
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        TypeBadge(text: "MOCK", color: NooberTheme.mock)
                        if let method = rule.httpMethod {
                            TypeBadge(text: method, color: NooberTheme.methodColor(method))
                        }
                        TypeBadge(text: "\(rule.mockStatusCode)", color: statusColor)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { rule.isEnabled },
                            set: { _ in onToggle() }
                        ))
                        .labelsHidden()
                        .scaleEffect(0.7)
                    }
                    Text(rule.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(rule.matchPattern.mode.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NooberTheme.matchModeColor(rule.matchPattern.mode))
                        Text(rule.matchPattern.pattern)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(.leading, 10)
            .padding(.vertical, 8)
        }
        .padding(.leading, 16)
        .opacity(rule.isEnabled ? 1 : 0.5)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 30) }
    }

    private var statusColor: Color {
        switch rule.mockStatusCode {
        case 200..<300: return NooberTheme.success
        case 300..<400: return NooberTheme.info
        case 400..<500: return NooberTheme.warning
        case 500..<600: return NooberTheme.error
        default:        return .secondary
        }
    }
}
