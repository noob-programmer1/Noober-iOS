import SwiftUI

struct RewriteRuleEditView: View {

    @ObservedObject var store: RulesStore
    let existingRule: URLRewriteRule?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var matchMode: URLMatchMode = .host
    @State private var pattern = ""
    @State private var replacement = ""
    @State private var isEnabled = true

    init(store: RulesStore, existingRule: URLRewriteRule? = nil) {
        self.store = store
        self.existingRule = existingRule
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name
                    sectionHeader("Name")
                    TextField("e.g. Prod → Staging", text: $name)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(fieldBackground)
                        .padding(.horizontal, 16)

                    // Match Mode
                    sectionHeader("Match Mode")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(URLMatchMode.allCases, id: \.self) { mode in
                                Button {
                                    matchMode = mode
                                } label: {
                                    Text(mode.rawValue)
                                        .font(.system(size: 13, weight: matchMode == mode ? .bold : .medium))
                                        .foregroundColor(matchMode == mode ? .white : NooberTheme.matchModeColor(mode))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(
                                                matchMode == mode
                                                    ? NooberTheme.matchModeColor(mode)
                                                    : NooberTheme.matchModeColor(mode).opacity(0.12)
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Pattern
                    sectionHeader("Match Pattern")
                    TextField(patternPlaceholder, text: $pattern)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(fieldBackground)
                        .padding(.horizontal, 16)

                    // Replacement
                    sectionHeader("Replace With")
                    TextField("api.staging.com", text: $replacement)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(fieldBackground)
                        .padding(.horizontal, 16)

                    // Enabled
                    HStack {
                        sectionHeader("Enabled")
                        Spacer()
                        Toggle("", isOn: $isEnabled)
                            .labelsHidden()
                            .padding(.trailing, 16)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(existingRule != nil ? "Edit Rule" : "New Rewrite Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(NooberTheme.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || pattern.trimmingCharacters(in: .whitespaces).isEmpty
                                  || replacement.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let rule = existingRule {
                    name = rule.name
                    matchMode = rule.matchPattern.mode
                    pattern = rule.matchPattern.pattern
                    replacement = rule.replacementHost
                    isEnabled = rule.isEnabled
                }
            }
        }
    }

    private var patternPlaceholder: String {
        switch matchMode {
        case .host:     return "api.production.com"
        case .contains: return "/api/v1/"
        case .prefix:   return "https://api.production.com"
        case .exact:    return "https://api.production.com/users"
        case .regex:    return "api\\.prod.*\\.com"
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(uiColor: .tertiarySystemFill))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(NooberTheme.accent)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
    }

    private func save() {
        let matchPattern = URLMatchPattern(mode: matchMode, pattern: pattern.trimmingCharacters(in: .whitespaces))
        if let existing = existingRule {
            let updated = URLRewriteRule(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                matchPattern: matchPattern,
                replacementHost: replacement.trimmingCharacters(in: .whitespaces),
                isEnabled: isEnabled,
                createdAt: existing.createdAt
            )
            store.updateRewriteRule(updated)
        } else {
            let rule = URLRewriteRule(
                name: name.trimmingCharacters(in: .whitespaces),
                matchPattern: matchPattern,
                replacementHost: replacement.trimmingCharacters(in: .whitespaces),
                isEnabled: isEnabled
            )
            store.addRewriteRule(rule)
        }
        dismiss()
    }
}
