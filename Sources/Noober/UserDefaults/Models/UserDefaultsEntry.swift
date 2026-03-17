import Foundation

struct UserDefaultsEntry: Identifiable, Sendable, Hashable {
    let id: String  // == key, unique in UserDefaults
    let key: String
    let displayValue: String
    let valueType: ValueType

    enum ValueType: String, Sendable, CaseIterable {
        case string = "String"
        case int = "Int"
        case double = "Double"
        case bool = "Bool"
        case data = "Data"
        case date = "Date"
        case array = "Array"
        case dictionary = "Dict"
        case unknown = "?"
    }
}
