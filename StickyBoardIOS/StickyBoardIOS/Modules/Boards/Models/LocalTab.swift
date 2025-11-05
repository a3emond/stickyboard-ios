import SwiftUI
import StickyBoardKit

struct LocalTab: Identifiable, Equatable {
    let id: UUID
    var title: String
    var icon: String
    var tint: Color
    var type: TabType
    var position: Int
    var isActive: Bool

    init(from dto: TabDto, active: Bool = false) {
        id = dto.id
        title = dto.title
        icon = LocalTab.icon(for: dto.tabType)
        tint = LocalTab.tint(for: dto.tabType)
        type = dto.tabType
        position = dto.position
        isActive = active
    }

    // MARK: - UI Mapping Helpers
    static func icon(for type: TabType) -> String {
        switch type {
        case .board: return "📋"
        case .calendar: return "📆"
        case .timeline: return "🗓"
        case .kanban: return "🧩"
        case .whiteboard: return "🧠"
        case .chat: return "💬"
        case .metrics: return "📊"
        case .custom: return "⚙️"
        }
    }

    static func tint(for type: TabType) -> Color {
        switch type {
        case .board: return .accentColor
        case .calendar: return .orange
        case .timeline: return .blue
        case .kanban: return .green
        case .whiteboard: return .purple
        case .chat: return .cyan
        case .metrics: return .mint
        case .custom: return .gray
        }
    }
}
