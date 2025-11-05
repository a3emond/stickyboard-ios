import Foundation

@available(iOS 15.0, macOS 12.0, *)
public final class CardService {
    private let api: APIClient
    private let auth: AuthManager

    public init(api: APIClient, auth: AuthManager) {
        self.api = api
        self.auth = auth
    }

    // MARK: - Get Card by ID
    public func get(id: UUID) async throws -> CardDto {
        let ep = Endpoint(.GET, "Cards/\(id.uuidString)").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Get Cards by Tab
    public func getByTab(tabId: UUID) async throws -> [CardDto] {
        let ep = Endpoint(.GET, "Cards/tab/\(tabId.uuidString)").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Get Cards by Section
    public func getBySection(sectionId: UUID) async throws -> [CardDto] {
        let ep = Endpoint(.GET, "Cards/section/\(sectionId.uuidString)").auth(true)
        return try await api.request(ep)
    }

    // MARK: - Create Card
    @discardableResult
    public func create(_ dto: CardCreateDto) async throws -> UUID {
        struct IdResponse: Decodable { let id: UUID }
        let ep = Endpoint(.POST, "Cards")
            .withBody(dto)
            .auth(true)
        let res: IdResponse = try await api.request(ep)
        return res.id
    }

    // MARK: - Update Card
    public func update(id: UUID, dto: CardUpdateDto) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.PUT, "Cards/\(id.uuidString)")
            .withBody(dto)
            .auth(true)
        _ = try await api.request(ep) as OkResponse
    }

    // MARK: - Delete Card
    public func delete(id: UUID) async throws {
        struct OkResponse: Decodable { let success: Bool }
        let ep = Endpoint(.DELETE, "Cards/\(id.uuidString)").auth(true)
        _ = try await api.request(ep) as OkResponse
    }
}
