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
}
