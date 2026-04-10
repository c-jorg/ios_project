import SwiftUI
import SwiftData

struct CheckersView: View {
    @Binding var game: Checkers 
    let onBackToMenu: () -> Void
    let onSave: () -> Void
    @State private var animatingMove: MoveAnimation? = nil
    @State private var moveProgress: CGFloat = 0 

    private let cellSize: CGFloat = 44 
    private let animationDuration: Double = 0.8

    private struct MoveAnimation {
        let from: (row: Int, col: Int)
        let to: (row: Int, col: Int)
        let piece: CheckersPiece
    }

    var body: some View{

    }

    private func handleTap(row: Int, col: Int) {
        guard animatingMove == nil else {return}

        if let selected = game.selectedSquare, 
            let sourcePiece = game.board[selected.row][selected.col].piece, let destinationPiece = game.board[row][col].piece {
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
            Rectangle().fill((row + col).isMultiple(of: 2) ? .green : .brown.opacity(0.25))
            if isSelected {
                Rectangle().fill(.yellow.opacity(0.5))
            }
            if let piece = square.piece, !isAnimatingFrom && !isAnimatingTo {
                Text(symbol(for: piece)).font(.largeTitle)
            }
        }.frame(width: cellSize, height: cellSize)
    }

    private func symbol(for piece: CheckersPiece) -> String {
        switch (piece.type, piece.color) {
            case (.man, .white): return "⛀"
            case (.man, .black): return "⛂"
            case (.king, .white): return "⛁"
            case (.king, .black): return "⛃"
        }
    }
}