import SwiftUI
import StickyBoardKit

struct BoardsTabView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var vm: BoardsViewModel
    @State private var showTabEditor = false
    @State private var editingTab: LocalTab?

    // MARK: - Init
    init(app: AppState = .shared) {
        _vm = StateObject(wrappedValue: BoardsViewModel(app: app))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.isLoading {
                    ProgressView("Loading...")
                        .padding(.top, 40)

                } else if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding()

                } else if vm.selectedBoard == nil {
                    // MARK: Board List
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

                } else {
                    // MARK: Tabs Bar
                    TopTabsDock(
                        boardTitle: vm.selectedBoard?.title ?? "Untitled Board",
                        tabs: $vm.tabs,
                        onActivate: vm.activateTab,
                        onAdd: { showTabEditor = true },
                        onEdit: { tab in editingTab = tab },
                        onDelete: vm.deleteTab
                    )

                    Divider().padding(.bottom, 4)

                    // MARK: Section Scroll
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach($vm.sections) { $section in
                                CollapsibleSectionView(
                                    section: $section,
                                    boardId: vm.selectedBoard?.id,
                                    tabId: app.selectedTabId
                                )
                                .environmentObject(app)
                            }

                            // MARK: Add Section Button
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

            // MARK: - Create Tab Sheet
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

            // MARK: - Edit Tab Sheet
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

            // MARK: - Initial Load + Reactivity
            .task {
                if vm.boards.isEmpty {
                    await vm.loadMyBoards()
                }
            }
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
        }
    }
}
