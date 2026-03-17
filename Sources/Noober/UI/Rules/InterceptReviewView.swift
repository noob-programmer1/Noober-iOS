import SwiftUI
import Combine

struct InterceptReviewView: View {

    let intercept: PendingIntercept
    @Environment(\.dismiss) private var dismiss

    @State private var url: String = ""
    @State private var method: String = "GET"
    @State private var headers: [(key: String, value: String)] = []
    @State private var bodyText: String = ""
    @State private var remainingSeconds: Int = 60

    private let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Countdown banner
                countdownBanner

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Method
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

                        // URL
                        sectionHeader("URL")
                        TextField("https://...", text: $url)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(10)
                            .background(fieldBackground)
                            .padding(.horizontal, 16)

                        // Headers
                        sectionHeader("Headers (\(headers.count))")
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

                        // Body
                        if method != "GET" && method != "HEAD" {
                            sectionHeader("Body")
                            ZStack(alignment: .topLeading) {
                                if bodyText.isEmpty {
                                    Text("Request body...")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(Color(uiColor: .placeholderText))
                                        .padding(.top, 12)
                                        .padding(.leading, 14)
                                }
                                TextEditor(text: $bodyText)
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(minHeight: 100)
                                    .padding(4)
                            }
                            .background(fieldBackground)
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }

                // Action bar
                actionBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Intercepted Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Drop") {
                        InterceptManager.cancel(id: intercept.id)
                        dismiss()
                    }
                    .foregroundColor(NooberTheme.error)
                }
            }
            .onAppear {
                url = intercept.url
                method = intercept.method
                headers = intercept.headers
                    .sorted(by: { $0.key < $1.key })
                    .map { (key: $0.key, value: $0.value) }
                if let body = intercept.body,
                   let str = String(data: body, encoding: .utf8) {
                    bodyText = str
                }
                remainingSeconds = max(0, Int(intercept.autoTimeoutDate.timeIntervalSince(Date())))
            }
            .onReceive(timer) { _ in
                remainingSeconds = max(0, Int(intercept.autoTimeoutDate.timeIntervalSince(Date())))
                if remainingSeconds <= 0 {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Countdown

    private var countdownBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 14))
            Text("\(intercept.method) \(intercept.path)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .lineLimit(1)
            Spacer()
            Text("\(remainingSeconds)s")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(remainingSeconds <= 10 ? NooberTheme.error : .white)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            remainingSeconds <= 10
                ? NooberTheme.error.opacity(0.9)
                : Color(red: 0.95, green: 0.55, blue: 0.15)
        )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                InterceptManager.cancel(id: intercept.id)
                dismiss()
            } label: {
                Text("Cancel Request")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(NooberTheme.error))
            }

            Button {
                continueRequest()
            } label: {
                Text("Continue")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(NooberTheme.success))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
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

    private func continueRequest() {
        let headerDict = headers.reduce(into: [String: String]()) { dict, pair in
            let k = pair.key.trimmingCharacters(in: .whitespaces)
            if !k.isEmpty { dict[k] = pair.value }
        }
        let bodyData: Data? = bodyText.isEmpty ? nil : bodyText.data(using: .utf8)
        InterceptManager.proceed(
            id: intercept.id,
            url: url,
            method: method,
            headers: headerDict,
            body: bodyData
        )
        dismiss()
    }
}
