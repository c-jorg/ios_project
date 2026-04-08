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
    var body: some View {
        Group {
            switch screen {
                case .menu:
                    MainMenuView(onStartGame: {
                        game.newGame()
                        screen = .game
                    }
                )
                case .game:
                    GameView(game: $game, onBackToMenu: {
                        screen = .menu
                    }
                )
            }
        }.animation(.easeInOut, value: screen)
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
                button("Load Game") {
                    //onLoadGame()
                }.buttonStyle(.borderedProminent)
            }.padding()
        }
    }
    
    struct GameView: View {
        @Binding var game: Chess
        let onBackToMenu: () -> Void

        VStack(spacing: 12) {
            HStack{
                Text("Chess Game").font(.largeTitle.bold())
                Button("Menu"){
                    onBackToMenu()
                }.buttonStyle(.borderedProminent)
                Button("Save"){
                    //todo
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
    private func squareView(row: Int, col: Int) -? some View {
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

#Preview {
    ContentView()
}
