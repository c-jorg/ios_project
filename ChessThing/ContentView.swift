import SwiftUI
import SwiftData

struct ContentView: View {

    enum Screen {
        case menu
        case game
        case loadSelect
    }

    @State var screen: Screen = .menu
    @State var game = Chess()
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
                                game = try SaveGameStore.load(record: record)
                                screen = .game
                            } catch {
                                loadErrorMessage = error.localizedDescription
                            }
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
                            try SaveGameStore.save(name: finalName, game: game, context: modelContext)
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

    struct MainMenuView: View {
        let onStartGame: () -> Void
        let onLoadGame: () -> Void

        var body: some View {
            VStack(spacing: 20) {
                Text("Chess Thing").font(.largeTitle.bold())

                Button("Start New Game") {
                    onStartGame()
                }.buttonStyle(.borderedProminent)
                Button("Load Game") {
                    onLoadGame()
                }.buttonStyle(.borderedProminent)
            }.padding()
        }
    }
    
    struct GameView: View {
        @Binding var game: Chess
        let onBackToMenu: () -> Void
        let onSave: () -> Void

        var body: some View{
            VStack(spacing: 12) {
                HStack{
                    Text("Chess Game").font(.largeTitle.bold())
                    Button("Menu"){
                        onBackToMenu()
                    }.buttonStyle(.borderedProminent)
                    Button("Save"){
                        onSave()
                    }.buttonStyle(.borderedProminent)
                }

                HStack{
                    Button("New Game"){
                        game.newGame()
                    }.buttonStyle(.borderedProminent)

                    Text("Turn: \(game.isWhiteTurn ? "White" : "Black")").font(.headline)
                }

                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) {row in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) {col in
                                squareView(row: row, col: col).onTapGesture {
                                    game.handleTap(row: row, col: col)
                                }
                            }
                        }
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.4), lineWidth: 1))

                Text("Last Move: \(game.lastMove ?? "None")").font(.subheadline).foregroundStyle(.secondary)
            }.padding()
        }

        @ViewBuilder
        private func squareView(row: Int, col: Int) -> some View {
            let square = game.board[row][col]
            let isSelected = game.selectedSquare?.row == row && game.selectedSquare?.col == col

            ZStack {
                Rectangle().fill((row+col).isMultiple(of: 2) ? .green : .brown.opacity(0.25))

                if isSelected {
                    Rectangle().fill(.yellow.opacity(0.35))
                }

                if let piece = square.piece {
                    Text(symbol(for: piece)).font(.largeTitle)
                }
            }.frame(width: 44, height: 44)
        }

        private func symbol(for piece: Piece) -> String {
            switch (piece.type, piece.color) {
                case (.king, .white): return "♔"
                case (.queen, .white): return "♕"
                case (.rook, .white): return "♖"
                case (.bishop, .white): return "♗"
                case (.knight, .white): return "♘"
                case (.pawn, .white): return "♙"
                case (.king, .black): return "♚"
                case (.queen, .black): return "♛"
                case (.rook, .black): return "♜"
                case (.bishop, .black): return "♝"
                case (.knight, .black): return "♞"
                case (.pawn, .black): return "♟︎"
            }
        }
    }
}

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

#Preview {
    ContentView().modelContainer(for: [SavedGame.self], inMemory: true)
}
