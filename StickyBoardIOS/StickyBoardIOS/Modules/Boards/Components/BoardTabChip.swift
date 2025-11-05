import SwiftUI

struct BoardTabChip: View {
    let boardTitle: String
    var tab: LocalTab
    var activate: () -> Void
    var edit: () -> Void
    var delete: () -> Void

    var body: some View {
        Button(action: activate) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tab.isActive ? tab.tint.opacity(0.18) : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tab.isActive ? tab.tint : .clear, lineWidth: tab.isActive ? 1.0 : 0)
                        )
                        .frame(width: tab.isActive ? 56 : 44, height: tab.isActive ? 56 : 44)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: tab.isActive)

                    Text(tab.icon)
                        .font(.system(size: tab.isActive ? 26 : 22))
                        .frame(width: tab.isActive ? 56 : 44, height: tab.isActive ? 56 : 44)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: tab.isActive)
                }

                if tab.isActive {
                    VStack(spacing: 0) {
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                        Text(boardTitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 72)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.18), value: tab.isActive)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                edit()
            } label: {
                Label("Update", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                delete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityLabel(tab.title)
    }
}
