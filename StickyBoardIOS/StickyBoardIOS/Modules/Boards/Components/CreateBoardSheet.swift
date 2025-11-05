import SwiftUI
import StickyBoardKit

struct CreateBoardSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var visibility: BoardVisibility = .private_
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Board Info") {
                    TextField("Board title", text: $title)
                        .focused($isTitleFocused)
                        .submitLabel(.done)

                    Picker("Visibility", selection: $visibility) {
                        Text("Private").tag(BoardVisibility.private_)
                        Text("Shared").tag(BoardVisibility.shared)
                        Text("Public").tag(BoardVisibility.public_)
                    }
                    .pickerStyle(.segmented)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .disabled(isLoading)
            .navigationTitle("Create Board")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createBoard() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isTitleFocused = true
                }
            }
        }
    }

    private func createBoard() async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a board title."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dto = BoardCreateDto(
            title: title,
            visibility: visibility,
            orgId: nil,
            folderId: nil,
            theme: nil,
            meta: nil
        )

        do {
            _ = try await app.boardService.create(dto)
            await MainActor.run {
                app.selectedBoardId = nil
            }
            // Optionally refresh board list after creation
            try? await Task.sleep(nanoseconds: 150_000_000)
            await MainActor.run {
                dismiss()
            }
        } catch {
            errorMessage = (error as? APIError)?.description ?? error.localizedDescription
        }
    }
}
