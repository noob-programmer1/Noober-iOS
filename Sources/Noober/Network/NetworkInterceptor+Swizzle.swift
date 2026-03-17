import Foundation

extension NetworkInterceptor {

    static func swizzleSessionConfigurations() {
        swizzle(
            original: #selector(getter: URLSessionConfiguration.default),
            swizzled: #selector(URLSessionConfiguration.noober_defaultConfiguration)
        )
        swizzle(
            original: #selector(getter: URLSessionConfiguration.ephemeral),
            swizzled: #selector(URLSessionConfiguration.noober_ephemeralConfiguration)
        )
    }

    private static func swizzle(original: Selector, swizzled: Selector) {
        guard
            let originalMethod = class_getClassMethod(URLSessionConfiguration.self, original),
            let swizzledMethod = class_getClassMethod(URLSessionConfiguration.self, swizzled)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension URLSessionConfiguration {

    @objc dynamic class func noober_defaultConfiguration() -> URLSessionConfiguration {
        let config = noober_defaultConfiguration() // calls original after swizzle
        config.injectNoober()
        return config
    }

    @objc dynamic class func noober_ephemeralConfiguration() -> URLSessionConfiguration {
        let config = noober_ephemeralConfiguration() // calls original after swizzle
        config.injectNoober()
        return config
    }

    private func injectNoober() {
        var protocols = protocolClasses ?? []
        if !protocols.contains(where: { $0 == NetworkInterceptor.self }) {
            protocols.insert(NetworkInterceptor.self, at: 0)
        }
        protocolClasses = protocols
    }
}
