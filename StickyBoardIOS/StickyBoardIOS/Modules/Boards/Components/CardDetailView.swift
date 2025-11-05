//
//  CardDetailView.swift
//  StickyBoardIOS
//
//  Created by Alexandre Émond on 2025-11-04.
//  Updated minimal, safe: post-it layout + ink + fields
//

import SwiftUI
import PencilKit
import StickyBoardKit

struct CardDetailView: View {
    @Binding var card: LocalCard
    @EnvironmentObject var app: AppState

    var onClose: () -> Void
    var onSave: (CardUpdateDto) -> Void

    // Text + metadata
    @State private var text: String = ""
    @State private var assigneeName: String?
    @State private var dueDate: Date?
    @State private var tags: [String] = []

    // PencilKit
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker: PKToolPicker?

    // UI state
    @State private var showAssigneePicker = false
    @State private var showTagInput = false
    @State private var newTag = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }

                TextField("Title", text: $text)
                    .font(.headline)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .focused($isTitleFocused)

                Spacer()

                Button("Save") { save() }
                    .font(.headline)
            }
            .padding()
            .background(.thinMaterial)

            Divider()

            // MARK: Body
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Assignee
                    HStack {
                        Text("Assignee")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            showAssigneePicker = true
                        } label: {
                            Text(assigneeName ?? "None")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    Divider()

                    // Due date
                    HStack {
                        Text("Due date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                    }

                    Divider()

                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 6) {
                                        Text(tag)
                                            .font(.caption.weight(.semibold))
                                        Button {
                                            tags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.12))
                                    .cornerRadius(10)
                                }

                                Button {
                                    showTagInput = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add tag")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Sticky note (text + ink overlay)
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.yellow.opacity(0.32))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.yellow.opacity(0.55), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 4)

                        VStack(alignment: .leading, spacing: 12) {
                            // Rich note text (simple for now; can upgrade to AttributedText later)
                            TextEditor(text: $text)
                                .font(.body)
                                .frame(minHeight: 120)
                                .background(Color.clear)

                            // Ink layer
                            CanvasRepresentable(canvasView: $canvasView)
                                .frame(height: 260)
                                .background(Color.clear)
                                .onAppear { setupPencilKit() }
                        }
                        .padding(14)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                }
                .padding()
            }

            Divider()

            // MARK: Pencil tools (simple, reliable)
            toolBar
        }
        .task {
            // Initialize from current card
            text = card.title ?? ""
            dueDate = card.dueDate
            tags = card.tags
            // Keep current assignee label if available; otherwise show short id
            if let id = card.assigneeId {
                assigneeName = shortUserLabel(for: id) // todo: fetch real name
            }
            // Load back ink if present
            if let inkObj = card.inkData,
               case let .object(dict) = inkObj,
               case let .string(base64Ink)? = dict["ink"],
               let data = Data(base64Encoded: base64Ink),
               let drawing = try? PKDrawing(data: data)
            {
                canvasView.drawing = drawing
            }
        }
        .alert("Add Tag", isPresented: $showTagInput) {
            TextField("Tag", text: $newTag)
            Button("Add") {
                let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { tags.append(t) }
                newTag = ""
            }
            Button("Cancel", role: .cancel) { newTag = "" }
        }
        .sheet(isPresented: $showAssigneePicker) {
            AssigneePickerSheet(
                current: card.assigneeId,
                onSelect: { userId, display in
                    card.assigneeId = userId
                    assigneeName = display ?? shortUserLabel(for: userId)
                    showAssigneePicker = false
                },
                onClear: {
                    card.assigneeId = nil
                    assigneeName = nil
                    showAssigneePicker = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Toolbar
    private var toolBar: some View {
        HStack(spacing: 16) {
            Button("Pen") {
                canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
            }
            Button("Marker") {
                canvasView.tool = PKInkingTool(.marker, color: .black, width: 10)
            }
            Button("Pencil") {
                canvasView.tool = PKInkingTool(.pencil, color: .black, width: 4)
            }
            Button("Eraser") {
                canvasView.tool = PKEraserTool(.vector)
            }
            Spacer()
            Button("Clear Ink") {
                canvasView.drawing = PKDrawing()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Save
    private func save() {
        // 1. Encode PKDrawing → base64 → JSONValue
        let drawingData = canvasView.drawing.dataRepresentation()
        let base64 = drawingData.base64EncodedString()
        let inkJson: JSONValue? = base64.isEmpty
            ? nil
            : .object(["ink": .string(base64)])

        // 2. Convert text editor content to JSONValue
        let contentJson: JSONValue = .object([
            "text": .string(text)
        ])

        // 3. Mirror UI values into local binding before sending
        card.title = text
        card.content = contentJson
        card.tags = tags
        card.assigneeId = card.assigneeId
        card.dueDate = dueDate

        // 4. Build update DTO
        let dto = CardUpdateDto(
            title: text,
            content: contentJson,
            inkData: inkJson,
            tags: tags.isEmpty ? nil : tags,
            status: card.status,
            priority: card.priority,
            assigneeId: card.assigneeId,
            dueDate: dueDate,
            startTime: card.startTime,
            endTime: card.endTime,
            sectionId: card.sectionId,
            tabId: card.tabId
        )

        onSave(dto)
        onClose()
    }

    // MARK: - PencilKit
    private func setupPencilKit() {
        guard toolPicker == nil else { return }
        let picker = PKToolPicker()
        picker.setVisible(true, forFirstResponder: canvasView)
        picker.addObserver(canvasView)
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.becomeFirstResponder()
        toolPicker = picker
    }

    // MARK: - Utilities
    private func shortUserLabel(for id: UUID) -> String {
        let s = id.uuidString
        return String(s.prefix(6))
    }
}

// MARK: - PencilKit Wrapper
private struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - Assignee Picker (simple, non-breaking)
private struct AssigneePickerSheet: View {
    var current: UUID?
    var onSelect: (UUID, String?) -> Void
    var onClear: () -> Void

    // Minimal list: current user and "clear". Extend later with real people.
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationView {
            List {
                if let me = app.currentUser {
                    Button {
                        onSelect(me.id, me.displayName)
                    } label: {
                        HStack {
                            Text(me.displayName)
                            Spacer()
                            Text("Me").foregroundColor(.secondary)
                        }
                    }
                }

                Button(role: .destructive) { onClear() } label: {
                    Text("Clear assignee")
                }
            }
            .navigationTitle("Select Assignee")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onClear() }
                }
            }
        }
    }
}
