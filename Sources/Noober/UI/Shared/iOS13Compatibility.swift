import SwiftUI
import UIKit

// MARK: - Label

/// `Label(_:systemImage:)` on iOS 14+, manual `HStack` fallback on iOS 13.
@ViewBuilder
func NooberLabel(_ title: String, systemImage: String) -> some View {
    if #available(iOS 14, *) {
        Label(title, systemImage: systemImage)
    } else {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(title)
        }
    }
}

// MARK: - Destructive Button

/// `Button(role: .destructive)` on iOS 15+ (native red styling + semantics in menus),
/// plain red-tinted `Button` fallback on iOS 13/14.
@ViewBuilder
func NooberDestructiveButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
    if #available(iOS 15, *) {
        Button(role: .destructive, action: action) {
            NooberLabel(title, systemImage: systemImage)
        }
    } else {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - LazyVStack

/// `LazyVStack` on iOS 14+, plain `VStack` fallback on iOS 13 (no lazy loading, same visual result).
@ViewBuilder
func NooberLazyVStack<Content: View>(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    if #available(iOS 14, *) {
        LazyVStack(alignment: alignment, spacing: spacing, content: content)
    } else {
        VStack(alignment: alignment, spacing: spacing, content: content)
    }
}

// MARK: - Swipe Actions

/// `HorizontalEdge` doesn't exist before iOS 15 — this is a pre-15-safe stand-in.
enum NooberSwipeEdge {
    case leading, trailing

    @available(iOS 15, *)
    var horizontalEdge: HorizontalEdge {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

extension View {
    /// `.swipeActions` on iOS 15+, no-op on iOS 13/14 — pair with an always-available
    /// `.contextMenu` (long-press) offering the same action so nothing is lost below 15.
    @ViewBuilder
    func nooberSwipeAction(
        edge: NooberSwipeEdge,
        isDestructive: Bool = false,
        tint: Color? = nil,
        allowsFullSwipe: Bool = false,
        label: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        if #available(iOS 15, *) {
            self.swipeActions(edge: edge.horizontalEdge, allowsFullSwipe: allowsFullSwipe) {
                Button(role: isDestructive ? .destructive : nil, action: action) {
                    NooberLabel(label, systemImage: systemImage)
                }
                .tint(tint)
            }
        } else {
            self
        }
    }
}

// MARK: - TextEditor

/// `TextEditor` on iOS 14+, `UITextView`-backed substitute on iOS 13 (TextEditor doesn't exist before 14).
struct NooberTextEditorCompat: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.backgroundColor = .clear
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }
        func textViewDidChange(_ textView: UITextView) { text.wrappedValue = textView.text }
    }
}

@ViewBuilder
func NooberTextEditor(text: Binding<String>) -> some View {
    if #available(iOS 14, *) {
        TextEditor(text: text)
    } else {
        NooberTextEditorCompat(text: text)
    }
}

// MARK: - Navigation Bar Title

extension View {
    /// `.navigationBarTitle(_:displayMode:)` on iOS 14+, plain `.navigationBarTitle(_:)`
    /// (large title only, no inline option) on iOS 13 — cosmetic difference only.
    @ViewBuilder
    func nooberNavigationBarTitle(_ title: String, inline: Bool = true) -> some View {
        if #available(iOS 14, *) {
            self.navigationBarTitle(title, displayMode: inline ? .inline : .large)
        } else {
            self.navigationBarTitle(title)
        }
    }
}

// MARK: - ProgressView

/// `ProgressView` on iOS 14+, `UIActivityIndicatorView`-backed spinner on iOS 13.
struct NooberProgressViewCompat: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        return spinner
    }
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {}
}

@ViewBuilder
func NooberProgressView() -> some View {
    if #available(iOS 14, *) {
        ProgressView()
    } else {
        NooberProgressViewCompat().frame(width: 20, height: 20)
    }
}

// MARK: - Row Separator

extension View {
    /// `.listRowSeparator(.hidden)` on iOS 15+, no-op on iOS 13/14 (rows just keep the default separator).
    @ViewBuilder
    func nooberHideRowSeparator() -> some View {
        if #available(iOS 15, *) {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
}

// MARK: - Relative Date Text

/// `Text(_:style: .relative)` on iOS 14+ (live-updating), a static
/// `RelativeDateTimeFormatter` snapshot on iOS 13 (doesn't auto-refresh).
@ViewBuilder
func NooberRelativeText(_ date: Date) -> some View {
    if #available(iOS 14, *) {
        Text(date, style: .relative)
    } else {
        let formatter = RelativeDateTimeFormatter()
        Text(formatter.localizedString(for: date, relativeTo: Date()))
    }
}
