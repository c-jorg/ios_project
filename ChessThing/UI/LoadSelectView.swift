import SwiftUI
import SwiftData

struct LoadSelectView: View {
    let savedGames: [SavedGame]
    let onBack: () -> Void
    let onLoad: (SavedGame) -> Void
    
    var body: some View {
        NavigationStack {
            List(savedGames) { record in
                Button {
                    onLoad(record)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.name).font(.headline)
                        Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Load Game")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { onBack() }
                }
            }
        }
    }
}