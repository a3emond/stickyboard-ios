import Foundation

// MARK: - Users & Auth
public struct UserDto: Codable {
    public let id: UUID
    public let email: String
    public let displayName: String
    public let avatarUrl: String?
    public let role: UserRole

    public init(id: UUID, email: String, displayName: String, avatarUrl: String?, role: UserRole) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.role = role
    }
}

public struct UserSelfDto: Codable {
    public let id: UUID
    public let email: String
    public let displayName: String
    public let avatarUrl: String?
    public let prefs: JSONValue?
    public let createdAt: Date
}

public struct UserUpdateDto: Codable {
    public let displayName: String?
    public let avatarUrl: String?
    public let prefs: JSONValue?

    public init(displayName: String? = nil, avatarUrl: String? = nil, prefs: JSONValue? = nil) {
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.prefs = prefs
    }
}

public struct ChangePasswordDto: Codable {
    public let oldPassword: String
    public let newPassword: String

    public init(oldPassword: String, newPassword: String) {
        self.oldPassword = oldPassword
        self.newPassword = newPassword
    }
}

public struct AuthLoginRequest: Codable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct AuthLoginResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserSelfDto
}

public struct AuthRefreshRequest: Codable {
    public let refreshToken: String
    public init(refreshToken: String) { self.refreshToken = refreshToken }
}

public struct AuthRefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
}

public struct RegisterRequestDto: Codable {
    public let email: String
    public let password: String
    public let displayName: String
    public let inviteToken: String?

    public init(email: String, password: String, displayName: String, inviteToken: String? = nil) {
        self.email = email
        self.password = password
        self.displayName = displayName
        self.inviteToken = inviteToken
    }
}

public struct RegisterResponseDto: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserSelfDto
}

// MARK: - Organizations
public struct OrganizationDto: Codable {
    public let id: UUID
    public let name: String
    public let ownerId: UUID
}

public struct OrganizationCreateDto: Codable {
    public let name: String
    public init(name: String) { self.name = name }
}

public struct OrganizationUpdateDto: Codable {
    public let name: String
    public init(name: String) { self.name = name }
}

public struct OrganizationMemberDto: Codable {
    public let user: UserDto
    public let role: OrgRole
}

// MARK: - Board Folders
public struct BoardFolderDto: Codable {
    public let id: UUID
    public let name: String
    public let orgId: UUID?
    public let userId: UUID?
    public let icon: String?
    public let color: String?
    public let meta: JSONValue?
}

public struct BoardFolderCreateDto: Codable {
    public let name: String
    public let orgId: UUID?
    public let icon: String?
    public let color: String?
    public let meta: JSONValue?

    public init(name: String, orgId: UUID? = nil, icon: String? = nil, color: String? = nil, meta: JSONValue? = nil) {
        self.name = name
        self.orgId = orgId
        self.icon = icon
        self.color = color
        self.meta = meta
    }
}

public struct BoardFolderUpdateDto: Codable {
    public let name: String?
    public let icon: String?
    public let color: String?
    public let meta: JSONValue?

    public init(name: String? = nil, icon: String? = nil, color: String? = nil, meta: JSONValue? = nil) {
        self.name = name
        self.icon = icon
        self.color = color
        self.meta = meta
    }
}

// MARK: - Boards
public struct BoardDto: Codable {
    public let id: UUID
    public let title: String
    public let visibility: BoardVisibility
    public let ownerId: UUID
    public let orgId: UUID?
    public let folderId: UUID?
    public let theme: JSONValue?
    public let meta: JSONValue?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct BoardCreateDto: Codable {
    public let title: String
    public let visibility: BoardVisibility
    public let orgId: UUID?
    public let folderId: UUID?
    public let theme: JSONValue?
    public let meta: JSONValue?

    public init(
        title: String,
        visibility: BoardVisibility,
        orgId: UUID? = nil,
        folderId: UUID? = nil,
        theme: JSONValue? = nil,
        meta: JSONValue? = nil
    ) {
        self.title = title
        self.visibility = visibility
        self.orgId = orgId
        self.folderId = folderId
        self.theme = theme
        self.meta = meta
    }
    enum CodingKeys: String, CodingKey {
            case title, visibility, orgId, folderId, theme, meta
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(visibility.rawValue, forKey: .visibility)
            try container.encodeIfPresent(orgId, forKey: .orgId)
            try container.encodeIfPresent(folderId, forKey: .folderId)
            try container.encodeIfPresent(theme, forKey: .theme)
            try container.encodeIfPresent(meta, forKey: .meta)
        }
}

public struct BoardUpdateDto: Codable {
    public let title: String?
    public let visibility: BoardVisibility?
    public let folderId: UUID?
    public let theme: JSONValue?
    public let meta: JSONValue?

    public init(
        title: String? = nil,
        visibility: BoardVisibility? = nil,
        folderId: UUID? = nil,
        theme: JSONValue? = nil,
        meta: JSONValue? = nil
    ) {
        self.title = title
        self.visibility = visibility
        self.folderId = folderId
        self.theme = theme
        self.meta = meta
    }
}

public struct RenameBoardDto: Codable {
    public let title: String
    public init(title: String) { self.title = title }
}

public struct MoveBoardFolderDto: Codable {
    public let folderId: UUID?
    public init(folderId: UUID?) { self.folderId = folderId }
}

public struct MoveBoardOrgDto: Codable {
    public let orgId: UUID?
    public init(orgId: UUID?) { self.orgId = orgId }
}

public struct PermissionDto: Codable {
    public let userId: UUID
    public let boardId: UUID
    public let role: BoardRole
    public let grantedAt: Date
}

public struct GrantPermissionDto: Codable {
    public let userId: UUID
    public let role: BoardRole
    public init(userId: UUID, role: BoardRole) {
        self.userId = userId
        self.role = role
    }
}

public struct UpdatePermissionDto: Codable {
    public let role: BoardRole
    public init(role: BoardRole) { self.role = role }
}

// MARK: - Tabs
public struct TabDto: Codable {
    public let id: UUID
    public let boardId: UUID
    public let title: String
    public let tabType: TabType
    public let position: Int
    public let layout: JSONValue?
    
    public init(
            id: UUID,
            boardId: UUID,
            title: String,
            tabType: TabType,
            position: Int,
            layout: JSONValue? = nil
        ) {
            self.id = id
            self.boardId = boardId
            self.title = title
            self.tabType = tabType
            self.position = position
            self.layout = layout
        }
}

public struct TabCreateDto: Codable {
    public let boardId: UUID
    public let title: String
    public let tabType: TabType
    public let position: Int
    public let layout: JSONValue?

    public init(boardId: UUID, title: String, tabType: TabType, position: Int, layout: JSONValue? = nil) {
        self.boardId = boardId
        self.title = title
        self.tabType = tabType
        self.position = position
        self.layout = layout
    }
}

public struct TabUpdateDto: Codable {
    public let title: String?
    public let tabType: TabType?
    public let position: Int
    public let layout: JSONValue?

    public init(title: String? = nil, tabType: TabType? = nil, position: Int, layout: JSONValue? = nil) {
        self.title = title
        self.tabType = tabType
        self.position = position
        self.layout = layout
    }
}

public struct TabMoveDto: Codable {
    public let newPosition: Int
    public init(newPosition: Int) { self.newPosition = newPosition }
}

// MARK: - Sections
public struct SectionDto: Codable {
    public let id: UUID
    public let tabId: UUID
    public let parentSectionId: UUID?
    public let title: String
    public let position: Int
    public let layout: JSONValue?

    // MARK: - Public Initializer
    public init(
        id: UUID,
        tabId: UUID,
        parentSectionId: UUID? = nil,
        title: String,
        position: Int,
        layout: JSONValue? = nil
    ) {
        self.id = id
        self.tabId = tabId
        self.parentSectionId = parentSectionId
        self.title = title
        self.position = position
        self.layout = layout
    }
}

public struct SectionCreateDto: Codable {
    public let tabId: UUID
    public let parentSectionId: UUID?
    public let title: String
    public let position: Int
    public let layout: JSONValue?

    public init(tabId: UUID, parentSectionId: UUID? = nil, title: String, position: Int, layout: JSONValue? = nil) {
        self.tabId = tabId
        self.parentSectionId = parentSectionId
        self.title = title
        self.position = position
        self.layout = layout
    }
}

public struct SectionUpdateDto: Codable {
    public let title: String?
    public let position: Int
    public let parentSectionId: UUID?
    public let layout: JSONValue?

    public init(title: String? = nil, position: Int, parentSectionId: UUID? = nil, layout: JSONValue? = nil) {
        self.title = title
        self.position = position
        self.parentSectionId = parentSectionId
        self.layout = layout
    }
}

public struct SectionMoveDto: Codable {
    public let newPosition: Int
    public let parentSectionId: UUID?

    public init(newPosition: Int, parentSectionId: UUID? = nil) {
        self.newPosition = newPosition
        self.parentSectionId = parentSectionId
    }
}

// MARK: - Cards
public struct CardDto: Codable {
    public let id: UUID
    public let boardId: UUID
    public let tabId: UUID
    public let sectionId: UUID?
    public let type: CardType
    public let title: String?
    public let content: JSONValue?
    public let inkData: JSONValue?
    public let tags: [String]
    public let status: CardStatus
    public let priority: Int
    public let assigneeId: UUID?
    public let dueDate: Date?
    public let startTime: Date?
    public let endTime: Date?
    public let updatedAt: Date

    public init(
        id: UUID,
        boardId: UUID,
        tabId: UUID,
        sectionId: UUID? = nil,
        type: CardType,
        title: String? = nil,
        content: JSONValue? = nil,
        inkData: JSONValue? = nil,
        tags: [String] = [],
        status: CardStatus,
        priority: Int,
        assigneeId: UUID? = nil,
        dueDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        updatedAt: Date
    ) {
        self.id = id
        self.boardId = boardId
        self.tabId = tabId
        self.sectionId = sectionId
        self.type = type
        self.title = title
        self.content = content
        self.inkData = inkData
        self.tags = tags
        self.status = status
        self.priority = priority
        self.assigneeId = assigneeId
        self.dueDate = dueDate
        self.startTime = startTime
        self.endTime = endTime
        self.updatedAt = updatedAt
    }
}

public struct CardCreateDto: Codable {
    public let boardId: UUID
    public let tabId: UUID
    public let sectionId: UUID?
    public let type: CardType
    public let title: String?
    public let content: JSONValue?
    public let inkData: JSONValue?
    public let tags: [String]?
    public let priority: Int
    public let assigneeId: UUID?
    public let dueDate: Date?

    public init(
        boardId: UUID,
        tabId: UUID,
        sectionId: UUID? = nil,
        type: CardType,
        title: String? = nil,
        content: JSONValue? = nil,
        inkData: JSONValue? = nil,
        tags: [String]? = nil,
        priority: Int,
        assigneeId: UUID? = nil,
        dueDate: Date? = nil
    ) {
        self.boardId = boardId
        self.tabId = tabId
        self.sectionId = sectionId
        self.type = type
        self.title = title
        self.content = content
        self.inkData = inkData
        self.tags = tags
        self.priority = priority
        self.assigneeId = assigneeId
        self.dueDate = dueDate
    }
}

public struct CardUpdateDto: Codable {
    public let title: String?
    public let content: JSONValue?
    public let inkData: JSONValue?
    public let tags: [String]?
    public let status: CardStatus?
    public let priority: Int
    public let assigneeId: UUID?
    public let dueDate: Date?
    public let startTime: Date?
    public let endTime: Date?
    public let sectionId: UUID?
    public let tabId: UUID?

    public init(
        title: String? = nil,
        content: JSONValue? = nil,
        inkData: JSONValue? = nil,
        tags: [String]? = nil,
        status: CardStatus? = nil,
        priority: Int,
        assigneeId: UUID? = nil,
        dueDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        sectionId: UUID? = nil,
        tabId: UUID? = nil
    ) {
        self.title = title
        self.content = content
        self.inkData = inkData
        self.tags = tags
        self.status = status
        self.priority = priority
        self.assigneeId = assigneeId
        self.dueDate = dueDate
        self.startTime = startTime
        self.endTime = endTime
        self.sectionId = sectionId
        self.tabId = tabId
    }
}
// MARK: - Card Comments
public struct CardCommentDto: Codable {
    public let id: UUID
    public let cardId: UUID
    public let user: UserDto
    public let content: String
    public let createdAt: Date
}

public struct CardCommentCreateDto: Codable {
    public let content: String
    public init(content: String) { self.content = content }
}

// MARK: - Board Chat
public struct BoardMessageDto: Codable {
    public let id: UUID
    public let boardId: UUID
    public let user: UserDto
    public let content: String
    public let createdAt: Date
}

public struct BoardMessageCreateDto: Codable {
    public let content: String
    public init(content: String) { self.content = content }
}

// MARK: - User Relations
public struct UserRelationDto: Codable {
    public let userId: UUID
    public let friendId: UUID
    public let status: RelationStatus
    public let createdAt: Date
    public let updatedAt: Date
}

public struct UserRelationCreateDto: Codable {
    public let friendId: UUID
    public init(friendId: UUID) { self.friendId = friendId }
}

public struct UserRelationUpdateDto: Codable {
    public let status: RelationStatus
    public init(status: RelationStatus) { self.status = status }
}

// MARK: - Direct Messages
public struct MessageDto: Codable {
    public let id: UUID
    public let senderId: UUID?
    public let receiverId: UUID
    public let subject: String?
    public let body: String
    public let type: MessageType
    public let relatedBoardId: UUID?
    public let relatedOrgId: UUID?
    public let status: MessageStatus
    public let createdAt: Date
}

public struct SendMessageDto: Codable {
    public let receiverId: UUID
    public let subject: String?
    public let body: String
    public let type: MessageType
    public let relatedBoardId: UUID?
    public let relatedOrgId: UUID?

    public init(receiverId: UUID, subject: String? = nil, body: String, type: MessageType,
                relatedBoardId: UUID? = nil, relatedOrgId: UUID? = nil) {
        self.receiverId = receiverId
        self.subject = subject
        self.body = body
        self.type = type
        self.relatedBoardId = relatedBoardId
        self.relatedOrgId = relatedOrgId
    }
}

public struct UpdateMessageStatusDto: Codable {
    public let status: MessageStatus
    public init(status: MessageStatus) { self.status = status }
}

// MARK: - Invites
public struct InviteDto: Codable {
    public let id: UUID
    public let email: String
    public let boardId: UUID?
    public let orgId: UUID?
    public let boardRole: BoardRole?
    public let orgRole: OrgRole?
    public let accepted: Bool
    public let expiresAt: Date
}

public struct InviteCreateDto: Codable {
    public let email: String
    public let boardId: UUID?
    public let orgId: UUID?
    public let boardRole: BoardRole?
    public let orgRole: OrgRole?
    public let expiresInDays: Int?

    public init(email: String, boardId: UUID? = nil, orgId: UUID? = nil,
                boardRole: BoardRole? = nil, orgRole: OrgRole? = nil, expiresInDays: Int? = nil) {
        self.email = email
        self.boardId = boardId
        self.orgId = orgId
        self.boardRole = boardRole
        self.orgRole = orgRole
        self.expiresInDays = expiresInDays
    }
}

public struct InviteCreateResponseDto: Codable {
    public let id: UUID
    public let token: String
    public let expiresAt: Date
}

public struct InviteRedeemRequestDto: Codable {
    public let token: String
    public init(token: String) { self.token = token }
}

public struct InviteListItemDto: Codable {
    public let id: UUID
    public let email: String
    public let boardId: UUID?
    public let organizationId: UUID?
    public let boardRole: BoardRole?
    public let orgRole: OrgRole?
    public let accepted: Bool
    public let createdAt: Date
    public let expiresAt: Date
    public let senderDisplayName: String
}

public struct InvitePublicDto: Codable {
    public let email: String
    public let boardId: UUID?
    public let organizationId: UUID?
    public let boardRole: BoardRole?
    public let orgRole: OrgRole?
    public let accepted: Bool
    public let expiresAt: Date
    public let senderDisplayName: String
}
