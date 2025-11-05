import SwiftUI
import StickyBoardKit

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var selectedTab: Tab = .boards
    @State private var showMenu = false

    enum Tab { case boards, collab, inbox }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: - Main Tab Content
                NavigationStack {
                    TabView(selection: $selectedTab) {
                        BoardsTabView() 
                            .tag(Tab.boards)
                            .tabItem {
                                Label("Boards", systemImage: "rectangle.grid.2x2")
                            }

                        CollaborationTabView()
                            .tag(Tab.collab)
                            .tabItem {
                                Label("Collab", systemImage: "person.2")
                            }

                        MessageTabView()
                            .tag(Tab.inbox)
                            .tabItem {
                                Label("Inbox", systemImage: "tray.full")
                            }
                    }
                    .navigationBarHidden(true)
                }
                .blur(radius: showMenu ? 3 : 0)
                .disabled(showMenu)
                .animation(.easeInOut(duration: 0.25), value: showMenu)

                // MARK: - Overlay when menu is open
                if showMenu {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                showMenu = false
                            }
                        }
                }

                // MARK: - Drawer Menu
                SideMenu(selectedTab: $selectedTab, showMenu: $showMenu)
                    .environmentObject(app)
                    .frame(width: geo.size.width * 0.68)
                    .offset(x: showMenu ? 0 : -geo.size.width * 0.93)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showMenu)

                // MARK: - Drawer Pull Handle
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                showMenu.toggle()
                            }
                        } label: {
                            VStack {
                                Image(systemName: showMenu ? "chevron.left" : "chevron.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 28, height: 90)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                        }
                        .offset(x: showMenu ? 6 : -8)

                        Spacer()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
