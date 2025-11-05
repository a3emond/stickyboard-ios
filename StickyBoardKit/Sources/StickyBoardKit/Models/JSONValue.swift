import Foundation

/// A lightweight representation of arbitrary JSON values.
/// Used in DTOs for flexible fields like `prefs`, `meta`, `layout`, or `content`.
/// Conforms to `Codable` for seamless JSON encoding/decoding and `Sendable`
/// for concurrency safety across async boundaries.
public enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    // MARK: - Decoding
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Double.self) {
            self = .number(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([String: JSONValue].self) {
            self = .object(v)
        } else if let v = try? container.decode([JSONValue].self) {
            self = .array(v)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported JSON value"
                )
            )
        }
    }

    // MARK: - Encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let v):
            try container.encode(v)
        case .number(let v):
            try container.encode(v)
        case .string(let v):
            try container.encode(v)
        case .object(let dict):
            try container.encode(dict)
        case .array(let arr):
            try container.encode(arr)
        }
    }
}

// MARK: - Equatable Support
extension JSONValue: Equatable {
    public static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            return true
        case let (.string(a), .string(b)):
            return a == b
        case let (.number(a), .number(b)):
            return a == b
        case let (.bool(a), .bool(b)):
            return a == b
        case let (.array(a), .array(b)):
            return a == b
        case let (.object(a), .object(b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - String Representation Helper
public extension JSONValue {
    /// Converts the JSON value to a serialized JSON string.
    var asString: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}


// MARK: - Factory Helpers
public extension JSONValue {
    /// Creates a `.string` value.
    static func makeString(_ value: String) -> JSONValue { .string(value) }

    /// Creates an `.object` value from a dictionary.
    static func makeObject(_ dict: [String: JSONValue]) -> JSONValue { .object(dict) }

    /// Creates an `.array` value from an array.
    static func makeArray(_ arr: [JSONValue]) -> JSONValue { .array(arr) }

    /// Creates a `.number` value.
    static func makeNumber(_ value: Double) -> JSONValue { .number(value) }

    /// Creates a `.bool` value.
    static func makeBool(_ value: Bool) -> JSONValue { .bool(value) }
}
