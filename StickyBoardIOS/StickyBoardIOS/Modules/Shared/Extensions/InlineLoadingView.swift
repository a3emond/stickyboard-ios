import SwiftUI

struct InlineLoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(0.9)
            .tint(.accentColor)
            .padding(8)
    }
}

#Preview {
    InlineLoadingView()
}
