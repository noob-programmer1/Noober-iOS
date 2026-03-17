import Foundation
import ObjectiveC

/// Intercepts URLSessionWebSocketTask send/receive by swizzling the private
/// `__NSURLSessionWebSocketTask` class. This captures all WebSocket traffic
/// that goes through URLSession (the standard iOS WebSocket API).
final class WebSocketInterceptor: @unchecked Sendable {

    static let shared = WebSocketInterceptor()

    private var isSwizzled = false

    /// Maps ObjectIdentifier of a task → connection ID
    private var trackedTasks: [ObjectIdentifier: UUID] = [:]
    private let lock = NSLock()

    private init() {}

    // MARK: - Public

    func install() {
        guard !isSwizzled else { return }
        performSwizzling()
    }

    func uninstall() {
        // Swizzling is idempotent; clearing tracked tasks is sufficient
        lock.lock()
        trackedTasks.removeAll()
        lock.unlock()
    }

    // MARK: - Swizzling

    private func performSwizzling() {
        guard let wsClass = NSClassFromString("__NSURLSessionWebSocketTask") else { return }

        swizzleResume(in: wsClass)
        swizzleSendMessage(in: wsClass)
        swizzleReceiveMessage(in: wsClass)
        swizzleCancel(in: wsClass)

        isSwizzled = true
    }

    // MARK: - resume → track connection start

    private func swizzleResume(in cls: AnyClass) {
        let selector = NSSelectorFromString("resume")
        guard let original = class_getInstanceMethod(cls, selector) else { return }

        let originalIMP = method_getImplementation(original)
        typealias OriginalFunc = @convention(c) (AnyObject, Selector) -> Void
        let origFunc = unsafeBitCast(originalIMP, to: OriginalFunc.self)

        let block: @convention(block) (AnyObject) -> Void = { [weak self] task in
            origFunc(task, selector)
            self?.handleResume(task: task)
        }
        method_setImplementation(original, imp_implementationWithBlock(block))
    }

    // MARK: - sendMessage:completionHandler:

    private func swizzleSendMessage(in cls: AnyClass) {
        let selector = NSSelectorFromString("sendMessage:completionHandler:")
        guard let original = class_getInstanceMethod(cls, selector) else { return }

        let originalIMP = method_getImplementation(original)
        typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject, AnyObject?) -> Void
        let origFunc = unsafeBitCast(originalIMP, to: OriginalFunc.self)

        let block: @convention(block) (AnyObject, AnyObject, AnyObject?) -> Void = { [weak self] task, message, completion in
            origFunc(task, selector, message, completion)
            self?.handleSentMessage(task: task, message: message)
        }
        method_setImplementation(original, imp_implementationWithBlock(block))
    }

    // MARK: - receiveMessageWithCompletionHandler:

    private func swizzleReceiveMessage(in cls: AnyClass) {
        let selector = NSSelectorFromString("receiveMessageWithCompletionHandler:")
        guard let original = class_getInstanceMethod(cls, selector) else { return }

        let originalIMP = method_getImplementation(original)
        typealias OriginalFunc = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let origFunc = unsafeBitCast(originalIMP, to: OriginalFunc.self)

        let block: @convention(block) (AnyObject, @escaping @convention(block) (AnyObject?, AnyObject?) -> Void) -> Void = { [weak self] task, completion in

            let wrappedCompletion: @convention(block) (AnyObject?, AnyObject?) -> Void = { message, error in
                if let message {
                    self?.handleReceivedMessage(task: task, message: message)
                }
                completion(message, error)
            }

            origFunc(task, selector, wrappedCompletion as AnyObject)
        }
        method_setImplementation(original, imp_implementationWithBlock(block))
    }

    // MARK: - cancelWithCloseCode:reason:

    private func swizzleCancel(in cls: AnyClass) {
        let selector = NSSelectorFromString("cancelWithCloseCode:reason:")
        guard let original = class_getInstanceMethod(cls, selector) else { return }

        let originalIMP = method_getImplementation(original)
        typealias OriginalFunc = @convention(c) (AnyObject, Selector, Int, AnyObject?) -> Void
        let origFunc = unsafeBitCast(originalIMP, to: OriginalFunc.self)

        let block: @convention(block) (AnyObject, Int, AnyObject?) -> Void = { [weak self] task, closeCode, reason in
            origFunc(task, selector, closeCode, reason)
            self?.handleClose(task: task, closeCode: closeCode, reason: reason as? Data)
        }
        method_setImplementation(original, imp_implementationWithBlock(block))
    }

    // MARK: - Event Handlers

    private func handleResume(task: AnyObject) {
        guard let wsTask = task as? URLSessionWebSocketTask else { return }
        let urlString = wsTask.currentRequest?.url?.absoluteString ?? "ws://unknown"
        let connId = getOrCreateConnectionId(for: wsTask, url: urlString)

        Task { @MainActor in
            NetworkActivityStore.shared.updateWebSocketStatus(connectionId: connId, status: .connected)
        }
    }

    private func handleSentMessage(task: AnyObject, message: AnyObject) {
        guard let wsTask = task as? URLSessionWebSocketTask else { return }
        let connId = getOrCreateConnectionId(for: wsTask, url: wsTask.currentRequest?.url?.absoluteString ?? "ws://unknown")

        let frame = extractFrame(from: message, direction: .sent, connectionId: connId)

        Task { @MainActor in
            NetworkActivityStore.shared.addWebSocketFrame(frame, connectionId: connId)
        }
    }

    private func handleReceivedMessage(task: AnyObject, message: AnyObject) {
        guard let wsTask = task as? URLSessionWebSocketTask else { return }
        let connId = getOrCreateConnectionId(for: wsTask, url: wsTask.currentRequest?.url?.absoluteString ?? "ws://unknown")

        let frame = extractFrame(from: message, direction: .received, connectionId: connId)

        Task { @MainActor in
            NetworkActivityStore.shared.addWebSocketFrame(frame, connectionId: connId)
        }
    }

    private func handleClose(task: AnyObject, closeCode: Int, reason: Data?) {
        guard let wsTask = task as? URLSessionWebSocketTask else { return }
        let taskId = ObjectIdentifier(wsTask)

        lock.lock()
        let connId = trackedTasks[taskId]
        trackedTasks.removeValue(forKey: taskId)
        lock.unlock()

        guard let connId else { return }

        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) }

        Task { @MainActor in
            NetworkActivityStore.shared.closeWebSocket(connectionId: connId, closeCode: closeCode, reason: reasonString)
        }
    }

    // MARK: - Helpers

    private func getOrCreateConnectionId(for task: URLSessionWebSocketTask, url: String) -> UUID {
        let taskId = ObjectIdentifier(task)

        lock.lock()
        if let existing = trackedTasks[taskId] {
            lock.unlock()
            return existing
        }

        let connId = UUID()
        trackedTasks[taskId] = connId
        lock.unlock()

        Task { @MainActor in
            let connection = WebSocketConnectionModel(url: url)
            NetworkActivityStore.shared.addWebSocketConnection(connection, overrideId: connId)
        }

        return connId
    }

    private func extractFrame(from message: AnyObject, direction: WebSocketFrameModel.Direction, connectionId: UUID) -> WebSocketFrameModel {
        // URLSessionWebSocketTask.Message is an enum with .string and .data
        // When received via ObjC, we extract via KVC
        if let stringValue = message.value?(forKey: "string") as? String {
            return WebSocketFrameModel(
                connectionId: connectionId,
                direction: direction,
                frameType: .text,
                payload: stringValue.data(using: .utf8),
                payloadString: stringValue
            )
        }
        if let dataValue = message.value?(forKey: "data") as? Data {
            return WebSocketFrameModel(
                connectionId: connectionId,
                direction: direction,
                frameType: .binary,
                payload: dataValue,
                payloadString: String(data: dataValue, encoding: .utf8)
            )
        }
        // Fallback: try to convert description
        return WebSocketFrameModel(
            connectionId: connectionId,
            direction: direction,
            frameType: .text,
            payload: nil,
            payloadString: String(describing: message)
        )
    }
}
