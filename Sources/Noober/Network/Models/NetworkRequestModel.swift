import Foundation
import UIKit

struct NetworkRequestModel: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let url: String
    let host: String
    let path: String
    let method: String
    let requestHeaders: [String: String]
    let requestBody: Data?
    let statusCode: Int?
    let responseHeaders: [String: String]
    let responseBody: Data?
    let duration: TimeInterval
    let errorDescription: String?
    let mimeType: String?
    let isMocked: Bool
    let isIntercepted: Bool
    let isEnvironmentRewritten: Bool
    let originalURL: String?
    let screenName: String?

    // MARK: - Content Type

    var contentType: ContentType {
        if let mime = mimeType?.lowercased() {
            if mime.contains("json") { return .json }
            if mime.contains("image") { return .image }
            if mime.contains("xml") { return .xml }
            if mime.contains("html") { return .html }
            if mime.contains("text") { return .text }
            if mime.contains("pdf") { return .pdf }
            if mime.contains("javascript") || mime.contains("css") { return .text }
        }
        // Fallback: try to detect from body
        if let data = responseBody, !data.isEmpty {
            if (try? JSONSerialization.jsonObject(with: data)) != nil { return .json }
            if UIImage(data: data) != nil { return .image }
        }
        if responseBody != nil { return .binary }
        return .unknown
    }

    var isImage: Bool { contentType == .image }

    var responseImage: UIImage? {
        guard isImage, let data = responseBody else { return nil }
        return UIImage(data: data)
    }

    var isSuccess: Bool {
        guard let code = statusCode else { return false }
        return (200..<300).contains(code)
    }

    var statusCodeCategory: StatusCodeCategory {
        guard let code = statusCode else { return .unknown }
        switch code {
        case 200..<300: return .success
        case 300..<400: return .redirect
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default: return .unknown
        }
    }

    var prettyResponseBody: String {
        prettyPrint(responseBody)
    }

    var prettyRequestBody: String {
        prettyPrint(requestBody)
    }

    var responseSizeText: String {
        guard let data = responseBody else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)
    }

    var durationText: String {
        let ms = duration * 1000
        if ms < 1000 {
            return String(format: "%.0fms", ms)
        } else {
            return String(format: "%.1fs", duration)
        }
    }

    private func prettyPrint(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "(empty)" }
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let string = String(data: pretty, encoding: .utf8) {
            return string
        }
        return String(data: data, encoding: .utf8) ?? "(binary, \(data.count) bytes)"
    }

    init(
        request: URLRequest,
        response: HTTPURLResponse? = nil,
        responseBody: Data? = nil,
        duration: TimeInterval = 0,
        error: Error? = nil,
        isMocked: Bool = false,
        isIntercepted: Bool = false,
        isEnvironmentRewritten: Bool = false,
        originalURL: String? = nil,
        screenName: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.url = request.url?.absoluteString ?? "unknown"
        self.host = request.url?.host ?? "unknown"
        self.path = request.url?.path ?? "/"
        self.method = request.httpMethod ?? "GET"
        self.requestHeaders = request.allHTTPHeaderFields ?? [:]
        // httpBody is often nil in URLProtocol because URLSession moves it to httpBodyStream
        self.requestBody = request.httpBody ?? request.httpBodyStream?.readAllData()
        self.statusCode = response?.statusCode
        self.mimeType = response?.mimeType
        self.responseHeaders = (response?.allHeaderFields as? [String: String]) ?? [:]
        self.responseBody = responseBody
        self.duration = duration
        self.errorDescription = error?.localizedDescription
        self.isMocked = isMocked
        self.isIntercepted = isIntercepted
        self.isEnvironmentRewritten = isEnvironmentRewritten
        self.originalURL = originalURL
        self.screenName = screenName
    }
}

// MARK: - InputStream Helper

extension InputStream {
    /// Reads all available data from the stream. Used to capture request bodies
    /// that URLSession converts from httpBody to httpBodyStream.
    func readAllData() -> Data? {
        open()
        defer { close() }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while hasBytesAvailable {
            let bytesRead = read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }

        return data.isEmpty ? nil : data
    }
}

// MARK: - Enums

extension NetworkRequestModel {
    enum StatusCodeCategory: String, CaseIterable, Sendable {
        case success = "2xx"
        case redirect = "3xx"
        case clientError = "4xx"
        case serverError = "5xx"
        case unknown = "ERR"
    }

    enum ContentType: String, Sendable {
        case json = "JSON"
        case image = "IMG"
        case xml = "XML"
        case html = "HTML"
        case text = "TXT"
        case pdf = "PDF"
        case binary = "BIN"
        case unknown = "—"
    }
}
