import Foundation

@available(iOS 15.0, macOS 12.0, *)
public final class AuthService {
    private let api: APIClient
    private let auth: AuthManager

    public init(api: APIClient, auth: AuthManager) {
        self.api = api
        self.auth = auth
    }

    // MARK: - Login
    @discardableResult
    public func login(email: String, password: String) async throws -> AuthLoginResponse {
        // Clear previous tokens just in case
        await auth.clear()

        let body = AuthLoginRequest(email: email, password: password)
        let ep = Endpoint(.POST, "Auth/login")
            .withBody(body)
            .auth(false)

        let res: AuthLoginResponse = try await api.request(ep)
        await auth.updateTokens(access: res.accessToken, refresh: res.refreshToken)
        return res
    }

    // MARK: - Register
    @discardableResult
    public func register(
        email: String,
        password: String,
        displayName: String,
        inviteToken: String? = nil
    ) async throws -> RegisterResponseDto {
        let body = RegisterRequestDto(
            email: email,
            password: password,
            displayName: displayName,
            inviteToken: inviteToken
        )

        let ep = Endpoint(.POST, "Auth/register")
            .withBody(body)
            .auth(false)

        let res: RegisterResponseDto = try await api.request(ep)
        await auth.updateTokens(access: res.accessToken, refresh: res.refreshToken)
        return res
    }

    // MARK: - Me
    public func me() async throws -> UserSelfDto {
        let ep = Endpoint(.GET, "Auth/me")
        return try await api.request(ep)
    }

    // MARK: - Refresh
    public func refresh() async throws {
        try await auth.refreshIfPossible()
    }

    // MARK: - Logout
    public func logout() async {
        struct LogoutOk: Decodable { let success: Bool }

        do {
            let ep = Endpoint(.POST, "Auth/logout").auth(true)
            _ = try await api.request(ep) as LogoutOk
        } catch {
            // Non-fatal: network failure or expired token
            print("Logout request failed:", error)
        }

        await auth.clear()
    }
}
