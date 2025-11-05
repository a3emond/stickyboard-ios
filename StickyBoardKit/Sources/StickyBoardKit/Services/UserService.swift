import Foundation
@available(iOS 15.0, macOS 12.0, *)
public final class UserService {
    private let api: APIClient

    public init(api: APIClient) {
        self.api = api
    }

    // MARK: - Update Profile

    public func updateSelf(_ dto: UserUpdateDto) async throws {
        struct Empty: Decodable {}
        let ep = Endpoint(.PUT, "Users/me").withBody(dto)
        let _: Empty = try await api.request(ep)
    }

    // MARK: - Change Password

    public func changePassword(oldPassword: String, newPassword: String) async throws {
        struct Empty: Decodable {}
        let dto = ChangePasswordDto(oldPassword: oldPassword, newPassword: newPassword)
        let ep = Endpoint(.PUT, "Users/me/password").withBody(dto)
        let _: Empty = try await api.request(ep)
    }
}
