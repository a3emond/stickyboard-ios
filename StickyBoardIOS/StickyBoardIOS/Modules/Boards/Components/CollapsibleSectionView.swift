import SwiftUI
import StickyBoardKit

struct CollapsibleSectionView: View {
    @Binding var section: LocalSection
    @Binding var expandedSectionId: UUID?
    @StateObject private var vm: CardsViewModel
    @State private var selectedCard: LocalCard?

    // Rename/Delete
    @State private var showRenameSheet = false
    @State private var newTitle = ""
    @State private var isProcessing = false

    // MARK: - Init
    init(section: Binding<LocalSection>, boardId: UUID?, tabId: UUID?, expandedSectionId: Binding<UUID?>) {
        _section = section
        _expandedSectionId = expandedSectionId
        _vm = StateObject(
            wrappedValue: CardsViewModel(
                boardId: boardId ?? UUID(),
                tabId: tabId ?? UUID(),
                sectionId: section.wrappedValue.id
            )
        )
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: Section Header (tap to expand, long-press menu via contextMenu)
            HStack {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if expandedSectionId == section.id {
                            // collapse if already open
                            expandedSectionId = nil
                            section.isExpanded = false
                        } else {
                            // open this + collapse others
                            expandedSectionId = section.id
                            section.isExpanded = true
                        }
                    }
                } label: {
                    HStack {
                        Text(section.title)
                            .font(.headline)
                        Spacer()
                        Image(systemName: section.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
            }
            
            .contextMenu {
                Button("Rename Section") {
                    newTitle = section.title
                    showRenameSheet = true
                }
                Button("Delete Section", role: .destructive) {
                    Task { await deleteSection() }
                }
            }
            .onChange(of: expandedSectionId) { newId in
                section.isExpanded = (newId == section.id)
            }

            // MARK: Cards
            if section.isExpanded {
                if vm.isLoading {
                    ProgressView().padding()
                } else if vm.cards.isEmpty {
                    // Empty state + compact add button
                    VStack(spacing: 10) {
                        Text("No cards yet")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        addCardButton
                    }
                    .padding(.vertical, 8)
                } else {
                    // Sticky grid
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach($vm.cards) { $card in
                            CardCompactView(card: $card) {
                                selectedCard = card
                            }
                        }
                        addCardTile
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
        .task { await vm.loadCards() }

        // MARK: - Card detail sheet
        .sheet(item: $selectedCard, onDismiss: {
            Task { await vm.loadCards() } // <- force refresh from server after close
        }) { card in
            if let binding = vm.binding(for: card) {
                CardDetailView(
                    card: binding,
                    onClose: { selectedCard = nil },
                    onSave: { dto in
                        Task { await vm.updateCard(binding.wrappedValue, dto: dto) }
                    }
                )
            } else {
                Text("Card not found")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        // MARK: - Rename Sheet
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
        }
    }

    // MARK: - Add Card UI

    private var addCardButton: some View {
        Button {
            Task { await vm.addCard() }
        } label: {
            Label("Add Card", systemImage: "plus.square.fill.on.square.fill")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var addCardTile: some View {
        Button {
            Task { await vm.addCard() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 1.2)
                    )

                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                    Text("New")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.gray)
            }
            .frame(height: 120)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add card")
    }

    // MARK: - Rename Sheet UI

    private var renameSheet: some View {
        VStack(spacing: 20) {
            Text("Rename Section")
                .font(.title3.bold())
                .padding(.top)

            TextField("New title", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if isProcessing {
                ProgressView().padding(.vertical)
            }

            Button("Save") {
                Task { await renameSection() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing || newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.bottom, 12)

            Button("Cancel", role: .cancel) {
                showRenameSheet = false
            }
            .tint(.secondary)

            Spacer()
        }
        .presentationDetents([.medium])
        .padding()
    }

    // MARK: - Backend Actions

    private func renameSection() async {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isProcessing = true
        do {
            // Update locally for instant UI feedback
            section.title = newTitle

            let dto = SectionUpdateDto(
                title: newTitle,
                position: section.position
            )
            try await AppState.shared.sectionService.update(id: section.id, dto: dto)
            showRenameSheet = false
        } catch {
            print("Rename error:", error.localizedDescription)
        }
        isProcessing = false
    }

    private func deleteSection() async {
        isProcessing = true
        do {
            try await AppState.shared.sectionService.delete(id: section.id)
            // parent container handles actual removal from the list
        } catch {
            print("Delete error:", error.localizedDescription)
        }
        isProcessing = false
    }
}

// MARK: - (Kept) Helpers – if still used elsewhere
private func describeCardType(_ type: CardType) -> String {
    switch type {
    case .note: return "Note"
    case .task: return "Task"
    case .event_: return "Event"
    case .drawing: return "Drawing"
    }
}

private func describeCardStatus(_ status: CardStatus) -> String {
    switch status {
    case .open: return "Open"
    case .in_progress: return "In Progress"
    case .blocked: return "Blocked"
    case .done: return "Done"
    case .archived: return "Archived"
    }
}
