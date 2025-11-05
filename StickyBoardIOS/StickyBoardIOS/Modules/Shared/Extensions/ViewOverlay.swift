import SwiftUI

extension View {
    func withOverlay(isVisible: Bool, message: String? = nil, showSpinner: Bool = true) -> some View {
        ZStack {
            self
            OverlayView(isVisible: isVisible, message: message, showSpinner: showSpinner)
        }
    }
}
