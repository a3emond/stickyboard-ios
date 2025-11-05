import SwiftUI
import StickyBoardKit

@MainActor
final class BoardsViewModel: ObservableObject {
    // MARK: - Published state
    @Published var boards: [BoardDto] = []
    @Published var selectedBoard: BoardDto?
    @Published var tabs: [LocalTab] = []
    @Published var sections: [LocalSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let app: AppState
    private var lastSelectedBoardId: UUID?

    init(app: AppState) {
        self.app = app

        // Observe board selection from app state
        Task { @MainActor in
            for await boardId in app.$selectedBoardId.values {
                // Debounce and prevent recursive re-selections
                guard let id = boardId, id != lastSelectedBoardId else { continue }
                lastSelectedBoardId = id
                await selectBoardById(id)
            }
        }
    }

    // ============================================================
    // MARK: - Boards
    // ============================================================

    func loadMyBoards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            boards = try await app.boardService.getMine()
            // Auto-select the first board only if none is selected yet
            if selectedBoard == nil, let first = boards.first {
                await selectBoard(first)
            }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    func selectBoard(_ board: BoardDto) async {
        // Prevent redundant calls
        guard selectedBoard?.id != board.id else { return }
        selectedBoard = board
        app.selectedBoardId = board.id
        await loadTabs(for: board.id)
    }
    
    func selectBoardById(_ boardId: UUID) async {
        // Prevent redundant fetch if already selected
        guard selectedBoard?.id != boardId else { return }
        if let board = boards.first(where: { $0.id == boardId }) {
            await selectBoard(board)
        } else {
            do {
                let dto = try await app.boardService.get(id: boardId)
                await selectBoard(dto)
            } catch {
                errorMessage = (error as? APIError)?.description ?? error.localizedDescription
            }
        }
    }

    // ============================================================
    // MARK: - Tabs
    // ============================================================

    func loadTabs(for boardId: UUID) async {
        do {
            let tabDtos = try await app.tabService.getForBoard(boardId: boardId)
            tabs = tabDtos.sorted(by: { $0.position < $1.position })
                .enumerated()
                .map { idx, dto in LocalTab(from: dto, active: idx == 0) }

            if let first = tabs.first {
                activateTab(first)
            } else {
                sections = []
            }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    func activateTab(_ tab: LocalTab) {
        tabs.indices.forEach { tabs[$0].isActive = false }

        if let i = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[i].isActive = true
            app.selectedTabId = tab.id
            Task { await loadSections(for: tab.id) }
        }
    }

    func deleteTab(_ tab: LocalTab) {
        withAnimation {
            tabs.removeAll { $0.id == tab.id }
        }
    }

    // ============================================================
    // MARK: - Sections
    // ============================================================

    func loadSections(for tabId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let sectionDtos = try await app.sectionService.getForTab(tabId: tabId)
            let ordered = sectionDtos.sorted(by: { $0.position < $1.position })

            var loadedSections: [LocalSection] = []
            for dto in ordered {
                let cardVM = CardsViewModel(
                    boardId: app.selectedBoardId ?? UUID(),
                    tabId: tabId,
                    sectionId: dto.id
                )
                await cardVM.loadCards()
                let local = LocalSection(from: dto, cards: cardVM.cards)
                loadedSections.append(local)
            }
            sections = loadedSections
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    func addNewSection() async {
        guard let activeTab = tabs.first(where: { $0.isActive }) else { return }

        let tempDto = SectionDto(
            id: UUID(),
            tabId: activeTab.id,
            parentSectionId: nil,
            title: "New Section",
            position: sections.count,
            layout: nil
        )

        let newSection = LocalSection(from: tempDto, cards: [], expanded: true)
        sections.append(newSection)

        do {
            let createDto = SectionCreateDto(
                tabId: activeTab.id,
                parentSectionId: nil,
                title: newSection.title,
                position: newSection.position,
                layout: nil
            )
            _ = try await app.sectionService.create(createDto)
            await loadSections(for: activeTab.id)
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }

    // ============================================================
    // MARK: - Helpers
    // ============================================================

    func visibilityLabel(for visibility: BoardVisibility) -> String {
        switch visibility {
        case .private_: return "Private"
        case .shared: return "Shared"
        case .public_: return "Public"
        }
    }
}
