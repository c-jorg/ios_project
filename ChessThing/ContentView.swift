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
        @State private var animatingMove: MoveAnimation? = nil
        @State private var moveProgress: CGFloat = 0
        
        private let cellSize: CGFloat = 44
        private let animationDuration: Double = 0.8
        
        private struct MoveAnimation {
            let from: (row: Int, col: Int)
            let to: (row: Int, col: Int)
            let piece: Piece
        }
        
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
                
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<8, id: \.self) { col in
                                    squareView(row: row, col: col)
                                        .onTapGesture {
                                            handleTap(row: row, col: col)
                                        }
                                    
                                }
                            }
                        }
                    }
                    
                    if let move = animatingMove {
                        Text(symbol(for: move.piece))
                            .font(.largeTitle)
                            .frame(width: cellSize, height: cellSize)
                            .position(
                                x: CGFloat(move.from.col) * cellSize + cellSize / 2 + CGFloat(move.to.col - move.from.col) * cellSize * moveProgress,
                                y: CGFloat(move.from.row) * cellSize + cellSize / 2 + CGFloat(move.to.row - move.from.row) * cellSize * moveProgress
                            )
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: cellSize * 8, height: cellSize * 8)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.black.opacity(0.4), lineWidth: 1)
                )
                
                Text("Last Move: \(game.lastMove ?? "None")").font(.subheadline).foregroundStyle(.secondary)
            }.padding()
        }
        
        private func handleTap(row: Int, col: Int) {
            guard animatingMove == nil else { return }
            
            if let selected = game.selectedSquare,
               let sourcePiece = game.board[selected.row][selected.col].piece {
                let destinationPiece = game.board[row][col].piece
                let isDifferentColorTarget = destinationPiece?.color != sourcePiece.color
                let isActualMove = !(selected.row == row && selected.col == col) && isDifferentColorTarget
                
                if isActualMove {
                    animatingMove = MoveAnimation(
                        from: (selected.row, selected.col),
                        to: (row, col),
                        piece: sourcePiece
                    )
                    moveProgress = 0
                    
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        moveProgress = 1
                        game.handleTap(row: row, col: col)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        animatingMove = nil
                        moveProgress = 0
                    }
                } else {
                    game.handleTap(row: row, col: col)
                }
            } else {
                game.handleTap(row: row, col: col)
            }
        }
        
        @ViewBuilder
        private func squareView(row: Int, col: Int) -> some View {
            let square = game.board[row][col]
            let isSelected = game.selectedSquare?.row == row && game.selectedSquare?.col == col
            let isAnimatingFrom = animatingMove?.from.row == row && animatingMove?.from.col == col
            let isAnimatingTo = animatingMove?.to.row == row && animatingMove?.to.col == col
            
            ZStack {
                Rectangle()
                    .fill((row + col).isMultiple(of: 2) ? .green : .brown.opacity(0.25))
                
                if isSelected {
                    Rectangle().fill(.yellow.opacity(0.35))
                }
                
                if let piece = square.piece, !isAnimatingFrom && !isAnimatingTo {
                    Text(symbol(for: piece)).font(.largeTitle)
                }
            }
            .frame(width: cellSize, height: cellSize)
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
}
    #Preview {
        ContentView().modelContainer(for: [SavedGame.self], inMemory: true)
    }

