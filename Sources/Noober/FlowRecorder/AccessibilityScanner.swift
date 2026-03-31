import UIKit

/// Scans the accessibility tree from inside the app process.
/// Uses UIAccessibility APIs that SwiftUI DOES populate automatically
/// (unlike UIView.accessibilityLabel which is empty for SwiftUI views).
///
/// This is the same data XCTest's snapshot_ui reads, but 200x faster
/// because it runs in-process without IPC overhead.
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

    /// Scan all accessibility elements on screen.
    public static func scanAll() -> [Element] {
        guard let window = appWindow else { return [] }

        var elements: [Element] = []
        scanAccessibilityTree(window, into: &elements)

        // Deduplicate by label + frame
        var seen = Set<String>()
        elements = elements.filter { el in
            let key = "\(el.label)|\(Int(el.frame.minX)),\(Int(el.frame.minY))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        return elements.sorted { $0.frame.minY < $1.frame.minY }
    }

    // MARK: - Private: Accessibility tree traversal

    private static func scanAccessibilityTree(_ element: Any, into results: inout [Element]) {
        // Check if this element IS an accessibility element
        if let ax = element as? NSObject {
            let isElement = ax.isAccessibilityElement
            let label = ax.accessibilityLabel ?? ""
            let frame = ax.accessibilityFrame
            let traits = ax.accessibilityTraits
            let value = ax.accessibilityValue

            if isElement && !label.isEmpty && frame.width > 0 && frame.height > 0 {
                // Skip Noober's own elements
                if let view = element as? UIView,
                   String(describing: type(of: view)).contains("Noober") { /* skip */ }
                else {
                    let type = traitToType(traits)
                    results.append(Element(
                        label: label,
                        type: type,
                        frame: frame,
                        value: value,
                        traits: traits,
                        isButton: traits.contains(.button),
                        isTextField: traits.contains(.searchField) || element is UITextField
                    ))
                }
            }
        }

        // Recurse into children
        // Method 1: accessibilityElements (SwiftUI populates this)
        if let container = element as? NSObject,
           let children = container.accessibilityElements {
            for child in children {
                scanAccessibilityTree(child, into: &results)
            }
        }

        // Method 2: UIView subviews (catches UIKit views)
        if let view = element as? UIView {
            // Skip hidden and Noober windows
            if view.isHidden || view.alpha < 0.01 { return }
            if view is BubbleWindow { return }
            if String(describing: type(of: view)).contains("Noober") { return }

            for subview in view.subviews {
                scanAccessibilityTree(subview, into: &results)
            }
        }

        // Method 3: accessibilityElementCount (older API, some views use this)
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

    private static var appWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { !($0 is BubbleWindow) && $0.isKeyWindow }
    }
}
