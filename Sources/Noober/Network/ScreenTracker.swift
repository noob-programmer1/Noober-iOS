import UIKit
import os

/// Tracks the currently visible view controller by swizzling `viewDidAppear(_:)`.
/// Thread-safe via `OSAllocatedUnfairLock`.
final class ScreenTracker: @unchecked Sendable {

    static let shared = ScreenTracker()

    // MARK: - Thread-safe storage

    private let lock = NSLock()
    private var _currentScreen: String = "Unknown"
    private var _screenHistory: [(name: String, timestamp: Date)] = []

    var currentScreen: String {
        lock.withLock { _currentScreen }
    }

    var screenHistory: [(name: String, timestamp: Date)] {
        lock.withLock { _screenHistory }
    }

    /// Manual screen tracking — called by `Noober.shared.trackScreen(_:)`.
    /// Use when your app has a custom navigation system.
    func manualTrack(_ name: String) {
        lock.withLock {
            _currentScreen = name
            if _screenHistory.last?.name != name {
                _screenHistory.append((name: name, timestamp: Date()))
                if _screenHistory.count > 200 {
                    _screenHistory.removeFirst(_screenHistory.count - 200)
                }
            }
        }
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
            let original = unsafeBitCast(originalIMP!, to: (@convention(c) (UIViewController, Selector, Bool) -> Void).self)
            original(vc, originalSelector, animated)
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

        lock.withLock {
            _currentScreen = name
            if _screenHistory.last?.name != name {
                _screenHistory.append((name: name, timestamp: Date()))
                if _screenHistory.count > 200 {
                    _screenHistory.removeFirst(_screenHistory.count - 200)
                }
            }
        }
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

        if ignoredVCTypes.contains(className) { return false }

        // UIHostingController: track only if vc.title is set (via .navigationTitle)
        // Apps with custom nav should use Noober.shared.trackScreen(_:) instead
        if className.hasPrefix("UIHostingController") {
            if let title = vc.title, !title.isEmpty, title.count < 60 { return true }
            return false
        }

        if className.hasPrefix("_") { return false }

        let bundle = Bundle(for: type(of: vc))
        if bundle == Bundle(for: ScreenTracker.self) { return false }

        return true
    }

    static func humanReadableName(for vc: UIViewController) -> String {
        let className = String(describing: type(of: vc))

        if className.hasPrefix("UIHostingController") {
            return vc.title ?? "Unknown Screen"
        }

        var name = className
        for suffix in ["ViewController", "Controller", "Screen", "View"] {
            if name.hasSuffix(suffix) && name.count > suffix.count {
                name = String(name.dropLast(suffix.count))
                break
            }
        }

        var result = ""
        for (i, char) in name.enumerated() {
            if i > 0 && char.isUppercase {
                let prev = name[name.index(name.startIndex, offsetBy: i - 1)]
                if prev.isLowercase { result.append(" ") }
            }
            result.append(char)
        }

        return result.isEmpty ? className : result
    }

    private init() {}
}
