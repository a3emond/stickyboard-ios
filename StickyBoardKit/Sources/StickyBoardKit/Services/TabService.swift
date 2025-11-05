import Foundation

@available(iOS 15.0, macOS 12.0, *)
public final class TabService {
    private let api: APIClient
    private let auth: AuthManager

    public init(api: APIClient, auth: AuthManager) {
        self.api = api
        self.auth = auth
    }

    // MARK: - List Tabs for Board
    public func getForBoard(boardId: UUID) async throws -> [TabDto] {
        let ep = Endpoint(.GET, "Tabs/board/\(boardId.uuidString)").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Create Tab
    @discardableResult
    public func create(_ dto: TabCreateDto) async throws -> UUID {
        struct IdResponse: Decodable { let id: UUID }
        let ep = Endpoint(.POST, "Tabs")
            .withBody(dto)
            .auth(true)
        let res: IdResponse = try await api.request(ep)
        return res.id
    }

    // MARK: - Update Tab
    public func update(id: UUID, dto: TabUpdateDto) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.PUT, "Tabs/\(id.uuidString)")
            .withBody(dto)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Move Tab
    public func move(id: UUID, newPosition: Int) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let body = TabMoveDto(newPosition: newPosition)
        let ep = Endpoint(.PUT, "Tabs/\(id.uuidString)/move")
            .withBody(body)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Delete Tab
    public func delete(id: UUID) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.DELETE, "Tabs/\(id.uuidString)").auth(true)
        _ = try await api.request(ep) as OkResponse
    }
}
