import SwiftUI

struct LoginView: View {
    @StateObject private var vm = AuthViewModel()
    var onSwitchToRegister: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in")
                .font(.title.bold())
                .padding(.bottom, 4)

            VStack(spacing: 14) {
                TextField("Email", text: $vm.email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $vm.password)
                    .textContentType(.password)
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
                Task { await vm.login() }
            } label: {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty)
            .padding(.top, 6)

            Button("Create an account") {
                onSwitchToRegister()
            }
            .font(.footnote.weight(.semibold))
            .padding(.top, 8)

            Spacer()
        }
        .padding(30)
        .multilineTextAlignment(.center)
        .onSubmit {
            Task { await vm.login() }
        }
    }
}
