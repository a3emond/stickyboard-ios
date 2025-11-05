//
//  CardDetailView.swift
//  StickyBoardIOS
//
//  Created by Alexandre Émond on 2025-11-04.
//

import SwiftUI
import PencilKit
import StickyBoardKit

struct CardDetailView: View {
    @Binding var card: LocalCard
    @EnvironmentObject var app: AppState
    var onClose: () -> Void
    var onSave: (CardUpdateDto) -> Void

    @State private var text: String = ""
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker: PKToolPicker?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(card.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button("Save") {
                    saveChanges()
                }
                .font(.headline)
            }
            .padding()
            .background(.thinMaterial)

            Divider()

            // MARK: Body
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Text Editor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        TextEditor(text: $text)
                            .focused($isFocused)
                            .padding(10)
                            .frame(minHeight: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                    }
                    .onAppear {
                        text = card.title ?? ""
                    }

                    // MARK: Drawing Canvas
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sketch")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        CanvasRepresentable(canvasView: $canvasView)
                            .frame(height: 280)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                            .onAppear {
                                setupPencilKit()
                            }
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - PencilKit setup
    private func setupPencilKit() {
        if toolPicker == nil {
            let picker = PKToolPicker()
            picker.addObserver(canvasView)
            picker.setVisible(true, forFirstResponder: canvasView)
            canvasView.becomeFirstResponder()
            toolPicker = picker
        }
    }

    // MARK: - Save logic
    private func saveChanges() {
        let data = canvasView.drawing.dataRepresentation()
        let inkBase64 = data.base64EncodedString()
        let inkJson = inkBase64.isEmpty ? nil : JSONValue.object(["ink": .string(inkBase64)])

        let dto = CardUpdateDto(
            title: text.isEmpty ? card.title : text,
            content: card.content,
            inkData: inkJson,
            priority: card.priority
        )

        onSave(dto)
        onClose()
    }
}

// MARK: - PencilKit Wrapper
private struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
