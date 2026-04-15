import UIKit

/// Scans the UI from inside the app process using two strategies:
/// 1. Accessibility tree (works great for SwiftUI, and UIKit with VoiceOver support)
/// 2. Direct UIKit view inspection (fallback for UIKit apps without accessibility labels)
///
/// This hybrid approach ensures all visible text/buttons are captured regardless
/// of whether the host app has good accessibility support.
@MainActor
public enum AccessibilityScanner {

    public struct Element {
        public let label: String
        public let type: String        // "Button", "StaticText", "Image", etc.
        public let frame: CGRect       // screen coordinates
        public let value: String?
        public let traits: UIAccessibilityTraits
        public let isButton: Bool
        public let isTextField: Bool
    }

    // MARK: - Find element by text (partial match)

    /// Search for elements whose label contains the given text.
    /// Returns all matches sorted by Y position.
    public static func find(text: String, exact: Bool = false) -> [Element] {
        let all = scanAll()
        let query = text.lowercased()
        return all.filter { el in
            let label = el.label.lowercased()
            return exact ? label == query : label.contains(query)
        }
    }

    /// Find the first tappable element matching the text.
    public static func findTappable(text: String) -> Element? {
        find(text: text).first { $0.isButton || $0.traits.contains(.button) }
            ?? find(text: text).first // fallback to any match
    }

    // MARK: - Get all visible text

    /// Returns all visible text on the current screen, line by line.
    public static func allVisibleText() -> [String] {
        scanAll()
            .filter { !$0.label.isEmpty }
            .map { el in
                if let value = el.value, !value.isEmpty, value != el.label {
                    return "\(el.label): \(value)"
                }
                return el.label
            }
    }

    // MARK: - Full scan

    /// Scan all elements on screen using accessibility + UIKit view fallback.
    public static func scanAll() -> [Element] {
        let windows = appWindows
        guard !windows.isEmpty else { return [] }

        var elements: [Element] = []
        var visitedFrames = Set<String>()

        for window in windows {
            // Strategy 1: Accessibility tree
            scanAccessibilityTree(window, into: &elements)
            // Strategy 2: Direct UIKit view inspection (catches views without accessibility)
            scanViewHierarchy(window, into: &elements)
        }

        // Deduplicate by label + approximate frame
        elements = elements.filter { el in
            let key = "\(el.label)|\(Int(el.frame.minX / 4) * 4),\(Int(el.frame.minY / 4) * 4)"
            if visitedFrames.contains(key) { return false }
            visitedFrames.insert(key)
            return true
        }

        return elements.sorted { $0.frame.minY < $1.frame.minY }
    }

    // MARK: - Strategy 1: Accessibility tree traversal

    private static func scanAccessibilityTree(_ element: Any, into results: inout [Element]) {
        if let ax = element as? NSObject {
            let isElement = ax.isAccessibilityElement
            let label = ax.accessibilityLabel ?? ""
            let frame = ax.accessibilityFrame
            let traits = ax.accessibilityTraits
            let value = ax.accessibilityValue

            if isElement && !label.isEmpty && frame.width > 0 && frame.height > 0 {
                if let view = element as? UIView,
                   isNooberView(view) { /* skip */ }
                else {
                    results.append(Element(
                        label: label,
                        type: traitToType(traits),
                        frame: frame,
                        value: value,
                        traits: traits,
                        isButton: traits.contains(.button),
                        isTextField: traits.contains(.searchField) || element is UITextField
                    ))
                }
            }
        }

        // Recurse via accessibilityElements (SwiftUI populates this)
        if let container = element as? NSObject,
           let children = container.accessibilityElements {
            for child in children {
                scanAccessibilityTree(child, into: &results)
            }
        }

        // Recurse via UIView subviews
        if let view = element as? UIView {
            guard !view.isHidden && view.alpha >= 0.01 else { return }
            guard !(view is BubbleWindow) && !isNooberView(view) else { return }
            for subview in view.subviews {
                scanAccessibilityTree(subview, into: &results)
            }
        }

        // Recurse via accessibilityElementCount (older API)
        if let container = element as? NSObject {
            let count = container.accessibilityElementCount()
            if count != NSNotFound && count > 0 {
                for i in 0..<count {
                    if let child = container.accessibilityElement(at: i) {
                        scanAccessibilityTree(child, into: &results)
                    }
                }
            }
        }
    }

    // MARK: - Strategy 2: Direct UIKit view inspection

    /// Walk the view hierarchy and extract text directly from UIKit views.
    /// This catches UILabel, UIButton, UITextField, UITextView, UISegmentedControl,
    /// UITabBar, UINavigationBar etc. even when accessibility labels aren't set.
    private static func scanViewHierarchy(_ view: UIView, into results: inout [Element]) {
        guard !view.isHidden && view.alpha >= 0.01 else { return }
        guard !(view is BubbleWindow) && !isNooberView(view) else { return }

        let frame = view.convert(view.bounds, to: nil) // screen coordinates
        guard frame.width > 0 && frame.height > 0 else { return }

        // Extract text from specific UIKit view types
        if let label = view as? UILabel, let text = label.text, !text.isEmpty {
            let isHeader = label.font.pointSize >= 20
            results.append(Element(
                label: text,
                type: isHeader ? "Header" : "StaticText",
                frame: frame,
                value: nil,
                traits: isHeader ? .header : .staticText,
                isButton: false,
                isTextField: false
            ))
        } else if let button = view as? UIButton {
            let title = button.currentTitle
                ?? button.titleLabel?.text
                ?? button.accessibilityLabel
                ?? ""
            if !title.isEmpty {
                results.append(Element(
                    label: title,
                    type: "Button",
                    frame: frame,
                    value: nil,
                    traits: .button,
                    isButton: true,
                    isTextField: false
                ))
            }
        } else if let textField = view as? UITextField {
            let text = textField.text ?? ""
            let placeholder = textField.placeholder ?? ""
            let label = text.isEmpty ? placeholder : text
            if !label.isEmpty {
                results.append(Element(
                    label: label,
                    type: "SearchField",
                    frame: frame,
                    value: text.isEmpty ? nil : text,
                    traits: .searchField,
                    isButton: false,
                    isTextField: true
                ))
            }
        } else if let textView = view as? UITextView, let text = textView.text, !text.isEmpty {
            results.append(Element(
                label: String(text.prefix(200)),
                type: "StaticText",
                frame: frame,
                value: nil,
                traits: .staticText,
                isButton: false,
                isTextField: false
            ))
        } else if let segmented = view as? UISegmentedControl {
            for i in 0..<segmented.numberOfSegments {
                if let title = segmented.titleForSegment(at: i) {
                    let segFrame = segmentFrame(segmented, index: i)
                    results.append(Element(
                        label: title,
                        type: "Button",
                        frame: segFrame,
                        value: i == segmented.selectedSegmentIndex ? "selected" : nil,
                        traits: .button,
                        isButton: true,
                        isTextField: false
                    ))
                }
            }
        } else if let tabBar = view as? UITabBar {
            for item in tabBar.items ?? [] {
                if let title = item.title {
                    // Approximate frame for each tab item
                    let itemCount = CGFloat(tabBar.items?.count ?? 1)
                    let index = CGFloat(tabBar.items?.firstIndex(of: item) ?? 0)
                    let itemWidth = frame.width / itemCount
                    let itemFrame = CGRect(
                        x: frame.origin.x + index * itemWidth,
                        y: frame.origin.y,
                        width: itemWidth,
                        height: frame.height
                    )
                    results.append(Element(
                        label: title,
                        type: "TabBar",
                        frame: itemFrame,
                        value: item == tabBar.selectedItem ? "selected" : nil,
                        traits: .button,
                        isButton: true,
                        isTextField: false
                    ))
                }
            }
        } else if let navBar = view as? UINavigationBar {
            if let title = navBar.topItem?.title, !title.isEmpty {
                results.append(Element(
                    label: title,
                    type: "Header",
                    frame: frame,
                    value: nil,
                    traits: .header,
                    isButton: false,
                    isTextField: false
                ))
            }
        } else if let imageView = view as? UIImageView {
            let label = view.accessibilityLabel ?? ""
            if !label.isEmpty {
                results.append(Element(
                    label: label,
                    type: "Image",
                    frame: frame,
                    value: nil,
                    traits: .image,
                    isButton: false,
                    isTextField: false
                ))
            }
        }

        // Recurse into subviews
        for subview in view.subviews {
            scanViewHierarchy(subview, into: &results)
        }
    }

    private static func segmentFrame(_ control: UISegmentedControl, index: Int) -> CGRect {
        let frame = control.convert(control.bounds, to: nil)
        let count = CGFloat(control.numberOfSegments)
        let segWidth = frame.width / count
        return CGRect(
            x: frame.origin.x + CGFloat(index) * segWidth,
            y: frame.origin.y,
            width: segWidth,
            height: frame.height
        )
    }

    // MARK: - Helpers

    private static func isNooberView(_ view: UIView) -> Bool {
        String(describing: type(of: view)).contains("Noober")
    }

    private static func traitToType(_ traits: UIAccessibilityTraits) -> String {
        if traits.contains(.button) { return "Button" }
        if traits.contains(.link) { return "Link" }
        if traits.contains(.image) { return "Image" }
        if traits.contains(.searchField) { return "SearchField" }
        if traits.contains(.header) { return "Header" }
        if traits.contains(.staticText) { return "StaticText" }
        if traits.contains(.adjustable) { return "Slider" }
        if traits.contains(.tabBar) { return "TabBar" }
        return "Other"
    }

    static var appWindows: [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !($0 is BubbleWindow) && !NooberWindow.shared.isNooberWindow($0) && !$0.isHidden }
    }

    private static var appWindow: UIWindow? {
        let windows = appWindows
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
}
