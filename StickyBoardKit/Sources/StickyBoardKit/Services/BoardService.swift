import Foundation

@available(iOS 15.0, macOS 12.0, *)
public final class BoardService {
    private let api: APIClient
    private let auth: AuthManager

    public init(api: APIClient, auth: AuthManager) {
        self.api = api
        self.auth = auth
    }

    // MARK: - Get My Boards
    public func getMine() async throws -> [BoardDto] {
        let ep = Endpoint(.GET, "Boards/mine").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Get Accessible Boards
    public func getAccessible() async throws -> [BoardDto] {
        let ep = Endpoint(.GET, "Boards/accessible").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Search Accessible Boards
    public func search(keyword: String) async throws -> [BoardDto] {
        let ep = Endpoint(.GET, "Boards/search")
            .withQuery("keyword", keyword.isEmpty ? nil : keyword)
            .auth(true)
        return try await api.request(ep)
    }

    // MARK: - Get Board by ID
    public func get(id: UUID) async throws -> BoardDto {
        let ep = Endpoint(.GET, "Boards/\(id.uuidString)").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Create Board
    @discardableResult
    public func create(_ dto: BoardCreateDto) async throws -> UUID {
        struct IdResponse: Decodable { let id: UUID }
        let ep = Endpoint(.POST, "Boards")
            .withBody(dto)
            .auth(true)
        let res: IdResponse = try await api.request(ep)
        return res.id
    }

    // MARK: - Update Board
    public func update(id: UUID, dto: BoardUpdateDto) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.PUT, "Boards/\(id.uuidString)")
            .withBody(dto)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Delete Board
    public func delete(id: UUID) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.DELETE, "Boards/\(id.uuidString)").auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Rename Board
    public func rename(id: UUID, title: String) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let body = RenameBoardDto(title: title)
        let ep = Endpoint(.PATCH, "Boards/\(id.uuidString)/rename")
            .withBody(body)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Move to Folder
    public func moveToFolder(id: UUID, folderId: UUID?) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let body = MoveBoardFolderDto(folderId: folderId)
        let ep = Endpoint(.PATCH, "Boards/\(id.uuidString)/folder")
            .withBody(body)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Move to Org
    public func moveToOrg(id: UUID, orgId: UUID?) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let body = MoveBoardOrgDto(orgId: orgId)
        let ep = Endpoint(.PATCH, "Boards/\(id.uuidString)/org")
            .withBody(body)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }
}
