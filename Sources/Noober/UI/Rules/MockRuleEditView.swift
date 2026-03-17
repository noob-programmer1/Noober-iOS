import SwiftUI

struct MockRuleEditView: View {

    @ObservedObject var store: RulesStore
    let existingRule: MockRule?
    let prefillFromRequest: NetworkRequestModel?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var matchMode: URLMatchMode = .contains
    @State private var pattern = ""
    @State private var filterMethod = false
    @State private var httpMethod = "GET"
    @State private var statusCode = "200"
    @State private var headers: [(key: String, value: String)] = [
        (key: "Content-Type", value: "application/json")
    ]
    @State private var bodyText = ""
    @State private var isEnabled = true

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]

    init(store: RulesStore, existingRule: MockRule? = nil, prefillFromRequest: NetworkRequestModel? = nil) {
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
                    TextField("e.g. Mock /api/users", text: $name)
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

                    // Status Code
                    sectionHeader("Response Status Code")
                    TextField("200", text: $statusCode)
                        .font(.system(size: 14, design: .monospaced))
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(fieldBackground)
                        .padding(.horizontal, 16)

                    // Response Headers
                    sectionHeader("Response Headers (\(headers.count))")
                    VStack(spacing: 8) {
                        ForEach(Array(headers.enumerated()), id: \.offset) { index, _ in
                            HStack(spacing: 8) {
                                TextField("Key", text: $headers[index].key)
                                    .font(.system(size: 12, design: .monospaced))
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                    )
                                TextField("Value", text: $headers[index].value)
                                    .font(.system(size: 12, design: .monospaced))
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(uiColor: .tertiarySystemFill))
                                    )
                                Button {
                                    headers.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(NooberTheme.error.opacity(0.7))
                                }
                            }
                        }
                        Button {
                            headers.append((key: "", value: ""))
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill").font(.system(size: 14))
                                Text("Add Header").font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(NooberTheme.accent)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Response Body
                    sectionHeader("Response Body")
                    ZStack(alignment: .topLeading) {
                        if bodyText.isEmpty {
                            Text("{\"message\": \"mocked\"}")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color(uiColor: .placeholderText))
                                .padding(.top, 12)
                                .padding(.leading, 14)
                        }
                        TextEditor(text: $bodyText)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(minHeight: 120)
                            .padding(4)
                    }
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
            .navigationTitle(existingRule != nil ? "Edit Mock" : "New Mock Rule")
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
            statusCode = "\(rule.mockStatusCode)"
            headers = rule.mockResponseHeaders
                .sorted(by: { $0.key < $1.key })
                .map { (key: $0.key, value: $0.value) }
            if let body = rule.mockResponseBody,
               let str = String(data: body, encoding: .utf8) {
                bodyText = str
            }
            isEnabled = rule.isEnabled
        } else if let req = prefillFromRequest {
            name = "\(req.method) \(req.path)"
            pattern = req.path
            filterMethod = true
            httpMethod = req.method
            statusCode = "\(req.statusCode ?? 200)"
            headers = req.responseHeaders
                .sorted(by: { $0.key < $1.key })
                .map { (key: $0.key, value: $0.value) }
            if let body = req.responseBody,
               let str = String(data: body, encoding: .utf8) {
                bodyText = str
            }
        }
    }

    private func save() {
        let matchPattern = URLMatchPattern(mode: matchMode, pattern: pattern.trimmingCharacters(in: .whitespaces))
        let headerDict = headers.reduce(into: [String: String]()) { dict, pair in
            let k = pair.key.trimmingCharacters(in: .whitespaces)
            if !k.isEmpty { dict[k] = pair.value }
        }
        let bodyData: Data? = bodyText.isEmpty ? nil : bodyText.data(using: .utf8)
        let code = Int(statusCode) ?? 200

        if let existing = existingRule {
            let updated = MockRule(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                matchPattern: matchPattern,
                httpMethod: filterMethod ? httpMethod : nil,
                mockStatusCode: code,
                mockResponseHeaders: headerDict,
                mockResponseBody: bodyData,
                isEnabled: isEnabled,
                createdAt: existing.createdAt
            )
            store.updateMockRule(updated)
        } else {
            let rule = MockRule(
                name: name.trimmingCharacters(in: .whitespaces),
                matchPattern: matchPattern,
                httpMethod: filterMethod ? httpMethod : nil,
                mockStatusCode: code,
                mockResponseHeaders: headerDict,
                mockResponseBody: bodyData,
                isEnabled: isEnabled
            )
            store.addMockRule(rule)
        }
        dismiss()
    }
}
