//
//  CardCompactView.swift
//  StickyBoardIOS
//
//  Created by alexandre emond on 2025-11-04.
//


import SwiftUI
import StickyBoardKit

struct CardCompactView: View {
    @Binding var card: LocalCard
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(card.title ?? "Untitled")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Label(describeCardType(card.type), systemImage: "square.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let due = card.dueDate {
                        Text(due, style: .date) // OR:
                        // Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private func describeCardType(_ type: CardType) -> String {
    switch type {
    case .note: return "Note"
    case .task: return "Task"
    case .event_: return "Event"
    case .drawing: return "Drawing"
    }
}
