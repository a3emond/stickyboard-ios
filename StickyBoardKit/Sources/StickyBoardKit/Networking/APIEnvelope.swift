import Foundation
@available(iOS 15.0, macOS 12.0, *)
/// Standard response wrapper used by your API
public struct ApiResponseDto<T: Decodable>: Decodable {
    public let success: Bool
    public let message: String?
    public let data: T?
}

public struct ErrorDto: Decodable, Sendable {
    public let code: ErrorCode
    public let message: String
    public let details: String?
}

@inline(__always)
internal func mapErrorDto(_ e: ErrorDto) -> APIError {
    switch e.code {
    case .SERVER_ERROR: return .server(e.message)
    case .AUTH_INVALID: return .authInvalid(e.message)
    case .AUTH_EXPIRED: return .authExpired(e.message)
    case .FORBIDDEN: return .forbidden(e.message)
    case .NOT_FOUND: return .notFound(e.message)
    case .VALIDATION_ERROR: return .validation(e.message, details: e.details)
    }
}

