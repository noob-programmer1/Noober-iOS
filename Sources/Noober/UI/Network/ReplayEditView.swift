import SwiftUI

struct ReplayEditView: View {

    let request: NetworkRequestModel
    @Environment(\.presentationMode) private var presentationMode

    @State private var url: String = ""
    @State private var method: String = "GET"
    @State private var headers: [(key: String, value: String)] = []
    @State private var bodyText: String = ""
    @State private var isSending = false
    @State private var sent = false

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Method")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(methods, id: \.self) { m in
                                Button {
                                    method = m
                                } label: {
                                    Text(m)
                                        .font(.system(size: 13, weight: method == m ? .bold : .medium, design: .monospaced))
                                        .foregroundColor(method == m ? .white : NooberTheme.methodColor(m))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(
                                                method == m
                                                    ? NooberTheme.methodColor(m)
                                                    : NooberTheme.methodColor(m).opacity(0.12)
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    sectionHeader("URL")
                    TextField("https://...", text: $url)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                        )
                        .padding(.horizontal, 16)

                    sectionHeader("Headers (\(headers.count))")
                    VStack(spacing: 8) {
                        ForEach(Array(headers.enumerated()), id: \.offset) { index, _ in
                            HStack(spacing: 8) {
                                TextField("Key", text: $headers[index].key)
                                    .font(.system(size: 12, design: .monospaced))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(.tertiarySystemFill))
                                    )

                                TextField("Value", text: $headers[index].value)
                                    .font(.system(size: 12, design: .monospaced))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color(.tertiarySystemFill))
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
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                Text("Add Header")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(NooberTheme.accent)
                        }
                    }
                    .padding(.horizontal, 16)

                    if method != "GET" && method != "HEAD" {
                        sectionHeader("Body")
                        ZStack(alignment: .topLeading) {
                            if bodyText.isEmpty {
                                Text("Request body...")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.top, 12)
                                    .padding(.leading, 14)
                            }
                            NooberTextEditor(text: $bodyText)
                                .font(.system(size: 13, design: .monospaced))
                                .frame(minHeight: 120)
                                .padding(4)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                        )
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .nooberNavigationBarTitle("Replay Request")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.secondary),
                trailing: Button {
                    sendRequest()
                } label: {
                    HStack(spacing: 4) {
                        if sent {
                            Image(systemName: "checkmark")
                            Text("Sent")
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send")
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(sent ? NooberTheme.success : NooberTheme.accent)
                }
                .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            )
            .onAppear {
                url = request.url
                method = request.method
                headers = request.requestHeaders
                    .sorted(by: { $0.key < $1.key })
                    .map { (key: $0.key, value: $0.value) }
                if let body = request.requestBody,
                   let str = String(data: body, encoding: .utf8) {
                    bodyText = str
                }
            }
        }
    }

    // MARK: - Send

    private func sendRequest() {
        isSending = true

        let headerDict = headers.reduce(into: [String: String]()) { dict, pair in
            let k = pair.key.trimmingCharacters(in: .whitespaces)
            if !k.isEmpty {
                dict[k] = pair.value
            }
        }

        let bodyData: Data? = bodyText.isEmpty ? nil : bodyText.data(using: .utf8)

        RequestReplayer.replay(
            url: url,
            method: method,
            headers: headerDict,
            body: bodyData
        )

        withAnimation(.spring(response: 0.3)) {
            sent = true
            isSending = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(NooberTheme.accent)
            .padding(.horizontal, 16)
    }
}
