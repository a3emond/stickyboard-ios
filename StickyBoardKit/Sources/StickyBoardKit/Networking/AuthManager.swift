import Foundation

@available(iOS 15.0, macOS 12.0, *)
public actor AuthManager {
    private var accessToken: String?
    private var refreshToken: String?

    private let store: TokenStore
    private let config: APIConfig
    private weak var apiClient: APIClient?

    // MARK: - Init
    public init(store: TokenStore, config: APIConfig) {
        self.store = store
        self.config = config

        let pair = store.load()
        accessToken = pair.access
        refreshToken = pair.refresh
    }

    // MARK: - Binding
    internal func bind(client: APIClient) {
        self.apiClient = client
    }

    // MARK: - Accessors
    public func currentAccessToken() -> String? { accessToken }

    public func updateTokens(access: String?, refresh: String?) {
        accessToken = access
        refreshToken = refresh
        store.save(access: access, refresh: refresh)
    }

    public func clear() {
        accessToken = nil
        refreshToken = nil
        store.clear()
    }

    // MARK: - Refresh logic
    internal func refreshIfPossible() async throws {
        guard let refreshToken else { return }
        guard let apiClient else { return }

        struct RefreshReq: Encodable { let refreshToken: String }
        struct RefreshRes: Decodable { let accessToken: String; let refreshToken: String }

        let ep = Endpoint(.POST, config.refreshPath)
            .withBody(RefreshReq(refreshToken: refreshToken))
            .auth(false)

        do {
            let res: RefreshRes = try await apiClient.request(ep)
            updateTokens(access: res.accessToken, refresh: res.refreshToken)
        } catch {
            print("Refresh failed:", error)
            clear() // prevents infinite retry
            throw error
        }
    }
}
