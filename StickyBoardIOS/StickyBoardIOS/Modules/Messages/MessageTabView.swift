import SwiftUI

// MARK: - Inbox Root
struct MessageTabView: View {
    @State private var currentMailbox: Mailbox = .inbox
    @State private var searchQuery = ""
    @State private var showCompose = false

    // Mock data (replace with API)
    @State private var messages: [Message] = [
        .init(subject: "Welcome to StickyBoard", sender: "System", preview: "We’re glad to have you here.", date: .now),
        .init(subject: "Board Access Request", sender: "Alex", preview: "Hey, can you grant me access to your board?", date: .now.addingTimeInterval(-3600)),
        .init(subject: "Deployment done", sender: "Worker", preview: "The new version has been deployed successfully.", date: .now.addingTimeInterval(-86400))
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {

                // MARK: - Custom Header
                HStack {
                    Text(currentMailbox.title)
                        .font(.largeTitle.bold())
                    Spacer()
                }
                .padding([.horizontal, .top])

                // MARK: - Search / Filter Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search messages...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding([.horizontal, .top])
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)

                Divider().padding(.bottom, 4)

                // MARK: - Message List / Empty State
                if filteredMessages.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("No messages found")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: filteredMessages.count)
                } else {
                    MessageListView(messages: filteredMessages)
                }
            }

            // MARK: - Floating Compose Button
            Button {
                showCompose = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .bold))
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .padding(.trailing, 22)
            .padding(.bottom, 22)
            .sheet(isPresented: $showCompose) {
                ComposeMessageView { newMsg in
                    messages.insert(newMsg, at: 0)
                }
            }
        }
        .ignoresSafeArea(.keyboard) // prevents layout push
    }

    // MARK: - Filter Logic
    private var filteredMessages: [Message] {
        let base: [Message]
        switch currentMailbox {
        case .inbox:
            base = messages.filter { !$0.archived && !$0.sent }
        case .archived:
            base = messages.filter { $0.archived }
        case .sent:
            base = messages.filter { $0.sent }
        }

        guard !searchQuery.isEmpty else { return base }

        let q = searchQuery.lowercased()
        return base.filter {
            $0.subject.lowercased().contains(q)
            || $0.sender.lowercased().contains(q)
            || $0.preview.lowercased().contains(q)
        }
    }
}

// MARK: - Mailbox Enum
enum Mailbox: String, CaseIterable, Identifiable {
    case inbox, archived, sent
    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .archived: return "Archived"
        case .sent: return "Sent"
        }
    }
}

// MARK: - Message Model
struct Message: Identifiable {
    let id = UUID()
    var subject: String
    var sender: String
    var preview: String
    var date: Date
    var archived: Bool = false
    var sent: Bool = false
}

// MARK: - Message List
struct MessageListView: View {
    var messages: [Message]

    var body: some View {
        List(messages) { msg in
            NavigationLink(destination: MessageDetailView(message: msg)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(msg.subject)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(msg.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(msg.sender)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(msg.preview)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Message Detail
struct MessageDetailView: View {
    let message: Message

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(message.subject)
                    .font(.title3.bold())

                HStack {
                    Text("From: \(message.sender)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(message.date.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                Text(message.preview + "\n\nThis is a placeholder for full message content.")
                    .font(.body)
                    .padding(.top, 4)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Compose Message
struct ComposeMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recipient = ""
    @State private var subject = ""
    @State private var messageBody = ""

    var onSend: (Message) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("To") {
                    TextField("Recipient", text: $recipient)
                        .textInputAutocapitalization(.never)
                }
                Section("Subject") {
                    TextField("Subject", text: $subject)
                }
                Section("Message") {
                    TextEditor(text: $messageBody)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        onSend(Message(
                            subject: subject,
                            sender: "You",
                            preview: messageBody,
                            date: .now,
                            sent: true
                        ))
                        dismiss()
                    }
                    .disabled(subject.isEmpty || messageBody.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MessageTabView()
    }
    .preferredColorScheme(.light)
}
