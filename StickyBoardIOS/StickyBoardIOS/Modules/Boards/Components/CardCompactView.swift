//
//  CardCompactView.swift
//  StickyBoardIOS
//

import SwiftUI
import PencilKit
import StickyBoardKit

struct CardCompactView: View {
    @Binding var card: LocalCard
    var onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {

                // Sticky look
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)

                VStack(alignment: .leading, spacing: 6) {

                    // Title
                    Text(card.title ?? "Untitled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // Small text preview if present
                    if let text = extractTextPreview() {
                        Text(text)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }

                    // Ink thumbnail
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .cornerRadius(6)
                    }

                    Spacer(minLength: 2)
                }
                .padding(10)
            }
        }
        .buttonStyle(.plain)
        .onAppear { loadThumbnail() }
    }

    private func extractTextPreview() -> String? {
        guard let c = card.content,
              case let .object(dict) = c,
              case let .string(text)? = dict["text"] else { return nil }
        return text
    }

    private func loadThumbnail() {
        guard thumbnail == nil,
              let inkObj = card.inkData,
              case let .object(dict) = inkObj,
              case let .string(base64)? = dict["ink"],
              let data = Data(base64Encoded: base64),
              let drawing = try? PKDrawing(data: data) else {
            return
        }

        let image = drawing.image(from: drawing.bounds, scale: 1)
        thumbnail = image
    }
}
