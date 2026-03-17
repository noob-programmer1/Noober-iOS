import SwiftUI

struct InterceptRuleEditView: View {

    @ObservedObject var store: RulesStore
    let existingRule: InterceptRule?
    let prefillFromRequest: NetworkRequestModel?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var matchMode: URLMatchMode = .contains
    @State private var pattern = ""
    @State private var filterMethod = false
    @State private var httpMethod = "GET"
    @State private var isEnabled = true

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]

    init(store: RulesStore, existingRule: InterceptRule? = nil, prefillFromRequest: NetworkRequestModel? = nil) {
        self.store = store
        self.existingRule = existingRule
        self.prefillFromRequest = prefillFromRequest
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name
                    sectionHeader("Name")
                    TextField("e.g. Intercept /api/users", text: $name)
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
                    TextField("/api/users", text: $pattern)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(fieldBackground)
                        .padding(.horizontal, 16)

                    // HTTP Method filter
                    HStack {
                        sectionHeader("Filter by Method")
                        Spacer()
                        Toggle("", isOn: $filterMethod)
                            .labelsHidden()
                            .padding(.trailing, 16)
                    }
                    if filterMethod {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(methods, id: \.self) { m in
                                    Button {
                                        httpMethod = m
                                    } label: {
                                        Text(m)
                                            .font(.system(size: 13, weight: httpMethod == m ? .bold : .medium, design: .monospaced))
                                            .foregroundColor(httpMethod == m ? .white : NooberTheme.methodColor(m))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule().fill(
                                                    httpMethod == m
                                                        ? NooberTheme.methodColor(m)
                                                        : NooberTheme.methodColor(m).opacity(0.12)
                                                )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

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
            .navigationTitle(existingRule != nil ? "Edit Rule" : "New Intercept Rule")
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
                                  || pattern.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { prefill() }
        }
    }

    // MARK: - Helpers

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

    private func prefill() {
        if let rule = existingRule {
            name = rule.name
            matchMode = rule.matchPattern.mode
            pattern = rule.matchPattern.pattern
            filterMethod = rule.httpMethod != nil
            httpMethod = rule.httpMethod ?? "GET"
            isEnabled = rule.isEnabled
        } else if let req = prefillFromRequest {
            name = "Intercept \(req.method) \(req.path)"
            pattern = req.path
            filterMethod = true
            httpMethod = req.method
        }
    }

    private func save() {
        let matchPattern = URLMatchPattern(mode: matchMode, pattern: pattern.trimmingCharacters(in: .whitespaces))
        if let existing = existingRule {
            let updated = InterceptRule(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                matchPattern: matchPattern,
                httpMethod: filterMethod ? httpMethod : nil,
                isEnabled: isEnabled,
                createdAt: existing.createdAt
            )
            store.updateInterceptRule(updated)
        } else {
            let rule = InterceptRule(
                name: name.trimmingCharacters(in: .whitespaces),
                matchPattern: matchPattern,
                httpMethod: filterMethod ? httpMethod : nil,
                isEnabled: isEnabled
            )
            store.addInterceptRule(rule)
        }
        dismiss()
    }
}
