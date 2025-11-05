import Foundation
import StickyBoardKit

struct LocalCard: Identifiable, Equatable {
    let id: UUID
    var type: CardType
    var title: String?
    var content: JSONValue?
    var inkData: JSONValue?
    var tags: [String]
    var status: CardStatus
    var priority: Int
    var assigneeId: UUID?
    var dueDate: Date?
    var startTime: Date?
    var endTime: Date?

    // we add these ⬇️ (needed for updates)
    var sectionId: UUID?
    var tabId: UUID?

    var isExpanded: Bool = false
    
    init(from dto: CardDto) {
        id = dto.id
        type = dto.type
        title = dto.title
        content = dto.content
        inkData = dto.inkData
        tags = dto.tags
        status = dto.status
        priority = dto.priority
        assigneeId = dto.assigneeId
        dueDate = dto.dueDate
        startTime = dto.startTime
        endTime = dto.endTime
        
        // new fields populated
        sectionId = dto.sectionId
        tabId = dto.tabId
    }
    
    static func == (lhs: LocalCard, rhs: LocalCard) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.status == rhs.status &&
        lhs.priority == rhs.priority &&
        lhs.dueDate == rhs.dueDate &&
        lhs.inkData == rhs.inkData &&
        lhs.content == rhs.content &&
        lhs.assigneeId == rhs.assigneeId
    }
}
