import SwiftUI
import StickyBoardKit

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()   // Global singleton instance
    // MARK: - Session
    @Published var currentUser: UserSelfDto?
    @Published var isAuthenticated: Bool = false

    // MARK: - Global UI state
    @Published var isBusy: Bool = false
    @Published var alertMessage: String?

    // MARK: - Services
    let config: APIConfig
    let tokenStore: TokenStore
    let authManager: AuthManager
    let apiClient: APIClient

    // Core API services
    let authService: AuthService
    let userService: UserService
    let boardService: BoardService
    let tabService: TabService
    let sectionService: SectionService
    let cardService: CardService

    // MARK: - Selection Context
    @Published var selectedBoardId: UUID?
    @Published var selectedTabId: UUID?
    @Published var selectedSectionId: UUID?
    
    init(
        baseURL: URL = URL(string: "https://stickyboard.aedev.pro/api")!,
        refreshPath: String = "Auth/refresh"
    ) {
        let cfg = APIConfig(baseURL: baseURL, refreshPath: refreshPath)
        config = cfg
        tokenStore = KeychainTokenStore()
        authManager = AuthManager(store: tokenStore, config: cfg)
        apiClient = APIClient(config: cfg, auth: authManager)
        
        // Services
        authService = AuthService(api: apiClient, auth: authManager)
        userService = UserService(api: apiClient)
        boardService = BoardService(api: apiClient, auth: authManager)
        tabService = TabService(api: apiClient, auth: authManager)
        sectionService = SectionService(api: apiClient, auth: authManager)
        cardService = CardService(api: apiClient, auth: authManager)
    }

    // MARK: - Session lifecycle
    func bootstrap() async {
        isBusy = true
        defer { isBusy = false }

        let tokens = tokenStore.load()
        print("BOOTSTRAP: tokens =", tokens)

        guard let refresh = tokens.refresh, !refresh.isEmpty else {
            print("BOOTSTRAP: no refresh token, skipping refresh.")
            await authManager.clear()
            currentUser = nil
            isAuthenticated = false
            return
        }

        do {
            print("BOOTSTRAP: attempting refresh()")
            try await withTimeout(seconds: 8) { [self] in
                try await authService.refresh()
            }

            print("BOOTSTRAP: refresh succeeded, fetching me()")
            let me = try await withTimeout(seconds: 5) { [self] in
                try await authService.me()
            }

            print("BOOTSTRAP: me() returned user =", me.email)
            currentUser = me
            isAuthenticated = true
        } catch {
            print("BOOTSTRAP: error =", error)
            await authManager.clear()
            currentUser = nil
            isAuthenticated = false
            alertMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    func reloadMe() async {
        isBusy = true
        defer { isBusy = false }

        do {
            let me = try await authService.me()
            currentUser = me
            isAuthenticated = true
            alertMessage = nil
        } catch {
            alertMessage = (error as? APIError)?.description ?? error.localizedDescription
            isAuthenticated = false
        }
    }

    func logout() async {
        isBusy = true
        defer { isBusy = false }

        await authService.logout()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Utility
    func withTimeout<T>(
        seconds: Double,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw APIError.transport(
                    underlying: NSError(domain: "Timeout", code: -1001)
                )
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
