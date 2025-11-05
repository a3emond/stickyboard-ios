import SwiftUI
import StickyBoardKit

struct SideMenu: View {
    @EnvironmentObject var app: AppState
    @Binding var selectedTab: HomeView.Tab
    @Binding var showMenu: Bool
    @State private var showingCreateBoard = false

    // MARK: - Data
    @State private var boards: [BoardDto] = []
    @State private var isLoadingBoards = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(.systemGray5), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 2, y: 0)
                .ignoresSafeArea(edges: .vertical)

            VStack(alignment: .leading, spacing: 18) {
                // MARK: - Header
                HStack(spacing: 12) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                    Text("StickyBoard")
                        .font(.headline.bold())
                }
                .padding(.bottom, 10)
                .padding(.top, 12)

                Divider().padding(.trailing, 20)

                // MARK: - Contextual Section
                switch selectedTab {
                case .boards:
                    boardsMenu()
                case .collab:
                    menuGroup(title: "Collaboration", items: [
                        ("building.2", "Organizations", {}),
                        ("person.2", "Friends", {}),
                        ("person.crop.circle.badge.plus", "Invites", {})
                    ])
                case .inbox:
                    menuGroup(title: "Inbox", items: [
                        ("tray", "All Messages", {}),
                        ("envelope.badge", "Unread", {}),
                        ("archivebox", "Archived", {})
                    ])
                }

                Divider().padding(.trailing, 20).padding(.vertical, 8)

                // MARK: - Common Section
                menuButton(icon: "gearshape", label: "Settings") {}
                menuButton(icon: "person.circle", label: "Profile") {}

                Spacer()

                // MARK: - Logout
                Button(role: .destructive) {
                    Task {
                        await app.logout()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showMenu = false
                            selectedTab = .boards
                        }
                    }
                } label: {
                    Label("Logout", systemImage: "arrow.backward.square")
                        .font(.body)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
            .padding(20)
        }
        // Board Creation Sheet
        .sheet(isPresented: $showingCreateBoard) {
            CreateBoardSheet()
                .environmentObject(app)
        }
        .task {
            await loadBoards()
        }
    }

    // MARK: - Boards Menu
    @ViewBuilder
    private func boardsMenu() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Boards")
                .font(.headline)
                .padding(.bottom, 4)

            if isLoadingBoards {
                ProgressView().padding(.vertical)
            } else if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else if boards.isEmpty {
                Text("No boards yet")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(boards, id: \.id) { board in
                    Button {
                        Task {
                            await selectBoard(board)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.grid.2x2")
                                .frame(width: 20)
                            Text(board.title)
                                .font(.body)
                                .bold(app.selectedBoardId == board.id)
                            Spacer()
                        }
                        .foregroundColor(app.selectedBoardId == board.id ? .accentColor : .primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(app.selectedBoardId == board.id ? Color.accentColor.opacity(0.15) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Add board button
            Button {
                showingCreateBoard = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Board")
                        .font(.body.weight(.semibold))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .foregroundColor(.accentColor)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Placeholder for future folders
            Text("Folders (coming soon)")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
    }

    // MARK: - Helpers
    private func menuGroup(title: String, items: [(String, String, () -> Void)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                menuButton(icon: item.0, label: item.1, action: item.2)
            }
        }
    }

    private func menuButton(icon: String, label: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showMenu = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 26)
                Text(label)
                    .font(.body)
                    .bold(isActive)
                Spacer()
            }
            .foregroundColor(isActive ? .accentColor : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func selectBoard(_ board: BoardDto) async {
        app.selectedBoardId = board.id
        try? await Task.sleep(nanoseconds: 150_000_000) // small delay for smooth transition
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selectedTab = .boards
            showMenu = false
        }
    }

    private func loadBoards() async {
        isLoadingBoards = true
        defer { isLoadingBoards = false }
        do {
            boards = try await app.boardService.getMine()
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }
}
