import Foundation

@MainActor
final class CustomActionStore: ObservableObject {

    static let shared = CustomActionStore()

    @Published private(set) var actions: [RegisteredAction] = []

    var isEmpty: Bool { actions.isEmpty }

    /// Grouped actions, preserving registration order within each group.
    var groupedActions: [(group: String, actions: [RegisteredAction])] {
        var order: [String] = []
        var map: [String: [RegisteredAction]] = [:]
        for action in actions {
            if map[action.group] == nil {
                order.append(action.group)
            }
            map[action.group, default: []].append(action)
        }
        return order.map { (group: $0, actions: map[$0]!) }
    }

    // MARK: - Registration

    func register(_ customActions: [CustomAction]) {
        actions = customActions.map { RegisteredAction(from: $0) }
    }

    func clearAll() {
        actions.removeAll()
    }

    private init() {}
}
