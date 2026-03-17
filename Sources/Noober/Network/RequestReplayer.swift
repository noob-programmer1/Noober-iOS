import Foundation

/// Fires a URLRequest constructed from editable parameters.
/// The request will be intercepted by NetworkInterceptor and appear as a new entry.
enum RequestReplayer {

    static func replay(
        url: String,
        method: String,
        headers: [String: String],
        body: Data?
    ) {
        guard let requestURL = URL(string: url) else { return }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if method != "GET" && method != "HEAD" {
            request.httpBody = body
        }

        // Fire and forget — the interceptor will capture the result
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }

    /// Replay a captured request as-is, no editing.
    static func replay(from model: NetworkRequestModel) {
        replay(
            url: model.url,
            method: model.method,
            headers: model.requestHeaders,
            body: model.requestBody
        )
    }
}
