import SwiftUI

struct InterceptRuleListView: View {

    @ObservedObject var store: RulesStore
    @State private var searchText = ""
    @State private var editingRule: InterceptRule?
    @State private var showAddSheet = false

    private var filteredRules: [InterceptRule] {
        if searchText.isEmpty { return store.interceptRules }
        let q = searchText.lowercased()
        return store.interceptRules.filter {
            $0.name.lowercased().contains(q)
                || $0.matchPattern.pattern.lowercased().contains(q)
                || ($0.httpMethod?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if store.interceptRules.isEmpty {
                emptyState
            } else {
                statsBar
                Divider()
                ruleList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            InterceptRuleEditView(store: store)
        }
        .sheet(item: $editingRule) { rule in
            InterceptRuleEditView(store: store, existingRule: rule)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Search intercept rules...", text: $searchText)
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
            let enabled = store.interceptRules.filter(\.isEnabled).count
            Text("\(store.interceptRules.count) rules")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text("\(enabled) active")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(enabled > 0 ? NooberTheme.success : .secondary)
            Spacer()
            if !store.interceptRules.isEmpty {
                Button {
                    NooberTheme.hapticMedium()
                    withAnimation { store.clearAllInterceptRules() }
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
                InterceptRuleRow(rule: rule) {
                    NooberTheme.hapticLight()
                    NooberSound.playFaaa()
                    store.toggleInterceptRule(rule)
                }
                .contextMenu {
                    Button { editingRule = rule } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        NooberSound.playFaaa()
                        store.toggleInterceptRule(rule)
                    } label: {
                        Label(rule.isEnabled ? "Disable" : "Enable",
                              systemImage: rule.isEnabled ? "pause.circle" : "play.circle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation { store.deleteInterceptRule(rule) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        NooberTheme.hapticMedium()
                        store.deleteInterceptRule(rule)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onMove { store.moveInterceptRule(from: $0, to: $1) }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: "hand.raised")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No Intercept Rules")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text("Pause requests before they're sent.\nReview, edit, then continue or cancel.")
                .font(.system(size: 14)).foregroundColor(Color(uiColor: .tertiaryLabel)).multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Add Rule")
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
            Text("Long press any request to prefill an intercept rule.")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .tertiarySystemFill)))
    }
}

// MARK: - Row

private struct InterceptRuleRow: View {
    let rule: InterceptRule
    let onToggle: () -> Void

    private let interceptColor = Color(red: 0.95, green: 0.55, blue: 0.15)

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(rule.isEnabled ? interceptColor : Color(uiColor: .tertiaryLabel))
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        TypeBadge(text: "INT", color: interceptColor)
                        if let method = rule.httpMethod {
                            TypeBadge(text: method, color: NooberTheme.methodColor(method))
                        }
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
                    Text(rule.matchPattern.pattern)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .lineLimit(1)
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
