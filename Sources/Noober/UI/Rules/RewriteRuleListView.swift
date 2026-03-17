import SwiftUI

struct RewriteRuleListView: View {

    @ObservedObject var store: RulesStore
    @State private var searchText = ""
    @State private var editingRule: URLRewriteRule?
    @State private var showAddSheet = false

    private var filteredRules: [URLRewriteRule] {
        if searchText.isEmpty { return store.rewriteRules }
        let q = searchText.lowercased()
        return store.rewriteRules.filter {
            $0.name.lowercased().contains(q)
                || $0.matchPattern.pattern.lowercased().contains(q)
                || $0.replacementHost.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if store.rewriteRules.isEmpty {
                emptyState
            } else {
                statsBar
                Divider()
                ruleList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            RewriteRuleEditView(store: store)
        }
        .sheet(item: $editingRule) { rule in
            RewriteRuleEditView(store: store, existingRule: rule)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Search rules...", text: $searchText)
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
            let enabled = store.rewriteRules.filter(\.isEnabled).count
            Text("\(store.rewriteRules.count) rules")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text("\(enabled) active")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(enabled > 0 ? NooberTheme.success : .secondary)
            Spacer()
            if !store.rewriteRules.isEmpty {
                Button {
                    NooberTheme.hapticMedium()
                    withAnimation { store.clearAllRewriteRules() }
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
                RewriteRuleRow(rule: rule) {
                    NooberTheme.hapticLight()
                    store.toggleRewriteRule(rule)
                }
                .contextMenu {
                    Button { editingRule = rule } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        store.toggleRewriteRule(rule)
                    } label: {
                        Label(rule.isEnabled ? "Disable" : "Enable",
                              systemImage: rule.isEnabled ? "pause.circle" : "play.circle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation { store.deleteRewriteRule(rule) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        NooberTheme.hapticMedium()
                        store.deleteRewriteRule(rule)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onMove { store.moveRewriteRule(from: $0, to: $1) }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No Rewrite Rules")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text("Redirect API requests to different\nhosts or URLs.")
                .font(.system(size: 14)).foregroundColor(Color(uiColor: .tertiaryLabel)).multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Add Rule")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(NooberTheme.accent)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(NooberTheme.accent.opacity(0.1)))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Row

private struct RewriteRuleRow: View {
    let rule: URLRewriteRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(rule.isEnabled ? NooberTheme.rewrite : Color(uiColor: .tertiaryLabel))
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        TypeBadge(text: "RW", color: NooberTheme.rewrite)
                        TypeBadge(text: rule.matchPattern.mode.rawValue.uppercased(),
                                  color: NooberTheme.matchModeColor(rule.matchPattern.mode))
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
                        Text(rule.matchPattern.pattern)
                            .lineLimit(1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .bold))
                        Text(rule.replacementHost)
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
}
