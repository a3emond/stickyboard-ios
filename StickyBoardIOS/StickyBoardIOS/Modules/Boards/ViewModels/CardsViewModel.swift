import SwiftUI
import StickyBoardKit

@MainActor
final class CardsViewModel: ObservableObject {
    @Published var cards: [LocalCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let app: AppState = .shared
    private let boardId: UUID
    private let tabId: UUID
    private let sectionId: UUID?

    init(boardId: UUID, tabId: UUID, sectionId: UUID?) {
        self.boardId = boardId
        self.tabId = tabId
        self.sectionId = sectionId
    }

    // ============================================================
    // MARK: - Load (robust with fallback)
    // ============================================================
    func loadCards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("LOADcards → board=\(boardId)")
            print("  tab=\(tabId)")
            print("  section=\(String(describing: sectionId))")

            let dtos: [CardDto]

            if let sectionId {
                // Primary path: by section
                let bySection = try await app.cardService.getBySection(sectionId: sectionId)
                print("RESULT bySection count: \(bySection.count)")

                if bySection.isEmpty {
                    // Fallback: fetch by tab and filter in app
                    let byTab = try await app.cardService.getByTab(tabId: tabId)
                    print("RESULT byTab (for fallback) count: \(byTab.count)")
                    dtos = byTab.filter { $0.sectionId == sectionId }
                    print("RESULT after client filter for section: \(dtos.count)")
                } else {
                    dtos = bySection
                }
            } else {
                // No section context: standard tab fetch
                let byTab = try await app.cardService.getByTab(tabId: tabId)
                print("RESULT byTab count: \(byTab.count)")
                dtos = byTab
            }

            cards = dtos.map { LocalCard(from: $0) }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
            print("LOAD error:", errorMessage ?? error.localizedDescription)
            // Ultra-safe fallback: keep UI populated if possible
            // (no change to 'cards' on failure)
        }
    }
    // ============================================================
    // MARK: - Create
    // ============================================================
    func addCard(title: String = "New Card") async {
        do {
            let createDto = CardCreateDto(
                boardId: boardId,
                tabId: tabId,
                sectionId: sectionId,
                type: .note,
                title: title,
                content: nil,
                tags: nil,
                priority: 0,
                assigneeId: nil,
                dueDate: nil
            )

            let newId = try await app.cardService.create(createDto)
            let newDto = try await app.cardService.get(id: newId)
            cards.append(LocalCard(from: newDto))
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    // ============================================================
    // MARK: - Update
    // ============================================================
    func updateCard(_ card: LocalCard, dto: CardUpdateDto) async {
        print("Updating card \(card.id)")
        do {
            try await app.cardService.update(id: card.id, dto: dto)

            // Pull fresh version from backend so ink + content sync
            let fresh = try await app.cardService.get(id: card.id)

            if let i = cards.firstIndex(where: { $0.id == card.id }) {
                cards[i] = LocalCard(from: fresh)
                // Force refresh to notify SwiftUI
                            objectWillChange.send()
            }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
            print("Update error:", error)
        }
    }

    // ============================================================
    // MARK: - Delete
    // ============================================================
    func deleteCard(_ card: LocalCard) async {
        do {
            try await app.cardService.delete(id: card.id)
            cards.removeAll { $0.id == card.id }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    // ============================================================
    // MARK: - Helpers
    // ============================================================
    func binding(for card: LocalCard) -> Binding<LocalCard>? {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return nil }
        return Binding(
            get: { self.cards[index] },
            set: { self.cards[index] = $0 }
        )
    }
}
