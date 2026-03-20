import UIKit

/// In-process screenshot capture — faster than XcodeBuildMCP's simctl-based screenshot.
@MainActor
public enum InProcessScreenshot {
    /// Capture the app's key window as base64-encoded PNG.
    public static func capture() -> String? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { !($0 is BubbleWindow) && $0.isKeyWindow }) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        return image.pngData()?.base64EncodedString()
    }
}

/// Lightweight in-process accessibility tree snapshot.
/// Runs inside the app — no XCTest overhead. Returns in milliseconds, not 20-30 seconds.
@MainActor
public enum ViewHierarchySnapshot {

    /// A simplified element from the view hierarchy
    public struct Element {
        public let label: String?
        public let identifier: String?
        public let type: String       // "Button", "Label", "Cell", etc.
        public let frame: CGRect      // in screen coordinates
        public let isInteractive: Bool

        public var bestName: String? {
            label ?? identifier
        }
    }

    /// Snapshot all accessible elements in the current app window.
    /// Returns elements sorted by Y position (top to bottom).
    public static func capture() -> [Element] {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { !($0 is BubbleWindow) && $0.isKeyWindow }) else {
            return []
        }

        var elements: [Element] = []
        walkView(window, in: window, into: &elements)
        return elements.sorted { $0.frame.minY < $1.frame.minY }
    }

    /// Find the element closest to a given point
    public static func elementNear(x: CGFloat, y: CGFloat) -> Element? {
        let elements = capture()
        let point = CGPoint(x: x, y: y)

        return elements
            .filter { $0.isInteractive }
            .min(by: {
                distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame)
            })
    }

    /// Walk the view hierarchy recursively
    private static func walkView(_ view: UIView, in window: UIWindow, into elements: inout [Element]) {
        // Skip hidden views and Noober windows
        guard !view.isHidden, view.alpha > 0.01 else { return }
        if String(describing: type(of: view)).contains("Noober") { return }

        let frame = view.convert(view.bounds, to: window)

        // Check if this view is an accessible element
        let label = view.accessibilityLabel
        let identifier = view.accessibilityIdentifier
        let isAccessible = view.isAccessibilityElement

        // Determine type
        let typeName: String
        if view is UIButton { typeName = "Button" }
        else if view is UILabel { typeName = "Label" }
        else if view is UITextField { typeName = "TextField" }
        else if view is UITextView { typeName = "TextView" }
        else if view is UISwitch { typeName = "Switch" }
        else if view is UISlider { typeName = "Slider" }
        else if view is UIImageView { typeName = "Image" }
        else if view is UITableViewCell { typeName = "Cell" }
        else if view is UICollectionViewCell { typeName = "Cell" }
        else { typeName = String(describing: type(of: view)).components(separatedBy: ".").last ?? "View" }

        // Determine if interactive
        let isInteractive = view.isUserInteractionEnabled && (
            view is UIControl ||
            view.gestureRecognizers?.isEmpty == false ||
            isAccessible
        )

        // Only include if it has a label/identifier or is interactive
        if label != nil || identifier != nil || (isInteractive && frame.width > 10 && frame.height > 10) {
            let element = Element(
                label: label,
                identifier: identifier,
                type: typeName,
                frame: frame,
                isInteractive: isInteractive
            )
            // Avoid duplicates with same label at same position
            if !elements.contains(where: { $0.label == element.label && $0.frame == element.frame }) {
                elements.append(element)
            }
        }

        // Recurse into subviews (but not too deep for performance)
        for subview in view.subviews {
            walkView(subview, in: window, into: &elements)
        }
    }

    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        if rect.contains(point) { return 0 }
        let cx = max(rect.minX, min(point.x, rect.maxX))
        let cy = max(rect.minY, min(point.y, rect.maxY))
        return hypot(point.x - cx, point.y - cy)
    }
}
