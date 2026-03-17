import SwiftUI

struct KeyValueRow: View {
    let key: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(NooberTheme.accent)

            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 6)
    }
}

struct HeadersView: View {
    let headers: [String: String]

    var body: some View {
        if headers.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 28))
                    .foregroundColor(Color(uiColor: .quaternaryLabel))
                Text("No headers")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    KeyValueRow(key: key, value: value)
                        .padding(.horizontal, 16)

                    if key != headers.sorted(by: { $0.key < $1.key }).last?.key {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
