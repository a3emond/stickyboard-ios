import Foundation

/// Unifies server + transport errors
public enum APIError: Error, Sendable, CustomStringConvertible {
    case server(String)
    case authInvalid(String?)
    case authExpired(String?)
    case forbidden(String?)
    case notFound(String?)
    case validation(String?, details: String?)
    case transport(underlying: Error)
    case decoding(String)
    case cancelled
    case unknown(status: Int?, body: String?)

    public var description: String {
        switch self {
        case .server(let msg): return "server(\(msg))"
        case .authInvalid(let m): return "authInvalid(\(m ?? ""))"
        case .authExpired(let m): return "authExpired(\(m ?? ""))"
        case .forbidden(let m): return "forbidden(\(m ?? ""))"
        case .notFound(let m): return "notFound(\(m ?? ""))"
        case .validation(let m, let d): return "validation(\(m ?? ""), details: \(d ?? ""))"
        case .transport(let e): return "transport(\(e.localizedDescription))"
        case .decoding(let m): return "decoding(\(m))"
        case .cancelled: return "cancelled"
        case .unknown(let s, let b): return "unknown(status: \(s ?? -1), body: \(b ?? "<nil>"))"
        }
    }
}
