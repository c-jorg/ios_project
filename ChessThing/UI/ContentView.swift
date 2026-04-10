import SwiftUI
import SwiftData

struct ContentView: View {
    
    enum Screen {
        case menu
        case game
        case loadSelect
        case checkersGame
    }
    
    @State var screen: Screen = .menu
    @State var game = Chess()
    @State var checkersGame = Checkers()
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SavedGame.createdAt, order: .reverse) var savedGames: [SavedGame]
    @State var showSaveDialog = false
    @State var saveName = ""
    @State var saveErrorMessage: String?
    @State var loadErrorMessage: String?
    
    
    var body: some View {
        
        Group {
            switch screen {
                case .menu:
                    MainMenuView(onStartGame: {
                        game.newGame()
                        screen = .game
                    }, onStartCheckersGame: {
                        checkersGame.newGame()
                        screen = .checkersGame
                    }, onLoadGame: {
                        screen = .loadSelect
                    }
                    )
                case .game:
                    GameView(game: $game, onBackToMenu: {
                        screen = .menu
                    }, onSave: {
                        showSaveDialog = true
                    }
                    )
                case .loadSelect:
                    LoadSelectView(
                        savedGames: savedGames,
                        onBack: {screen = .menu},
                        onLoad: {record in
                            do {
                                let loaded = try SaveGameStore.load(record: record)
                                switch loaded {
                                case .chess(let loadedChess):
                                    game = loadedChess
                                    screen = .game
                                case .checkers(let loadedCheckers):
                                    checkersGame = loadedCheckers
                                    screen = .checkersGame
                                }
                            } catch {
                                loadErrorMessage = error.localizedDescription
                            }
                        }
                    )
                case .checkersGame:
                    CheckersView(game: $checkersGame, onBackToMenu: {
                        screen = .menu
                    }, onSave: {
                        showSaveDialog = true
                    }
                )
            }
        }.animation(.easeInOut, value: screen)
            .alert("Save Error", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .alert("Load Error", isPresented: Binding(
                get: { loadErrorMessage != nil },
                set: { if !$0 { loadErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(loadErrorMessage ?? "")
            }
            .sheet(isPresented: $showSaveDialog) {
                VStack(spacing: 16) {
                    Text("Save Game").font(.headline)
                    
                    TextField("Game name (optional)", text: $saveName)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    HStack(spacing: 12) {
                        Button("Cancel", role: .cancel) {
                            showSaveDialog = false
                            saveName = ""
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            do {
                                let name = saveName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let finalName = name.isEmpty ? "Game \(Date.now.formatted(date: .abbreviated, time: .shortened))" : name
                                switch screen{
                                case .game:
                                    try SaveGameStore.save(name: finalName, game: game, context: modelContext)
                                case .checkersGame:
                                    try SaveGameStore.save(name: finalName, game: checkersGame, context: modelContext)
                                default:
                                        break
                            
                                }
                                saveName = ""
                                showSaveDialog = false
                            } catch {
                                saveErrorMessage = error.localizedDescription
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
    }
}

#Preview {
    ContentView().modelContainer(for: [SavedGame.self], inMemory: true)
}
