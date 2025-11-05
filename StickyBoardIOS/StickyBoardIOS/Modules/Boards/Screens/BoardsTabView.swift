import SwiftUI
import StickyBoardKit

struct BoardsTabView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var vm: BoardsViewModel
    @State private var showTabEditor = false
    @State private var editingTab: LocalTab?

    // accordion state
    @State private var expandedSectionId: UUID? = nil

    // Init
    init(app: AppState = .shared) {
        _vm = StateObject(wrappedValue: BoardsViewModel(app: app))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Loading state
                if vm.isLoading {
                    ProgressView("Loading...")
                        .padding(.top, 40)

                // Error
                } else if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding()

                // Board list (no board selected yet)
                } else if vm.selectedBoard == nil {
                    List(vm.boards, id: \.id) { board in
                        Button {
                            Task { await vm.selectBoard(board) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(board.title)
                                    .font(.headline)
                                Text(vm.visibilityLabel(for: board.visibility))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                // Board view
                } else {

                    // Tabs
                    TopTabsDock(
                        boardTitle: vm.selectedBoard?.title ?? "Untitled Board",
                        tabs: $vm.tabs,
                        onActivate: vm.activateTab,
                        onAdd: { showTabEditor = true },
                        onEdit: { tab in editingTab = tab },
                        onDelete: vm.deleteTab
                    )

                    Divider().padding(.bottom, 4)

                    // Sections
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {

                            ForEach($vm.sections) { $section in
                                CollapsibleSectionView(
                                    section: $section,
                                    boardId: vm.selectedBoard?.id,
                                    tabId: app.selectedTabId,
                                    expandedSectionId: $expandedSectionId
                                )
                                .environmentObject(app)
                            }

                            // Add Section Button
                            Button {
                                Task { await vm.addNewSection() }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Section")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.accentColor)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Boards")

            // Create tab sheet
            .sheet(isPresented: $showTabEditor) {
                if let board = vm.selectedBoard {
                    TabEditorSheet(onSave: { dto in
                        Task {
                            let createDto = TabCreateDto(
                                boardId: board.id,
                                title: dto.title,
                                tabType: dto.tabType,
                                position: dto.position,
                                layout: dto.layout
                            )
                            do {
                                _ = try await app.tabService.create(createDto)
                                await vm.loadTabs(for: board.id)
                            } catch {
                                vm.errorMessage = (error as? APIError)?.description ?? error.localizedDescription
                            }
                        }
                    })
                }
            }

            // Edit tab sheet
            .sheet(item: $editingTab) { tab in
                if let board = vm.selectedBoard {
                    TabEditorSheet(
                        existing: TabDto(
                            id: tab.id,
                            boardId: board.id,
                            title: tab.title,
                            tabType: tab.type,
                            position: tab.position,
                            layout: nil
                        ),
                        onSave: { _ in },
                        onUpdate: { id, dto in
                            Task {
                                do {
                                    try await app.tabService.update(id: id, dto: dto)
                                    await vm.loadTabs(for: board.id)
                                } catch {
                                    vm.errorMessage = (error as? APIError)?.description ?? error.localizedDescription
                                }
                            }
                        }
                    )
                }
            }

            // Initial load
            .task {
                if vm.boards.isEmpty {
                    await vm.loadMyBoards()
                }
            }

            // Auto select a board if changed
            .onReceive(app.$selectedBoardId.dropFirst()) { boardId in
                Task {
                    if let id = boardId {
                        await vm.selectBoardById(id)
                    } else {
                        vm.selectedBoard = nil
                        vm.tabs = []
                        vm.sections = []
                    }
                }
            }

            // Auto-expand first section when sections load
            .onChange(of: vm.sections) { newSections in
                if expandedSectionId == nil, let first = newSections.first {
                    expandedSectionId = first.id
                    vm.sections[0].isExpanded = true   //expand first
                }
            }
        }
    }
}
