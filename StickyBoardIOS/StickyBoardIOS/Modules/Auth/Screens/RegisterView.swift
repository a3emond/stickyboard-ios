import SwiftUI

struct RegisterView: View {
    @StateObject private var vm = AuthViewModel()
    var onSwitchToLogin: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Create Account")
                    .font(.title.bold())
                    .padding(.bottom, 8)

                VStack(spacing: 14) {
                    TextField("Display name", text: $vm.displayName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    TextField("Email", text: $vm.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $vm.password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    TextField("Invite token (optional)", text: $vm.inviteToken)
                        .textFieldStyle(.roundedBorder)
                }

                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Button {
                    Task { await vm.register() }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty || vm.displayName.isEmpty)
                .padding(.top, 8)

                Button("I already have an account") {
                    onSwitchToLogin()
                }
                .font(.footnote.weight(.semibold))
                .padding(.top, 8)

                Spacer(minLength: 30)
            }
            .padding(30)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
