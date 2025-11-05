import Foundation

@available(iOS 15.0, macOS 12.0, *)
public final class SectionService {
    private let api: APIClient
    private let auth: AuthManager

    public init(api: APIClient, auth: AuthManager) {
        self.api = api
        self.auth = auth
    }

    // MARK: - List Sections for Tab
    public func getForTab(tabId: UUID) async throws -> [SectionDto] {
        let ep = Endpoint(.GET, "Sections/tab/\(tabId.uuidString)").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Create Section
    @discardableResult
    public func create(_ dto: SectionCreateDto) async throws -> UUID {
        struct IdResponse: Decodable { let id: UUID }
        let ep = Endpoint(.POST, "Sections")
            .withBody(dto)
            .auth(true)
        let res: IdResponse = try await api.request(ep)
        return res.id
    }

    // MARK: - Update Section
    public func update(id: UUID, dto: SectionUpdateDto) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.PUT, "Sections/\(id.uuidString)")
            .withBody(dto)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Move Section (reparent / reorder)
    public func move(id: UUID, dto: SectionMoveDto) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.PUT, "Sections/\(id.uuidString)/move")
            .withBody(dto)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Delete Section
    public func delete(id: UUID) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.DELETE, "Sections/\(id.uuidString)").auth(true)
        _ = try await api.request(ep) as OkResponse
    }
}
