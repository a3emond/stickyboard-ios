import SwiftUI
import StickyBoardKit

struct RootView: View {
    @EnvironmentObject var app: AppState
    @State private var showRegister = false

    var body: some View {
        Group {
            if app.isAuthenticated {
                HomeView() // contains the main app stack
            } else {
                if showRegister {
                    RegisterView(onSwitchToLogin: { showRegister = false })
                } else {
                    LoginView(onSwitchToRegister: { showRegister = true })
                }
            }
        }
        .task {
            await app.bootstrap()
        }
        .alert("Error", isPresented: .constant(app.alertMessage != nil)) {
            Button("OK") { app.alertMessage = nil }
        } message: {
            Text(app.alertMessage ?? "")
        }
    }
}

#Preview {
    
    RootView()
        .environmentObject(AppState.shared)
}
