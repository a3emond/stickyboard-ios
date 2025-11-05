import Foundation

// MARK: - Error Code
public enum ErrorCode: Int, Codable, Sendable {
    case SERVER_ERROR
    case AUTH_INVALID
    case AUTH_EXPIRED
    case NOT_FOUND
    case FORBIDDEN
    case VALIDATION_ERROR
}

// MARK: - Users & Auth
public enum UserRole: Int, Codable {
    case user       = 0
    case admin      = 1
    case moderator  = 2
}

// MARK: - Organizations
public enum OrgRole: Int, Codable {
    case owner      = 0
    case admin      = 1
    case moderator  = 2
    case member     = 3
    case guest      = 4
}

// MARK: - Boards & Permissions
public enum BoardRole: Int, Codable {
    case owner      = 0
    case editor     = 1
    case commenter  = 2
    case viewer     = 3
}

public enum BoardVisibility: Int, Codable {
    case private_   = 0
    case shared     = 1
    case public_    = 2
}

// MARK: - Tabs
public enum TabScope: Int, Codable {
    case board      = 0
    case section    = 1
}

public enum TabType: Int, Codable, CaseIterable {
    case board      = 0
    case calendar   = 1
    case timeline   = 2
    case kanban     = 3
    case whiteboard = 4
    case chat       = 5
    case metrics    = 6
    case custom     = 7
}

// MARK: - Cards
public enum CardType: Int, Codable {
    case note       = 0
    case task       = 1
    case event_     = 2
    case drawing    = 3
}

public enum CardStatus: Int, Codable {
    case open         = 0
    case in_progress  = 1
    case blocked      = 2
    case done         = 3
    case archived     = 4
}

// MARK: - Messaging & Social
public enum MessageType: Int, Codable {
    case invite       = 0
    case system       = 1
    case direct       = 2
    case org_invite   = 3
}

public enum MessageStatus: Int, Codable {
    case unread       = 0
    case read         = 1
    case archived     = 2
}

public enum RelationStatus: Int, Codable {
    case active_      = 0
    case blocked      = 1
    case inactive     = 2
}

// MARK: - Universal tolerant Int enum decoding
extension Decodable where Self: RawRepresentable, RawValue == Int {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as raw int
        if let intVal = try? container.decode(Int.self),
           let value = Self(rawValue: intVal) {
            self = value
            return
        }

        // Try decoding numeric string (e.g. "0")
        if let strVal = try? container.decode(String.self),
           let intVal = Int(strVal),
           let value = Self(rawValue: intVal) {
            self = value
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot decode \(Self.self) from given value"
        )
    }
}
