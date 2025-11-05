import Foundation

/// Describes a REST call: path, method, query, body, auth requirement
///
/// This type is a lightweight value object used throughout the kit to compose
/// HTTP requests in a declarative way.
public struct Endpoint {
    public var method: HTTPMethod
    public var path: String
    public var query: [String: String?] = [:]
    public var headers: [String: String] = [:]
    public var body: Encodable? = nil
    public var requiresAuth: Bool = true

    public init(_ method: HTTPMethod, _ path: String) {
        self.method = method
        self.path = path
    }

    // Fluent helpers used by service code to modify an endpoint.
    public func withBody<T: Encodable>(_ b: T) -> Endpoint {
        var copy = self
        copy.body = b
        return copy
    }

    public func withQuery(_ key: String, _ value: String?) -> Endpoint {
        var copy = self
        copy.query[key] = value
        return copy
    }

    public func withHeader(_ name: String, _ value: String) -> Endpoint {
        var copy = self
        copy.headers[name] = value
        return copy
    }

    /// Toggle whether this endpoint requires the Authorization header.
    public func auth(_ enabled: Bool) -> Endpoint {
        var copy = self
        copy.requiresAuth = enabled
        return copy
    }
}
