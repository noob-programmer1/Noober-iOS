import UIKit
import SwiftUI

// MARK: - Tab Enums

enum NooberTab: Int, CaseIterable {
    case network = 0
    case storage = 1
    case logs = 2
    case rules = 3
    case qa = 4
}

enum StorageSection: Int, CaseIterable {
    case userDefaults = 0
    case keychain = 1
    case appInfo = 2
}

enum RulesSection: Int, CaseIterable {
    case rewrite = 0
    case mocks = 1
    case intercept = 2
    case environment = 3
}

@MainActor
final class NooberWindow {

    static let shared = NooberWindow()

    private var overlayWindow: BubbleWindow?
    private var debuggerWindow: UIWindow?

    private(set) var isDebuggerShowing = false

    /// The bubble reports its screen-space frame here so the window can do hit testing.
    var bubbleFrame: CGRect = .zero

    func showBubble() {
        guard overlayWindow == nil else { return }
        guard let scene = activeWindowScene else { return }

        let window = BubbleWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let bubbleView = FloatingBubbleView { [weak self] in
            self?.showDebugger()
        }
        let host = UIHostingController(rootView: bubbleView)
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false

        overlayWindow = window
    }

    func hideBubble() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
        hideDebugger()
    }

    func showDebugger() {
        guard debuggerWindow == nil else { return }
        guard let scene = overlayWindow?.windowScene else { return }

        isDebuggerShowing = true

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 2

        let dismiss: () -> Void = { [weak self] in self?.hideDebugger() }

        let tabBarController = UITabBarController()
        tabBarController.tabBar.tintColor = UIColor(red: 0.25, green: 0.48, blue: 1.0, alpha: 1.0)
        tabBarController.viewControllers = [
            makeTab(NetworkTabContent(), title: "Network", icon: "antenna.radiowaves.left.and.right", dismiss: dismiss),
            makeTab(StorageTabContent(), title: "Storage", icon: "externaldrive", dismiss: dismiss),
            makeTab(LogsTabContent(), title: "Logs", icon: "list.bullet.rectangle", dismiss: dismiss),
            makeTab(RulesTabContent(), title: "Rules", icon: "shuffle", dismiss: dismiss),
            makeTab(QATabContent(), title: "QA", icon: "checklist", dismiss: dismiss),
        ]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        debuggerWindow = window
        overlayWindow?.isHidden = true
    }

    private func makeTab<V: View>(_ rootView: V, title: String, icon: String, dismiss: @escaping () -> Void) -> UIViewController {
        let host = UIHostingController(rootView: rootView)
        if #available(iOS 16, *) {
            host.sizingOptions = []
        }
        host.view.backgroundColor = .systemBackground

        // Navigation bar via UIKit (replaces SwiftUI NavigationView)
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 1
        let nooberLabel = UILabel()
        nooberLabel.text = "NOOBER"
        nooberLabel.font = UIFont.systemFont(ofSize: 9, weight: .heavy)
        nooberLabel.textColor = UIColor(red: 0.25, green: 0.48, blue: 1.0, alpha: 1.0)
        let tabLabel = UILabel()
        tabLabel.text = title
        tabLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleStack.addArrangedSubview(nooberLabel)
        titleStack.addArrangedSubview(tabLabel)
        host.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleStack)

        let dismissImage = UIImage(systemName: "xmark.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 24))
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(.tertiaryLabel)
        host.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: dismissImage,
            primaryAction: UIAction { _ in dismiss() }
        )

        let nav = UINavigationController(rootViewController: host)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), tag: 0)
        return nav
    }

    func hideDebugger() {
        isDebuggerShowing = false
        debuggerWindow?.isHidden = true
        debuggerWindow = nil
        overlayWindow?.isHidden = false
    }

    /// Select a debugger tab.
    func selectTab(_ tab: NooberTab) {
        guard let tabBar = debuggerWindow?.rootViewController as? UITabBarController else { return }
        tabBar.selectedIndex = tab.rawValue
    }

    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    private init() {}
}

// MARK: - BubbleWindow

/// Custom UIWindow that only intercepts touches landing on the floating bubble.
/// All other touches pass through to the app windows below.
final class BubbleWindow: UIWindow {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitArea = NooberWindow.shared.bubbleFrame.insetBy(dx: -10, dy: -10)
        return hitArea.contains(point)
    }
}
