import SwiftUI
import StickyBoardKit

struct CollapsibleSectionView: View {
    @Binding var section: LocalSection
    @StateObject private var vm: CardsViewModel
    @State private var selectedCard: LocalCard?

    // MARK: - Context menu states
    @State private var showOptions = false
    @State private var showRenameSheet = false
    @State private var newTitle = ""
    @State private var isProcessing = false

    // MARK: - Init
    init(section: Binding<LocalSection>, boardId: UUID?, tabId: UUID?) {
        _section = section
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
        VStack(alignment: .leading, spacing: 10) {
            // MARK: Section Header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    section.isExpanded.toggle()
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
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            .onLongPressGesture {
                showOptions = true
            }

            // MARK: Cards
            if section.isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if vm.isLoading {
                        ProgressView().padding()
                    } else if vm.cards.isEmpty {
                        Text("No cards")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach($vm.cards) { $card in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(card.title ?? "Untitled")
                                            .font(.subheadline.bold())

                                        HStack {
                                            Text(describeCardType(card.type))
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(5)

                                            Text(describeCardStatus(card.status))
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.1))
                                                .cornerRadius(5)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                )
                                .frame(height: 70)
                                .padding(.horizontal)
                                .onTapGesture {
                                    selectedCard = card
                                }
                        }
                    }

                    // MARK: Add Card Button
                    Button {
                        Task { await vm.addCard() }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Card")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundColor(.accentColor)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 6)
            }
        }
        .padding(.vertical, 6)
        .task { await vm.loadCards() }

        // MARK: - Card detail sheet
        .sheet(item: $selectedCard) { card in
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

        // MARK: - Context Menu
        .confirmationDialog("Section Options", isPresented: $showOptions, titleVisibility: .visible) {
            Button("Rename Section") {
                newTitle = section.title
                showRenameSheet = true
            }

            Button("Delete Section", role: .destructive) {
                Task { await deleteSection() }
            }

            Button("Cancel", role: .cancel) {}
        }

        // MARK: - Rename Sheet
        .sheet(isPresented: $showRenameSheet) {
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
    }

    // MARK: - Actions
    private func renameSection() async {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isProcessing = true
        do {
            // Update locally
            section.title = newTitle

            // Build DTO with current position
            let dto = SectionUpdateDto(
                title: newTitle,
                position: section.position
            )

            // Send to backend
            try await AppState.shared.sectionService.update(id: section.id, dto: dto)

            // Close sheet
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
            // Parent refresh will handle actual removal
        } catch {
            print("Delete error:", error.localizedDescription)
        }
        isProcessing = false
    }
}

// MARK: - Helpers
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
