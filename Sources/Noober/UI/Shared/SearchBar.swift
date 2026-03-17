import SwiftUI

// NooberSearchBar is available as a reusable component for future tabs.
struct NooberSearchBar: View {

    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button {
                    NooberTheme.hapticLight()
                    withAnimation(.easeInOut(duration: 0.15)) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
    }
}
