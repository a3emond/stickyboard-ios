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
    // MARK: - Load
    // ============================================================
    func loadCards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let dtos: [CardDto]
            if let sectionId {
                dtos = try await app.cardService.getBySection(sectionId: sectionId)
            } else {
                dtos = try await app.cardService.getByTab(tabId: tabId)
            }

            cards = dtos.map { LocalCard(from: $0) }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
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
        do {
            try await app.cardService.update(id: card.id, dto: dto)

            if let i = cards.firstIndex(where: { $0.id == card.id }) {
                var updated = card
                updated.title = dto.title ?? card.title
                updated.content = dto.content ?? card.content
                updated.priority = dto.priority
                updated.dueDate = dto.dueDate
                cards[i] = updated
            }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
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
