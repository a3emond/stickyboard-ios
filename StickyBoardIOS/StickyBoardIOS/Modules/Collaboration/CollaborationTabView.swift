import SwiftUI

struct CollaborationTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Collaboration")
                    .font(.largeTitle).bold()
                Text("Organizations, friends, shared boards.")
            }
            .navigationTitle("Collaboration")
        }
    }
}
