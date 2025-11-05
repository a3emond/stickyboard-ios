import SwiftUI
import StickyBoardKit

@MainActor
final class AuthViewModel: ObservableObject {
    private let app: AppState = .shared  // unified shared instance

    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var inviteToken = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Login
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await app.authService.login(email: email, password: password)
            await app.reloadMe()
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Register
    func register() async {
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            errorMessage = "Please fill all required fields."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await app.authService.register(
                email: email,
                password: password,
                displayName: displayName,
                inviteToken: inviteToken.isEmpty ? nil : inviteToken
            )
            await app.reloadMe()
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Logout
    func logout() async {
        await app.logout()
        email = ""
        password = ""
        displayName = ""
        inviteToken = ""
        errorMessage = nil
    }
}
