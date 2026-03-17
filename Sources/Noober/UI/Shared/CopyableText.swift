import SwiftUI
import UIKit

struct CopyableText: View {

    let text: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                    NooberTheme.hapticSuccess()
                    withAnimation(.spring(response: 0.3)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copied = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied" : "Copy")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(copied ? NooberTheme.success : NooberTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                (copied ? NooberTheme.success : NooberTheme.accent)
                                    .opacity(0.12)
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Text(text)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
}
