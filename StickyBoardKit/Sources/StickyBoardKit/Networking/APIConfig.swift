import Foundation

/// Global networking config
public struct APIConfig: Sendable {
    public var baseURL: URL
    public var refreshPath: String
    public var accessHeaderName: String = "Authorization"
    public var accessHeaderPrefix: String = "Bearer "

    public init(baseURL: URL, refreshPath: String) {
        self.baseURL = baseURL
        self.refreshPath = refreshPath
    }
}

