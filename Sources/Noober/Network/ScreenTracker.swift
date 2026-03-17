import UIKit
import os

/// Tracks the currently visible view controller by swizzling `viewDidAppear(_:)`.
/// Thread-safe: writes happen on the main thread, reads can happen from any thread.
final class ScreenTracker: @unchecked Sendable {

    static let shared = ScreenTracker()

    // MARK: - Thread-safe storage

    private var _lock = os_unfair_lock()
    private var _currentScreen: String = "Unknown"
    private var _screenHistory: [(name: String, timestamp: Date)] = []

    var currentScreen: String {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        return _currentScreen
    }

    var screenHistory: [(name: String, timestamp: Date)] {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        return _screenHistory
    }

    // MARK: - Swizzle state

    nonisolated(unsafe) private static var isInstalled = false
    nonisolated(unsafe) private static var originalIMP: IMP?

    // MARK: - Install / Uninstall

    static func install() {
        guard !isInstalled else { return }
        isInstalled = true

        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector) else { return }

        originalIMP = method_getImplementation(originalMethod)

        let swizzledBlock: @convention(block) (UIViewController, Bool) -> Void = { vc, animated in
            // Call original implementation
            let original = unsafeBitCast(originalIMP!, to: (@convention(c) (UIViewController, Selector, Bool) -> Void).self)
            original(vc, originalSelector, animated)

            // Track the screen
            shared.handleViewDidAppear(vc)
        }

        method_setImplementation(originalMethod, imp_implementationWithBlock(swizzledBlock))
    }

    static func uninstall() {
        guard isInstalled, let imp = originalIMP else { return }
        isInstalled = false

        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector) else { return }

        method_setImplementation(originalMethod, imp)
        originalIMP = nil
    }

    // MARK: - VC Filtering & Name Formatting

    private func handleViewDidAppear(_ vc: UIViewController) {
        guard Self.shouldTrack(vc) else { return }

        let name = Self.humanReadableName(for: vc)
        os_unfair_lock_lock(&_lock)
        _currentScreen = name
        // Avoid consecutive duplicates in history
        if _screenHistory.last?.name != name {
            _screenHistory.append((name: name, timestamp: Date()))
            // Keep history bounded
            if _screenHistory.count > 200 {
                _screenHistory.removeFirst(_screenHistory.count - 200)
            }
        }
        os_unfair_lock_unlock(&_lock)
    }

    private static let ignoredVCTypes: Set<String> = [
        "UINavigationController",
        "UITabBarController",
        "UIPageViewController",
        "UIAlertController",
        "UIInputWindowController",
        "_UIContextMenuActionsOnlyViewController",
        "UIHostingController",
    ]

    private static func shouldTrack(_ vc: UIViewController) -> Bool {
        let className = String(describing: type(of: vc))

        // Filter system containers
        if ignoredVCTypes.contains(className) { return false }

        // Filter UIHostingController generics (e.g. "UIHostingController<SomeView>")
        if className.hasPrefix("UIHostingController") { return false }

        // Filter private system VCs (prefixed with _)
        if className.hasPrefix("_") { return false }

        // Filter Noober's own VCs
        let bundle = Bundle(for: type(of: vc))
        if bundle == Bundle(for: ScreenTracker.self) { return false }

        return true
    }

    /// Converts `HomeViewController` → `Home`, `UserProfileController` → `User Profile`.
    static func humanReadableName(for vc: UIViewController) -> String {
        var name = String(describing: type(of: vc))

        // Strip common suffixes
        for suffix in ["ViewController", "Controller", "Screen", "View"] {
            if name.hasSuffix(suffix) && name.count > suffix.count {
                name = String(name.dropLast(suffix.count))
                break
            }
        }

        // Insert spaces before capitals: "UserProfile" → "User Profile"
        var result = ""
        for (i, char) in name.enumerated() {
            if i > 0 && char.isUppercase {
                let prev = name[name.index(name.startIndex, offsetBy: i - 1)]
                if prev.isLowercase {
                    result.append(" ")
                }
            }
            result.append(char)
        }

        return result.isEmpty ? String(describing: type(of: vc)) : result
    }

    private init() {}
}
