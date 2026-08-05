import Foundation
import Testing
@testable import Noober

@Test func nooberModuleExists() async throws {
    // Placeholder - verifies the module compiles
    #expect(true)
}

// MARK: - Public rule types

@Test func mockConvertsToRule() {
    let mock = NooberMock(
        "Empty cart",
        url: "/api/v1/cart",
        method: "GET",
        statusCode: 204,
        headers: ["X-Test": "1"],
        json: #"{"items": []}"#
    )
    let rule = mock.toRule()

    #expect(rule.id == mock.id)
    #expect(rule.name == "Empty cart")
    #expect(rule.matchPattern.mode == .contains)
    #expect(rule.matchPattern.pattern == "/api/v1/cart")
    #expect(rule.httpMethod == "GET")
    #expect(rule.mockStatusCode == 204)
    #expect(rule.mockResponseHeaders == ["X-Test": "1"])
    #expect(rule.mockResponseBody == #"{"items": []}"#.data(using: .utf8))
    #expect(rule.isEnabled)
    #expect(rule.source == .code)
}

@Test func interceptConvertsToRule() {
    let intercept = NooberIntercept(
        "Payments",
        url: "api.example.com",
        match: .host,
        method: "POST",
        isEnabled: false
    )
    let rule = intercept.toRule()

    #expect(rule.id == intercept.id)
    #expect(rule.matchPattern.mode == .host)
    #expect(rule.matchPattern.pattern == "api.example.com")
    #expect(rule.httpMethod == "POST")
    #expect(!rule.isEnabled)
    #expect(rule.source == .code)
}

@Test func mockMatchesOnlyItsMethod() {
    let rule = NooberMock("Cart", url: "/api/v1/cart", method: "POST").toRule()

    var post = URLRequest(url: URL(string: "https://api.example.com/api/v1/cart")!)
    post.httpMethod = "post"
    #expect(rule.matches(post))

    var get = URLRequest(url: URL(string: "https://api.example.com/api/v1/cart")!)
    get.httpMethod = "GET"
    #expect(!rule.matches(get))
}

@Test func disabledMockNeverMatches() {
    let rule = NooberMock("Cart", url: "/api/v1/cart", isEnabled: false).toRule()
    let request = URLRequest(url: URL(string: "https://api.example.com/api/v1/cart")!)
    #expect(!rule.matches(request))
}

/// `source` is deliberately outside the rule's coding keys, so anything that
/// survives a round trip through disk comes back as a manual rule.
@Test func encodingDropsRuleSource() throws {
    let rule = NooberMock("Cart", url: "/api/v1/cart").toRule()
    let decoded = try JSONDecoder().decode(MockRule.self, from: JSONEncoder().encode(rule))

    #expect(decoded.id == rule.id)
    #expect(decoded.source == .manual)
}

// MARK: - Registration

@MainActor
@Suite(.serialized)
struct RuleRegistrationTests {

    private let mockKey = "com.noober.mockRules"

    /// The store is a singleton wired to `UserDefaults.standard`; start every test
    /// from a clean slate rather than inheriting whatever the last one left.
    init() {
        let store = RulesStore.shared
        store.clearAllMockRules()
        store.clearAllInterceptRules()
    }

    @Test func registeringTwiceDoesNotDuplicate() {
        let store = RulesStore.shared
        let mocks = [
            NooberMock("Empty cart", url: "/api/v1/cart"),
            NooberMock("Payment failure", url: "/api/v1/payments", statusCode: 500),
        ]

        Noober.shared.registerMocks(mocks)
        Noober.shared.registerMocks(mocks)

        #expect(store.mockRules.count == 2)
    }

    @Test func registeringKeepsManualRulesAndOutranksNothing() {
        let store = RulesStore.shared
        store.addMockRule(MockRule(name: "Hand-made", matchPattern: .init(mode: .contains, pattern: "/api")))

        Noober.shared.registerMocks([NooberMock("From code", url: "/api")])

        #expect(store.mockRules.count == 2)
        // Manual rules sort first, and first match wins, so the tester's rule serves.
        #expect(store.mockRules.first?.name == "Hand-made")
        #expect(RulesSnapshot.findMatchingMock(
            for: URLRequest(url: URL(string: "https://example.com/api")!)
        )?.name == "Hand-made")
    }

    @Test func registeringDropsPreviousCodeRules() {
        let store = RulesStore.shared

        Noober.shared.registerMocks([NooberMock("Old", url: "/api/old")])
        Noober.shared.registerMocks([NooberMock("New", url: "/api/new")])

        #expect(store.mockRules.map(\.name) == ["New"])
    }

    @Test func codeRulesAreNotPersisted() throws {
        let store = RulesStore.shared
        store.addMockRule(MockRule(name: "Hand-made", matchPattern: .init(mode: .contains, pattern: "/api")))
        Noober.shared.registerMocks([NooberMock("From code", url: "/api")])

        let data = try #require(UserDefaults.standard.data(forKey: mockKey))
        let persisted = try JSONDecoder().decode([MockRule].self, from: data)

        #expect(persisted.map(\.name) == ["Hand-made"])
        #expect(store.mockRules.count == 2)
    }

    @Test func addMockTakesPrecedenceOverEverything() {
        Noober.shared.registerMocks([NooberMock("Registered", url: "/api")])
        Noober.shared.addMock(NooberMock("Added now", url: "/api"))

        #expect(RulesSnapshot.findMatchingMock(
            for: URLRequest(url: URL(string: "https://example.com/api")!)
        )?.name == "Added now")
    }

    @Test func removeMockRemovesByID() {
        let store = RulesStore.shared
        let mock = NooberMock("Temporary", url: "/api")

        let id = Noober.shared.addMock(mock)
        #expect(store.mockRules.count == 1)

        Noober.shared.removeMock(id: id)
        #expect(store.mockRules.isEmpty)
    }

    @Test func interceptsRegisterAndRemoveTheSameWay() {
        let store = RulesStore.shared

        Noober.shared.registerIntercepts([
            NooberIntercept("Payments", url: "/api/v1/payments", isEnabled: false)
        ])
        #expect(store.interceptRules.count == 1)
        #expect(!(store.interceptRules.first?.isEnabled ?? true))

        let id = Noober.shared.addIntercept(NooberIntercept("Cart", url: "/api/v1/cart"))
        #expect(store.interceptRules.count == 2)

        Noober.shared.removeIntercept(id: id)
        #expect(store.interceptRules.map(\.name) == ["Payments"])
    }
}

// MARK: - Custom actions

@MainActor
@Suite(.serialized)
struct CustomActionTests {

    init() {
        CustomActionStore.shared.clearAll()
    }

    @Test func addAppendsInsteadOfReplacing() {
        Noober.shared.registerActions([.init("Clear Cache") {}])
        Noober.shared.addAction(.init("Reset Onboarding") {})
        Noober.shared.addActions([.init("Expire Session") {}, .init("Force Crash") {}])

        #expect(CustomActionStore.shared.actions.map(\.title)
            == ["Clear Cache", "Reset Onboarding", "Expire Session", "Force Crash"])
    }

    @Test func registerStillReplaces() {
        Noober.shared.addActions([.init("One") {}, .init("Two") {}])
        Noober.shared.registerActions([.init("Only") {}])

        #expect(CustomActionStore.shared.actions.map(\.title) == ["Only"])
    }

    @Test func removeAndClear() {
        Noober.shared.addActions([.init("One") {}, .init("Two") {}])

        Noober.shared.removeAction("One")
        #expect(CustomActionStore.shared.actions.map(\.title) == ["Two"])

        Noober.shared.clearActions()
        #expect(CustomActionStore.shared.isEmpty)
    }
}
