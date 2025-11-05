import SwiftUI

struct TopTabsDock: View {
    let boardTitle: String
    @Binding var tabs: [LocalTab]

    var onActivate: (LocalTab) -> Void
    var onAdd: () -> Void
    var onEdit: (LocalTab) -> Void
    var onDelete: (LocalTab) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabs) { tab in
                    BoardTabChip(
                        boardTitle: boardTitle,
                        tab: tab,
                        activate: { onActivate(tab) },
                        edit: { onEdit(tab) },
                        delete: { onDelete(tab) }
                    )
                }

                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Tab")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .contentMargins(.horizontal, 2, for: .scrollContent)
    }
}
