import UIKit
import WebKit

/// Intercepts WKWebView network calls (fetch, XHR) and console.log by injecting JavaScript.
/// Automatically instruments all WKWebViews via swizzling.
@MainActor
public final class WebViewInterceptor {

    public static let shared = WebViewInterceptor()
    nonisolated(unsafe) private static var isInstalled = false

    // MARK: - Install (swizzles WKWebView init)

    public static func install() {
        guard !isInstalled else { return }
        isInstalled = true
        swizzleWKWebViewInit()
    }

    // MARK: - Manual instrumentation (if swizzle doesn't catch a webview)

    /// Call this on a WKWebView to add Noober interceptors manually.
    public static func instrument(_ webView: WKWebView) {
        let config = webView.configuration
        injectScripts(into: config.userContentController)
        registerMessageHandlers(on: config.userContentController)
    }

    // MARK: - JavaScript injection

    private static let interceptorJS = """
    // === Noober WebView Interceptor ===
    (function() {
        if (window.__nooberIntercepted) return;
        window.__nooberIntercepted = true;

        const rules = window.__nooberRules || { rewrites: [], mocks: [] };

        // --- Rule matching ---
        function matchesPattern(url, pattern, mode) {
            if (mode === 'contains') return url.indexOf(pattern) !== -1;
            if (mode === 'prefix') return url.indexOf(pattern) === 0;
            if (mode === 'regex') { try { return new RegExp(pattern).test(url); } catch(e) { return false; } }
            return url.indexOf(pattern) !== -1;
        }

        function findMockRule(url, method) {
            for (var i = 0; i < rules.mocks.length; i++) {
                var r = rules.mocks[i];
                if (matchesPattern(url, r.pattern, r.mode)) {
                    if (r.method && r.method !== method) continue;
                    return r;
                }
            }
            return null;
        }

        function applyRewrite(url) {
            for (var i = 0; i < rules.rewrites.length; i++) {
                var r = rules.rewrites[i];
                if (matchesPattern(url, r.pattern, r.mode)) {
                    try {
                        var parsed = new URL(url);
                        parsed.host = r.replacementHost;
                        return parsed.href;
                    } catch(e) {}
                }
            }
            return url;
        }

        // --- Intercept fetch ---
        const originalFetch = window.fetch;
        window.fetch = function(input, init) {
            const url = (typeof input === 'string') ? input : input.url;
            var fullUrl = new URL(url, window.location.href).href;
            const method = (init && init.method) || 'GET';
            const reqHeaders = (init && init.headers) ? Object.fromEntries(new Headers(init.headers).entries()) : {};
            const reqBody = (init && init.body) ? String(init.body).substring(0, 2000) : null;
            const startTime = Date.now();
            const requestId = Math.random().toString(36).substr(2, 9);

            // Check mock rules
            var mockRule = findMockRule(fullUrl, method);
            if (mockRule) {
                var mockBody = mockRule.body || '';
                var mockHeaders = mockRule.headers || {};
                window.webkit.messageHandlers.nooberNetwork.postMessage({
                    id: requestId, type: 'fetch', url: fullUrl, method: method,
                    status: mockRule.statusCode, duration: 0,
                    requestHeaders: reqHeaders, requestBody: reqBody,
                    responseBody: mockBody.substring(0, 2000),
                    headers: mockHeaders, mocked: true
                });
                return Promise.resolve(new Response(mockBody, {
                    status: mockRule.statusCode,
                    headers: mockHeaders
                }));
            }

            // Apply rewrite rules
            fullUrl = applyRewrite(fullUrl);

            // Override the input if URL was rewritten
            var fetchArgs = arguments;
            if (fullUrl !== new URL(url, window.location.href).href) {
                fetchArgs = [fullUrl, init];
            }

            return originalFetch.apply(this, fetchArgs).then(function(response) {
                const duration = Date.now() - startTime;
                const cloned = response.clone();
                cloned.text().then(function(body) {
                    window.webkit.messageHandlers.nooberNetwork.postMessage({
                        id: requestId,
                        type: 'fetch',
                        url: fullUrl,
                        method: method,
                        status: response.status,
                        duration: duration,
                        requestHeaders: reqHeaders,
                        requestBody: reqBody,
                        responseBody: body.substring(0, 2000),
                        headers: Object.fromEntries(response.headers.entries())
                    });
                }).catch(function() {});
                return response;
            }).catch(function(error) {
                const duration = Date.now() - startTime;
                window.webkit.messageHandlers.nooberNetwork.postMessage({
                    id: requestId,
                    type: 'fetch',
                    url: fullUrl,
                    method: method,
                    status: 0,
                    duration: duration,
                    requestHeaders: reqHeaders,
                    requestBody: reqBody,
                    error: error.message
                });
                throw error;
            });
        };

        // --- Intercept XMLHttpRequest ---
        const OrigXHR = window.XMLHttpRequest;
        window.XMLHttpRequest = function() {
            const xhr = new OrigXHR();
            const requestId = Math.random().toString(36).substr(2, 9);
            let method = 'GET';
            let url = '';
            let startTime = 0;
            let reqHeaders = {};
            let reqBody = null;

            const originalOpen = xhr.open;
            xhr.open = function(m, u) {
                method = m;
                url = new URL(u, window.location.href).href;
                // Apply rewrite rules
                url = applyRewrite(url);
                return originalOpen.call(xhr, m, url);
            };

            const originalSetHeader = xhr.setRequestHeader;
            xhr.setRequestHeader = function(key, value) {
                reqHeaders[key] = value;
                return originalSetHeader.apply(xhr, arguments);
            };

            const originalSend = xhr.send;
            xhr.send = function(body) {
                reqBody = body ? String(body).substring(0, 2000) : null;
                startTime = Date.now();

                // Check mock rules
                var mockRule = findMockRule(url, method);
                if (mockRule) {
                    window.webkit.messageHandlers.nooberNetwork.postMessage({
                        id: requestId, type: 'xhr', url: url, method: method,
                        status: mockRule.statusCode, duration: 0,
                        requestHeaders: reqHeaders, requestBody: reqBody,
                        responseBody: (mockRule.body || '').substring(0, 2000),
                        mocked: true
                    });
                    // Simulate XHR response
                    Object.defineProperty(xhr, 'status', { value: mockRule.statusCode });
                    Object.defineProperty(xhr, 'responseText', { value: mockRule.body || '' });
                    Object.defineProperty(xhr, 'readyState', { value: 4 });
                    if (xhr.onload) xhr.onload();
                    if (xhr.onreadystatechange) xhr.onreadystatechange();
                    return;
                }
                xhr.addEventListener('loadend', function() {
                    const duration = Date.now() - startTime;
                    try {
                        window.webkit.messageHandlers.nooberNetwork.postMessage({
                            id: requestId,
                            type: 'xhr',
                            url: url,
                            method: method,
                            status: xhr.status,
                            duration: duration,
                            requestHeaders: reqHeaders,
                            requestBody: reqBody,
                            responseBody: (xhr.responseText || '').substring(0, 2000)
                        });
                    } catch(e) {}
                });
                return originalSend.apply(xhr, arguments);
            };

            return xhr;
        };
        // Copy static methods
        Object.keys(OrigXHR).forEach(function(key) {
            try { window.XMLHttpRequest[key] = OrigXHR[key]; } catch(e) {}
        });
        window.XMLHttpRequest.prototype = OrigXHR.prototype;

        // --- Intercept console ---
        ['log', 'warn', 'error', 'info', 'debug'].forEach(function(level) {
            const original = console[level];
            console[level] = function() {
                const args = Array.from(arguments).map(function(a) {
                    try { return typeof a === 'object' ? JSON.stringify(a) : String(a); }
                    catch(e) { return String(a); }
                });
                try {
                    window.webkit.messageHandlers.nooberConsole.postMessage({
                        level: level,
                        message: args.join(' ')
                    });
                } catch(e) {}
                return original.apply(console, arguments);
            };
        });
    })();
    """;

    private static func injectScripts(into controller: WKUserContentController) {
        // Inject rules first, then the interceptor
        let rulesJS = buildRulesJS()
        let combined = rulesJS + "\n" + interceptorJS

        let script = WKUserScript(
            source: combined,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        controller.addUserScript(script)
    }

    /// Build JavaScript that sets window.__nooberRules from current RulesStore
    @MainActor
    private static func buildRulesJS() -> String {
        let store = RulesStore.shared

        // Rewrite rules
        var rewrites: [[String: String]] = []
        for rule in store.rewriteRules where rule.isEnabled {
            rewrites.append([
                "pattern": rule.matchPattern.pattern,
                "mode": rule.matchPattern.mode.rawValue,
                "replacementHost": rule.replacementHost,
            ])
        }

        // Mock rules
        var mocks: [[String: Any]] = []
        for rule in store.mockRules where rule.isEnabled {
            var mock: [String: Any] = [
                "pattern": rule.matchPattern.pattern,
                "mode": rule.matchPattern.mode.rawValue,
                "statusCode": rule.mockStatusCode,
            ]
            if let body = rule.mockResponseBody, let bodyStr = String(data: body, encoding: .utf8) {
                mock["body"] = bodyStr
            }
            mock["headers"] = rule.mockResponseHeaders
            if let method = rule.httpMethod { mock["method"] = method }
            mocks.append(mock)
        }

        guard let rewriteData = try? JSONSerialization.data(withJSONObject: rewrites),
              let mockData = try? JSONSerialization.data(withJSONObject: mocks),
              let rewriteStr = String(data: rewriteData, encoding: .utf8),
              let mockStr = String(data: mockData, encoding: .utf8) else {
            return "window.__nooberRules = { rewrites: [], mocks: [] };"
        }

        return "window.__nooberRules = { rewrites: \(rewriteStr), mocks: \(mockStr) };"
    }

    private static func registerMessageHandlers(on controller: WKUserContentController) {
        let handler = NooberWebViewMessageHandler()
        // Remove existing handlers first to avoid duplicates
        controller.removeScriptMessageHandler(forName: "nooberNetwork")
        controller.removeScriptMessageHandler(forName: "nooberConsole")
        controller.add(handler, name: "nooberNetwork")
        controller.add(handler, name: "nooberConsole")
    }

    // MARK: - Swizzle WKWebView

    nonisolated(unsafe) private static var originalInitIMP: IMP?

    private static func swizzleWKWebViewInit() {
        // Swizzle initWithFrame:configuration: to inject scripts into every WKWebView
        let sel = #selector(WKWebView.init(frame:configuration:))
        guard let method = class_getInstanceMethod(WKWebView.self, sel) else { return }
        originalInitIMP = method_getImplementation(method)

        let block: @convention(block) (WKWebView, CGRect, WKWebViewConfiguration) -> WKWebView = { webView, frame, config in
            // Inject our scripts before the original init processes the config
            injectScripts(into: config.userContentController)
            registerMessageHandlers(on: config.userContentController)

            // Call original init
            let original = unsafeBitCast(originalInitIMP!, to: (@convention(c) (WKWebView, Selector, CGRect, WKWebViewConfiguration) -> WKWebView).self)
            return original(webView, sel, frame, config)
        }

        method_setImplementation(method, imp_implementationWithBlock(block))
    }

    private init() {}
}

// MARK: - Message Handler (receives JS messages)

private class NooberWebViewMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }

        Task { @MainActor in
            switch message.name {
            case "nooberNetwork":
                handleNetworkMessage(body)
            case "nooberConsole":
                handleConsoleMessage(body)
            default:
                break
            }
        }
    }

    @MainActor
    private func handleNetworkMessage(_ body: [String: Any]) {
        let url = body["url"] as? String ?? ""
        let method = body["method"] as? String ?? "GET"
        let status = body["status"] as? Int ?? 0
        let duration = body["duration"] as? Int ?? 0
        let type = body["type"] as? String ?? "fetch"
        let responseBody = body["responseBody"] as? String
        let responseHeaders = body["headers"] as? [String: String] ?? [:]
        let requestHeaders = body["requestHeaders"] as? [String: String] ?? [:]
        let requestBody = body["requestBody"] as? String
        let error = body["error"] as? String
        let isMocked = body["mocked"] as? Bool ?? false

        // Add to NetworkActivityStore as a proper network entry
        let model = NetworkRequestModel(
            webViewURL: url,
            method: method,
            statusCode: status > 0 ? status : nil,
            duration: TimeInterval(duration) / 1000.0,
            requestHeaders: requestHeaders,
            requestBody: requestBody,
            responseBody: responseBody,
            responseHeaders: responseHeaders,
            errorDescription: error,
            type: type,
            screenName: ScreenTracker.shared.currentScreen,
            isMocked: isMocked
        )
        NetworkActivityStore.shared.addRequest(model)

        // Also log for the Logs tab
        let statusText = status > 0 ? "\(status)" : (error ?? "failed")
        let message = "[\(type.uppercased())] \(method) \(statusText) \(duration)ms \(url)"

        Noober.shared.log(
            message,
            level: status >= 400 || status == 0 ? .error : .info,
            category: .init("WebView")
        )
    }

    @MainActor
    private func handleConsoleMessage(_ body: [String: Any]) {
        let level = body["level"] as? String ?? "log"
        let message = body["message"] as? String ?? ""

        let logLevel: LogLevel
        switch level {
        case "error": logLevel = .error
        case "warn": logLevel = .warning
        case "debug": logLevel = .debug
        default: logLevel = .info
        }

        Noober.shared.log(
            message,
            level: logLevel,
            category: .init("WebView.console")
        )
    }
}
