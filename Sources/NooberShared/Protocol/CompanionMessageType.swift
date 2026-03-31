import Foundation

public enum CompanionMessageType: String, Codable, Sendable {
    // iOS -> macOS
    case syncFull = "sync.full"
    case eventHttpRequest = "event.httpRequest"
    case eventWsConnection = "event.wsConnection"
    case eventWsFrame = "event.wsFrame"
    case eventWsStatusChange = "event.wsStatusChange"
    case eventWsClose = "event.wsClose"
    case eventLog = "event.log"
    case eventEnvironmentChanged = "event.environmentChanged"
    case eventRulesChanged = "event.rulesChanged"
    case eventQAStatusChanged = "event.qaStatusChanged"
    case eventClear = "event.clear"
    case heartbeat = "heartbeat"

    // macOS -> iOS (commands)
    case commandSwitchEnvironment = "command.switchEnvironment"
    case commandClearStore = "command.clearStore"
    case commandToggleRule = "command.toggleRule"
    case commandReplayRequest = "command.replayRequest"
    case commandFireDeepLink = "command.fireDeepLink"
    case commandMarkQAPassed = "command.markQAPassed"
    case commandMarkQAFailed = "command.markQAFailed"
    case commandResetQAItem = "command.resetQAItem"
    case commandFetchBody = "command.fetchBody"
    case commandAddMockRule = "command.addMockRule"
    case commandRemoveMockRule = "command.removeMockRule"
    case commandAddInterceptRule = "command.addInterceptRule"
    case commandRemoveInterceptRule = "command.removeInterceptRule"
    case commandFindElement = "command.findElement"
    case commandScreenText = "command.screenText"
    case commandRequestSnapshot = "command.requestSnapshot"
    case commandRequestScreenshot = "command.requestScreenshot"
    case commandScreenHTML = "command.screenHTML"

    // iOS -> macOS (responses)
    case responseFindElement = "response.findElement"
    case responseScreenText = "response.screenText"
    case responseSnapshot = "response.snapshot"
    case responseScreenshot = "response.screenshot"
    case responseScreenHTML = "response.screenHTML"
}
