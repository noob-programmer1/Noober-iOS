import Foundation
import UIKit

@MainActor
enum CommandHandler {

    static func handle(_ message: CompanionMessage) {
        switch message.type {
        case .commandSwitchEnvironment:
            handleSwitchEnvironment(message)
        case .commandClearStore:
            handleClearStore(message)
        case .commandToggleRule:
            handleToggleRule(message)
        case .commandReplayRequest:
            handleReplayRequest(message)
        case .commandFireDeepLink:
            handleFireDeepLink(message)
        case .commandMarkQAPassed:
            handleMarkQAPassed(message)
        case .commandMarkQAFailed:
            handleMarkQAFailed(message)
        case .commandResetQAItem:
            handleResetQAItem(message)
        case .commandAddMockRule:
            handleAddMockRule(message)
        case .commandRemoveMockRule:
            handleRemoveMockRule(message)
        case .commandAddInterceptRule:
            handleAddInterceptRule(message)
        case .commandRemoveInterceptRule:
            handleRemoveInterceptRule(message)
        case .commandFindElement:
            handleFindElement(message)
        case .commandScreenText:
            handleScreenText()
        case .commandRequestSnapshot:
            handleSnapshot()
        case .commandRequestScreenshot:
            handleScreenshot()
        case .commandScreenHTML:
            handleScreenHTML()
        default:
            break
        }
    }

    // MARK: - Environment

    private static func handleSwitchEnvironment(_ message: CompanionMessage) {
        guard let command = try? message.decode(SwitchEnvironmentCommand.self) else { return }
        EnvironmentStore.shared.activate(id: command.environmentId)
    }

    // MARK: - Clear Store

    private static func handleClearStore(_ message: CompanionMessage) {
        guard let command = try? message.decode(ClearStoreCommand.self) else { return }
        switch command.store {
        case "http":
            NetworkActivityStore.shared.clearHTTP()
        case "websocket":
            NetworkActivityStore.shared.clearWebSockets()
        case "logs":
            LogStore.shared.clearAll()
        case "rules.rewrite":
            RulesStore.shared.clearAllRewriteRules()
        case "rules.mock":
            RulesStore.shared.clearAllMockRules()
        case "rules.intercept":
            RulesStore.shared.clearAllInterceptRules()
        case "userDefaults":
            UserDefaultsStore.shared.clearAll()
        case "keychain":
            KeychainStore.shared.clearAll()
        case "qa":
            QAChecklistStore.shared.clearAll()
        case "all":
            NetworkActivityStore.shared.clearAll()
            LogStore.shared.clearAll()
            QAChecklistStore.shared.clearAll()
        default:
            break
        }
    }

    // MARK: - Toggle Rule

    private static func handleToggleRule(_ message: CompanionMessage) {
        guard let command = try? message.decode(ToggleRuleCommand.self) else { return }
        let store = RulesStore.shared
        switch command.ruleType {
        case "rewrite":
            if let rule = store.rewriteRules.first(where: { $0.id == command.ruleId }) {
                store.toggleRewriteRule(rule)
            }
        case "mock":
            if let rule = store.mockRules.first(where: { $0.id == command.ruleId }) {
                store.toggleMockRule(rule)
            }
        case "intercept":
            if let rule = store.interceptRules.first(where: { $0.id == command.ruleId }) {
                store.toggleInterceptRule(rule)
            }
        default:
            break
        }
    }

    // MARK: - Add/Remove Rules

    struct AddMockRuleCommand: Codable {
        let urlPattern: String
        let matchMode: String?    // "contains", "prefix", "regex" — default "contains"
        let httpMethod: String?
        let statusCode: Int
        let responseBody: String?
        let responseHeaders: [String: String]?
        let name: String?
    }

    struct RemoveRuleCommand: Codable {
        let ruleId: String
    }

    struct AddInterceptRuleCommand: Codable {
        let urlPattern: String
        let matchMode: String?
        let httpMethod: String?
        let name: String?
    }

    private static func handleAddMockRule(_ message: CompanionMessage) {
        guard let cmd = try? message.decode(AddMockRuleCommand.self) else { return }
        let store = RulesStore.shared
        let rule = MockRule(
            name: cmd.name ?? "Mock \(cmd.urlPattern.prefix(30))",
            matchPattern: URLMatchPattern(
                mode: URLMatchPattern.MatchMode(rawValue: cmd.matchMode ?? "contains") ?? .contains,
                pattern: cmd.urlPattern
            ),
            httpMethod: cmd.httpMethod,
            mockStatusCode: cmd.statusCode,
            mockResponseHeaders: cmd.responseHeaders ?? ["Content-Type": "application/json"],
            mockResponseBody: cmd.responseBody?.data(using: .utf8)
        )
        store.addMockRule(rule)
    }

    private static func handleRemoveMockRule(_ message: CompanionMessage) {
        guard let cmd = try? message.decode(RemoveRuleCommand.self),
              let uuid = UUID(uuidString: cmd.ruleId),
              let rule = RulesStore.shared.mockRules.first(where: { $0.id == uuid }) else { return }
        RulesStore.shared.removeMockRule(rule)
    }

    private static func handleAddInterceptRule(_ message: CompanionMessage) {
        guard let cmd = try? message.decode(AddInterceptRuleCommand.self) else { return }
        let store = RulesStore.shared
        let rule = InterceptRule(
            name: cmd.name ?? "Intercept \(cmd.urlPattern.prefix(30))",
            matchPattern: URLMatchPattern(
                mode: URLMatchPattern.MatchMode(rawValue: cmd.matchMode ?? "contains") ?? .contains,
                pattern: cmd.urlPattern
            ),
            httpMethod: cmd.httpMethod
        )
        store.addInterceptRule(rule)
    }

    private static func handleRemoveInterceptRule(_ message: CompanionMessage) {
        guard let cmd = try? message.decode(RemoveRuleCommand.self),
              let uuid = UUID(uuidString: cmd.ruleId),
              let rule = RulesStore.shared.interceptRules.first(where: { $0.id == uuid }) else { return }
        RulesStore.shared.removeInterceptRule(rule)
    }

    // MARK: - Replay Request

    private static func handleReplayRequest(_ message: CompanionMessage) {
        guard let command = try? message.decode(ReplayRequestCommand.self) else { return }
        RequestReplayer.replay(
            url: command.url,
            method: command.method,
            headers: command.headers,
            body: command.body
        )
    }

    // MARK: - Deep Link

    private static func handleFireDeepLink(_ message: CompanionMessage) {
        guard let command = try? message.decode(FireDeepLinkCommand.self) else { return }
        guard let url = URL(string: command.url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - QA Checklist

    private static func handleMarkQAPassed(_ message: CompanionMessage) {
        guard let command = try? message.decode(MarkQACommand.self) else { return }
        QAChecklistStore.shared.markPassed(id: command.itemId)
    }

    private static func handleMarkQAFailed(_ message: CompanionMessage) {
        guard let command = try? message.decode(MarkQACommand.self) else { return }
        QAChecklistStore.shared.markFailed(
            id: command.itemId,
            notes: command.notes ?? "",
            requestIds: command.requestIds ?? []
        )
    }

    private static func handleResetQAItem(_ message: CompanionMessage) {
        guard let command = try? message.decode(MarkQACommand.self) else { return }
        QAChecklistStore.shared.resetItem(id: command.itemId)
    }

    // MARK: - Find Element (accessibility-based, works with SwiftUI)

    private static func handleFindElement(_ message: CompanionMessage) {
        struct FindCommand: Decodable {
            let text: String
            let exact: Bool?
        }

        struct FoundElement: Codable {
            let label: String
            let type: String
            let x: Int
            let y: Int
            let width: Int
            let height: Int
            let centerX: Int
            let centerY: Int
            let isButton: Bool
        }

        struct FindResponse: Codable {
            let screen: String
            let query: String
            let results: [FoundElement]
        }

        guard let command = try? message.decode(FindCommand.self) else { return }
        let matches = AccessibilityScanner.find(text: command.text, exact: command.exact ?? false)
        let screen = ScreenTracker.shared.currentScreen

        let response = FindResponse(
            screen: screen,
            query: command.text,
            results: matches.map {
                FoundElement(
                    label: $0.label,
                    type: $0.type,
                    x: Int($0.frame.origin.x),
                    y: Int($0.frame.origin.y),
                    width: Int($0.frame.width),
                    height: Int($0.frame.height),
                    centerX: Int($0.frame.midX),
                    centerY: Int($0.frame.midY),
                    isButton: $0.isButton
                )
            }
        )

        if let msg = try? CompanionMessage(type: .responseFindElement, payload: response) {
            CompanionServer.shared.send(msg)
        }
    }

    // MARK: - Screen Text (all visible text, fast)

    private static func handleScreenText() {
        struct ScreenTextResponse: Codable {
            let screen: String
            let lines: [String]
        }

        let lines = AccessibilityScanner.allVisibleText()
        let screen = ScreenTracker.shared.currentScreen

        let response = ScreenTextResponse(screen: screen, lines: lines)
        if let msg = try? CompanionMessage(type: .responseScreenText, payload: response) {
            CompanionServer.shared.send(msg)
        }
    }

    // MARK: - In-Process Screenshot

    private static func handleScreenshot() {
        struct ScreenshotResponse: Codable {
            let screen: String
            let base64PNG: String
        }

        guard let base64 = InProcessScreenshot.capture() else { return }
        let response = ScreenshotResponse(
            screen: ScreenTracker.shared.currentScreen,
            base64PNG: base64
        )
        if let message = try? CompanionMessage(type: .responseScreenshot, payload: response) {
            CompanionServer.shared.send(message)
        }
    }

    // MARK: - Semantic HTML (CogniSim-inspired, optimized for LLM comprehension)

    private static func handleScreenHTML() {
        struct ScreenHTMLResponse: Codable {
            let screen: String
            let html: String
            let elementCount: Int
        }

        let elements = AccessibilityScanner.scanAll()
        let screen = ScreenTracker.shared.currentScreen

        // Compact semantic HTML — only tap coordinates + short labels to minimize tokens
        var html = "<html><title>\(escapeHTML(screen))</title>\n"
        for (i, el) in elements.enumerated() {
            let id = i + 1
            let cx = Int(el.frame.midX)
            let cy = Int(el.frame.midY)
            // Truncate long labels to save tokens
            let rawLabel = el.label
            let label = escapeHTML(rawLabel.count > 60 ? String(rawLabel.prefix(57)) + "..." : rawLabel)
            let val = el.value.map { v in " v=\"\(escapeHTML(String(v.prefix(30))))\"" } ?? ""

            switch el.type {
            case "Button":
                html += "<button id=\(id) c=\"\(cx),\(cy)\"\(val)>\(label)</button>\n"
            case "Link":
                html += "<a id=\(id) c=\"\(cx),\(cy)\">\(label)</a>\n"
            case "Image":
                html += "<img id=\(id) c=\"\(cx),\(cy)\" alt=\"\(label)\">\n"
            case "Header":
                html += "<h2 id=\(id) c=\"\(cx),\(cy)\">\(label)</h2>\n"
            case "SearchField":
                html += "<input id=\(id) c=\"\(cx),\(cy)\"\(val) placeholder=\"\(label)\">\n"
            case "Slider":
                html += "<input type=range id=\(id) c=\"\(cx),\(cy)\"\(val) label=\"\(label)\">\n"
            case "TabBar":
                html += "<nav id=\(id) c=\"\(cx),\(cy)\">\(label)</nav>\n"
            case "StaticText":
                html += "<p id=\(id) c=\"\(cx),\(cy)\">\(label)</p>\n"
            default:
                if el.isTextField {
                    html += "<input id=\(id) c=\"\(cx),\(cy)\"\(val) placeholder=\"\(label)\">\n"
                } else if el.isButton {
                    html += "<button id=\(id) c=\"\(cx),\(cy)\"\(val)>\(label)</button>\n"
                } else {
                    html += "<span id=\(id) c=\"\(cx),\(cy)\">\(label)</span>\n"
                }
            }
        }
        html += "</html>"

        let response = ScreenHTMLResponse(screen: screen, html: html, elementCount: elements.count)
        if let msg = try? CompanionMessage(type: .responseScreenHTML, payload: response) {
            CompanionServer.shared.send(msg)
        }
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - View Hierarchy Snapshot (fast, in-process)

    private static func handleSnapshot() {
        let elements = ViewHierarchySnapshot.capture()
        let screen = ScreenTracker.shared.currentScreen

        struct SnapshotElement: Codable {
            let label: String?
            let identifier: String?
            let type: String
            let x: Int
            let y: Int
            let width: Int
            let height: Int
            let interactive: Bool
        }

        struct SnapshotResponse: Codable {
            let screen: String
            let elements: [SnapshotElement]
        }

        let response = SnapshotResponse(
            screen: screen,
            elements: elements.map {
                SnapshotElement(
                    label: $0.label,
                    identifier: $0.identifier,
                    type: $0.type,
                    x: Int($0.frame.origin.x),
                    y: Int($0.frame.origin.y),
                    width: Int($0.frame.width),
                    height: Int($0.frame.height),
                    interactive: $0.isInteractive
                )
            }
        )

        if let message = try? CompanionMessage(type: .responseSnapshot, payload: response) {
            CompanionServer.shared.send(message)
        }
    }
}
