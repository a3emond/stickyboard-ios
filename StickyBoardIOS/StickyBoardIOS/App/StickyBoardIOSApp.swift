import SwiftUI
import StickyBoardKit

@main
struct StickyBoardIOSApp: App {
    @StateObject private var app = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
        }
    }
}
