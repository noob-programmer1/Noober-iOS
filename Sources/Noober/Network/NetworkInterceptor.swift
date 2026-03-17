import Foundation

final class NetworkInterceptor: URLProtocol, @unchecked Sendable {

    private static let handledKey = "com.noober.handled"

    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var urlResponse: URLResponse?
    private var startTime: Date?
    private var rewrittenFromURL: String?
    private var wasEnvironmentRewritten = false
    private var pendingInterceptId: UUID?
    private var wasIntercepted = false
    private var capturedScreenName: String?

    private lazy var internalSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.protocolClasses = config.protocolClasses?.filter { $0 != NetworkInterceptor.self }
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else {
            return false
        }
        guard let scheme = request.url?.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let tagged = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: tagged)

        capturedScreenName = ScreenTracker.shared.currentScreen
        startTime = Date()
        Task { @MainActor in
            NetworkActivityStore.shared.trackRequestStarted()
        }

        // 1. Check mock rules — return synthetic response without hitting network
        if let mockRule = RulesSnapshot.findMatchingMock(for: tagged as URLRequest) {
            serveMockResponse(for: tagged as URLRequest, rule: mockRule)
            return
        }

        // 2. Check intercept rules — hold request until user acts
        if RulesSnapshot.findMatchingIntercept(for: tagged as URLRequest) != nil {
            let interceptId = UUID()
            self.pendingInterceptId = interceptId
            self.wasIntercepted = true
            InterceptManager.add(id: interceptId, interceptor: self, tagged: tagged)
            return  // Don't create dataTask — wait for user action
        }

        // 3. Check environment rewrite — change host/scheme/port for active environment
        if let originalURL = (tagged as URLRequest).url,
           let envRewrittenURL = EnvironmentSnapshot.rewriteURL(for: originalURL) {
            tagged.url = envRewrittenURL
            self.wasEnvironmentRewritten = true
            if self.rewrittenFromURL == nil {
                self.rewrittenFromURL = originalURL.absoluteString
            }
        }

        // 4. Check URL rewrite rules — modify URL before sending
        if let originalURL = (tagged as URLRequest).url,
           let rewrittenURL = RulesSnapshot.findRewriteURL(for: originalURL) {
            tagged.url = rewrittenURL
            if self.rewrittenFromURL == nil {
                self.rewrittenFromURL = originalURL.absoluteString
            }
        }

        dataTask = internalSession.dataTask(with: tagged as URLRequest)
        dataTask?.resume()
    }

    override func stopLoading() {
        // Clean up pending intercept if the original session cancelled/timed out
        if let interceptId = pendingInterceptId {
            pendingInterceptId = nil
            InterceptManager.remove(id: interceptId)
        }
        dataTask?.cancel()
        dataTask = nil
    }

    // MARK: - Intercept Actions (called by InterceptManager)

    func proceedWithRequest(_ modifiedRequest: URLRequest) {
        pendingInterceptId = nil

        // Apply environment rewrite, then manual rewrite rules
        let tagged = (modifiedRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        if let originalURL = (tagged as URLRequest).url,
           let envRewrittenURL = EnvironmentSnapshot.rewriteURL(for: originalURL) {
            tagged.url = envRewrittenURL
            self.wasEnvironmentRewritten = true
            if self.rewrittenFromURL == nil {
                self.rewrittenFromURL = originalURL.absoluteString
            }
        }
        if let originalURL = (tagged as URLRequest).url,
           let rewrittenURL = RulesSnapshot.findRewriteURL(for: originalURL) {
            tagged.url = rewrittenURL
            if self.rewrittenFromURL == nil {
                self.rewrittenFromURL = originalURL.absoluteString
            }
        }

        dataTask = internalSession.dataTask(with: tagged as URLRequest)
        dataTask?.resume()
    }

    func cancelInterceptedRequest() {
        pendingInterceptId = nil
        let error = NSError(domain: "com.noober.intercepted", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Request cancelled by Noober intercept"
        ])
        client?.urlProtocol(self, didFailWithError: error)

        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let model = NetworkRequestModel(
            request: request,
            duration: duration,
            error: error,
            isIntercepted: true,
            screenName: capturedScreenName
        )
        Task { @MainActor in
            NetworkActivityStore.shared.trackRequestFinished()
            NetworkActivityStore.shared.addRequest(model)
        }
    }
}

// MARK: - Mock Response

extension NetworkInterceptor {

    private func serveMockResponse(for request: URLRequest, rule: MockRule) {
        let url = request.url ?? URL(string: "https://mock")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: rule.mockStatusCode,
            httpVersion: "HTTP/1.1",
            headerFields: rule.mockResponseHeaders
        )!

        let body = rule.mockResponseBody ?? Data()

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if !body.isEmpty {
            client?.urlProtocol(self, didLoad: body)
        }
        client?.urlProtocolDidFinishLoading(self)

        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let model = NetworkRequestModel(
            request: request,
            response: response,
            responseBody: body.isEmpty ? nil : body,
            duration: duration,
            isMocked: true,
            screenName: capturedScreenName
        )

        Task { @MainActor in
            NetworkActivityStore.shared.trackRequestFinished()
            NetworkActivityStore.shared.addRequest(model)
        }
    }
}

// MARK: - URLSessionDataDelegate

extension NetworkInterceptor: URLSessionDataDelegate {

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        urlResponse = response
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0

        let model = NetworkRequestModel(
            request: request,
            response: urlResponse as? HTTPURLResponse,
            responseBody: receivedData,
            duration: duration,
            error: error,
            isIntercepted: wasIntercepted,
            isEnvironmentRewritten: wasEnvironmentRewritten,
            originalURL: rewrittenFromURL,
            screenName: capturedScreenName
        )

        Task { @MainActor in
            NetworkActivityStore.shared.trackRequestFinished()
            NetworkActivityStore.shared.addRequest(model)
        }

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}

// MARK: - Install / Uninstall

extension NetworkInterceptor {

    static func install() {
        URLProtocol.registerClass(NetworkInterceptor.self)
        swizzleSessionConfigurations()
    }

    static func uninstall() {
        URLProtocol.unregisterClass(NetworkInterceptor.self)
    }
}
