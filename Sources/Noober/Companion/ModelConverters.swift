import Foundation
import UIKit

// MARK: - NetworkRequestModel -> TransferableNetworkRequest

extension NetworkRequestModel {
    func toTransferable() -> TransferableNetworkRequest {
        TransferableNetworkRequest(
            id: id,
            timestamp: timestamp,
            url: url,
            host: host,
            path: path,
            method: method,
            requestHeaders: requestHeaders,
            requestBody: requestBody,
            statusCode: statusCode,
            responseHeaders: responseHeaders,
            responseBody: responseBody,
            duration: duration,
            errorDescription: errorDescription,
            mimeType: mimeType,
            isMocked: isMocked,
            isIntercepted: isIntercepted,
            isEnvironmentRewritten: isEnvironmentRewritten,
            originalURL: originalURL,
            screenName: screenName
        )
    }
}

// MARK: - WebSocketConnectionModel -> TransferableWSConnection

extension WebSocketConnectionModel {
    func toTransferable() -> TransferableWSConnection {
        TransferableWSConnection(
            id: id,
            url: url,
            host: host,
            startTime: startTime,
            status: status.rawValue,
            frames: frames.map { $0.toTransferable(connectionId: id) },
            closeCode: closeCode,
            closeReason: closeReason
        )
    }
}

// MARK: - WebSocketFrameModel -> TransferableWSFrame

extension WebSocketFrameModel {
    func toTransferable(connectionId: UUID) -> TransferableWSFrame {
        TransferableWSFrame(
            id: id,
            connectionId: connectionId,
            timestamp: timestamp,
            direction: direction.rawValue,
            frameType: frameType.rawValue,
            payload: payload,
            payloadString: payloadString
        )
    }
}

// MARK: - LogEntry -> TransferableLogEntry

extension LogEntry {
    func toTransferable() -> TransferableLogEntry {
        TransferableLogEntry(
            id: id,
            timestamp: timestamp,
            level: level.rawValue,
            category: category.rawValue,
            message: message,
            file: file,
            line: line
        )
    }
}

// MARK: - NooberEnvironment -> TransferableEnvironment

extension NooberEnvironment {
    func toTransferable() -> TransferableEnvironment {
        TransferableEnvironment(
            id: id,
            name: name,
            baseURLs: baseURLs,
            notes: notes
        )
    }
}

// MARK: - URLMatchPattern -> TransferableURLMatchPattern

extension URLMatchPattern {
    func toTransferable() -> TransferableURLMatchPattern {
        TransferableURLMatchPattern(
            mode: mode.rawValue,
            pattern: pattern
        )
    }
}

// MARK: - URLRewriteRule -> TransferableRewriteRule

extension URLRewriteRule {
    func toTransferable() -> TransferableRewriteRule {
        TransferableRewriteRule(
            id: id,
            name: name,
            matchPattern: matchPattern.toTransferable(),
            replacementHost: replacementHost,
            isEnabled: isEnabled,
            createdAt: createdAt
        )
    }
}

// MARK: - MockRule -> TransferableMockRule

extension MockRule {
    func toTransferable() -> TransferableMockRule {
        TransferableMockRule(
            id: id,
            name: name,
            matchPattern: matchPattern.toTransferable(),
            httpMethod: httpMethod,
            mockStatusCode: mockStatusCode,
            mockResponseHeaders: mockResponseHeaders,
            mockResponseBody: mockResponseBody,
            isEnabled: isEnabled,
            createdAt: createdAt
        )
    }
}

// MARK: - InterceptRule -> TransferableInterceptRule

extension InterceptRule {
    func toTransferable() -> TransferableInterceptRule {
        TransferableInterceptRule(
            id: id,
            name: name,
            matchPattern: matchPattern.toTransferable(),
            httpMethod: httpMethod,
            isEnabled: isEnabled,
            createdAt: createdAt
        )
    }
}

// MARK: - QAChecklistResult -> TransferableQAResult

extension QAChecklistResult {
    func toTransferable() -> TransferableQAResult {
        TransferableQAResult(
            id: id,
            title: title,
            notes: notes,
            priority: priority.rawValue,
            endpoints: endpoints,
            status: status.rawValue,
            failNotes: failNotes,
            attachedRequestIds: attachedRequestIds
        )
    }
}

// MARK: - UserDefaultsEntry -> TransferableUserDefaultsEntry

extension UserDefaultsEntry {
    func toTransferable() -> TransferableUserDefaultsEntry {
        TransferableUserDefaultsEntry(
            id: id,
            key: key,
            displayValue: displayValue,
            valueType: valueType.rawValue
        )
    }
}

// MARK: - KeychainEntry -> TransferableKeychainEntry

extension KeychainEntry {
    func toTransferable() -> TransferableKeychainEntry {
        TransferableKeychainEntry(
            id: id,
            itemClass: itemClass.rawValue,
            service: service,
            account: account,
            accessGroup: accessGroup,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            label: label
        )
    }
}
