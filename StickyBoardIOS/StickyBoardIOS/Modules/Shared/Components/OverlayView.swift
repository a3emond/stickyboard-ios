//
//  OverlayView.swift
//  StickyBoardIOS
//
//  Created by alexandre emond on 2025-11-02.
//


import SwiftUI

struct OverlayView: View {
    let isVisible: Bool
    let message: String?
    let showSpinner: Bool

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    if showSpinner {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                    }

                    if let msg = message, !msg.isEmpty {
                        Text(msg)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)
            }
            .transition(.opacity.animation(.easeInOut))
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        OverlayView(isVisible: true, message: "Loading...", showSpinner: true)
    }
}