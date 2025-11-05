import Foundation
import StickyBoardKit

struct LocalSection: Identifiable, Equatable {
    let id: UUID
    var title: String
    var position: Int
    var cards: [LocalCard]
    var isExpanded: Bool

    init(from dto: SectionDto, cards: [LocalCard] = [], expanded: Bool = true) {
        id = dto.id
        title = dto.title
        position = dto.position
        self.cards = cards
        isExpanded = expanded
    }

    // Provide manual Equatable conformance because CardDto is not Equatable.
    // We compare primitive properties directly and compare cards by their ids
    // (UUID) to avoid requiring CardDto: Equatable.
    static func == (lhs: LocalSection, rhs: LocalSection) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.position == rhs.position
            && lhs.isExpanded == rhs.isExpanded
            && lhs.cards.map({ $0.id }) == rhs.cards.map({ $0.id })
    }
}
