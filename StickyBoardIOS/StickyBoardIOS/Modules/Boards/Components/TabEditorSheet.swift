import SwiftUI
import StickyBoardKit

struct TabEditorSheet: View {
    var existing: TabDto? // nil = create
    var onSave: (TabCreateDto) -> Void
    var onUpdate: ((UUID, TabUpdateDto) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var icon: String = "🧩"
    @State private var tint: Color = .accentColor
    @State private var type: TabType = .board

    private let icons = ["📋","💡","🗓","🧠","🚀","📝","🎯","🗂","⚙️","❤️","📁","📦","🪄","🧱","📊","🧭","📌","🔖","⭐️","🧪"]

    init(existing: TabDto? = nil,
         onSave: @escaping (TabCreateDto) -> Void,
         onUpdate: ((UUID, TabUpdateDto) -> Void)? = nil)
    {
        self.existing = existing
        self.onSave = onSave
        self.onUpdate = onUpdate
        _title = State(initialValue: existing?.title ?? "")
        _type = State(initialValue: existing?.tabType ?? .board)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Live preview
                Section {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(tint.opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint, lineWidth: 1))
                            .frame(width: 56, height: 56)
                            .overlay(Text(icon).font(.system(size: 26)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title.isEmpty ? "Untitled" : title)
                                .font(.headline)
                            Text(tabTypeLabel(type))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Title") {
                    TextField("Tab title", text: $title)
                }

                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(icons, id: \.self) { ic in
                                Text(ic)
                                    .font(.largeTitle)
                                    .frame(width: 52, height: 52)
                                    .background(ic == icon ? tint.opacity(0.25) : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .onTapGesture { icon = ic }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Color") {
                    ColorPicker("Icon/Accent", selection: $tint, supportsOpacity: false)
                }

                Section("Type") {
                    Picker("Tab Type", selection: $type) {
                        ForEach(TabType.allCases, id: \.self) { t in
                            Text(tabTypeLabel(t)).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(existing == nil ? "Create Tab" : "Edit Tab")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Save") {
                        if let existing = existing {
                            // Update existing
                            let dto = TabUpdateDto(
                                title: title.isEmpty ? "Untitled" : title,
                                tabType: type,
                                position: existing.position,
                                layout: existing.layout
                            )
                            onUpdate?(existing.id, dto)
                        } else {
                            // Create new
                            let dto = TabCreateDto(
                                boardId: UUID(), // replace with selected board ID
                                title: title.isEmpty ? "Untitled" : title,
                                tabType: type,
                                position: 0,
                                layout: nil
                            )
                            onSave(dto)
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Helpers
    private func tabTypeLabel(_ type: TabType) -> String {
        switch type {
        case .board: return "Board"
        case .calendar: return "Calendar"
        case .timeline: return "Timeline"
        case .kanban: return "Kanban"
        case .whiteboard: return "Whiteboard"
        case .chat: return "Chat"
        case .metrics: return "Metrics"
        case .custom: return "Custom"
        }
    }
}
