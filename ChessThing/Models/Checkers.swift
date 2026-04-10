import Foundation

struct CheckersSnapshot: Codable {
    var board: [[CheckersSquare]]
    var selectedRow: Int?
    var selectedCol: Int?
    var forcedRow: Int?
    var forcedCol: Int?
    var isWhiteTurn: Bool
    var winner: CheckersPieceColor?
    var lastMove: String?
    var gameType: String?
}

struct Checkers {
    var board: [[CheckersSquare]]
    var selectedSquare: (row: Int, col: Int)?
    var forcedFromSquare: (row: Int, col: Int)?
    var isWhiteTurn: Bool
    var lastMove: String?
    var gameType: String
    var winner: CheckersPieceColor?

    private typealias MoveOption = (to: (row: Int, col: Int), captured: (row: Int, col: Int)?)

    init() {
        self.board = []
        self.selectedSquare = nil
        self.forcedFromSquare = nil
        self.isWhiteTurn = true
        self.lastMove = nil
        self.gameType = "checkers"
        self.winner = nil
        newGame()
    }

    func snapshot() -> CheckersSnapshot {
        CheckersSnapshot(
            board: board,
            selectedRow: selectedSquare?.row,
            selectedCol: selectedSquare?.col,
            forcedRow: forcedFromSquare?.row,
            forcedCol: forcedFromSquare?.col,
            isWhiteTurn: isWhiteTurn,
            winner: winner,
            lastMove: lastMove,
            gameType: gameType
        )
    }

    mutating func load(from snapshot: CheckersSnapshot) {
        board = snapshot.board

        if let r = snapshot.selectedRow, let c = snapshot.selectedCol {
            selectedSquare = (r, c)
        } else {
            selectedSquare = nil
        }

        if let r = snapshot.forcedRow, let c = snapshot.forcedCol {
            forcedFromSquare = (r, c)
        } else {
            forcedFromSquare = nil
        }

        isWhiteTurn = snapshot.isWhiteTurn
        winner = snapshot.winner
        lastMove = snapshot.lastMove
        gameType = snapshot.gameType ?? "checkers"
    }

    mutating func newGame() {
        board = (0..<8).map { row in
            (0..<8).map { col in
                CheckersSquare(row: row, col: col, piece: nil)
            }
        }

        for row in 0..<3 {
            for col in 0..<8 where isDarkSquare(row, col) {
                board[row][col].piece = CheckersPiece(type: .man, color: .black)
            }
        }

        for row in 5..<8 {
            for col in 0..<8 where isDarkSquare(row, col) {
                board[row][col].piece = CheckersPiece(type: .man, color: .white)
            }
        }

        selectedSquare = nil
        forcedFromSquare = nil
        isWhiteTurn = true
        lastMove = nil
        winner = nil
    }

    mutating func handleTap(row: Int, col: Int) {
        guard winner == nil else { return }
        guard inBounds(row, col) else { return }

        let currentColor = colorForTurn()

        if let forced = forcedFromSquare {
            selectedSquare = forced
            if row == forced.row && col == forced.col {
                return
            }
        }

        if let selected = selectedSquare {
            guard let movingPiece = board[selected.row][selected.col].piece else {
                selectedSquare = nil
                forcedFromSquare = nil
                return
            }

            if let tappedPiece = board[row][col].piece,
               tappedPiece.color == movingPiece.color,
               forcedFromSquare == nil {
                let mustCapture = hasAnyCapture(for: currentColor)
                let tappedMoves = legalMoves(from: (row, col))
                if !mustCapture || tappedMoves.contains(where: { $0.captured != nil }) {
                    selectedSquare = (row, col)
                }
                return
            }

            let moves = legalMoves(from: selected)
            let mustCapture = hasAnyCapture(for: currentColor)

            guard let chosen = moves.first(where: { $0.to.row == row && $0.to.col == col }) else {
                return
            }

            if mustCapture && chosen.captured == nil {
                return
            }

            let wasPromoted = applyMove(from: selected, to: chosen.to, captured: chosen.captured)
            lastMove = "\(toSquare(row: selected.row, col: selected.col))\(chosen.captured == nil ? "-" : "x")\(toSquare(row: chosen.to.row, col: chosen.to.col))"

            if chosen.captured != nil && !wasPromoted {
                let moreCaptures = legalMoves(from: chosen.to).contains(where: { $0.captured != nil })
                if moreCaptures {
                    selectedSquare = chosen.to
                    forcedFromSquare = chosen.to
                    return
                }
            }

            selectedSquare = nil
            forcedFromSquare = nil
            isWhiteTurn.toggle()

            let nextColor = colorForTurn()
            if !hasAnyLegalMove(for: nextColor) {
                winner = opponent(of: nextColor)
            }
            return
        }

        guard let tappedPiece = board[row][col].piece else { return }
        guard tappedPiece.color == currentColor else { return }

        let mustCapture = hasAnyCapture(for: currentColor)
        let moves = legalMoves(from: (row, col))
        if mustCapture && !moves.contains(where: { $0.captured != nil }) {
            return
        }

        selectedSquare = (row, col)
    }

    private func legalMoves(from: (row: Int, col: Int)) -> [MoveOption] {
        guard inBounds(from.row, from.col) else { return [] }
        guard let piece = board[from.row][from.col].piece else { return [] }

        let manDirections: [(Int, Int)] = piece.color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)]
        let kingDirections: [(Int, Int)] = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        let directions = piece.type == .king ? kingDirections : manDirections

        var results: [MoveOption] = []

        for (dr, dc) in directions {
            let stepRow = from.row + dr
            let stepCol = from.col + dc
            if inBounds(stepRow, stepCol), board[stepRow][stepCol].piece == nil {
                results.append(((stepRow, stepCol), nil))
            }

            let midRow = from.row + dr
            let midCol = from.col + dc
            let landRow = from.row + 2 * dr
            let landCol = from.col + 2 * dc

            if inBounds(landRow, landCol),
               let midPiece = board[midRow][midCol].piece,
               midPiece.color != piece.color,
               board[landRow][landCol].piece == nil {
                results.append(((landRow, landCol), (midRow, midCol)))
            }
        }

        return results
    }

    private func hasAnyCapture(for color: CheckersPieceColor) -> Bool {
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board[row][col].piece, piece.color == color else { continue }
                if legalMoves(from: (row, col)).contains(where: { $0.captured != nil }) {
                    return true
                }
            }
        }
        return false
    }

    private func hasAnyLegalMove(for color: CheckersPieceColor) -> Bool {
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board[row][col].piece, piece.color == color else { continue }
                if !legalMoves(from: (row, col)).isEmpty {
                    return true
                }
            }
        }
        return false
    }

    @discardableResult
    private mutating func applyMove(
        from: (row: Int, col: Int),
        to: (row: Int, col: Int),
        captured: (row: Int, col: Int)?
    ) -> Bool {
        guard let movingPiece = board[from.row][from.col].piece else { return false }

        board[to.row][to.col].piece = movingPiece
        board[from.row][from.col].piece = nil

        if let captured {
            board[captured.row][captured.col].piece = nil
        }

        return maybePromote(at: to)
    }

    private mutating func maybePromote(at square: (row: Int, col: Int)) -> Bool {
        guard let piece = board[square.row][square.col].piece else { return false }
        guard piece.type == .man else { return false }

        if piece.color == .white && square.row == 0 {
            board[square.row][square.col].piece = CheckersPiece(type: .king, color: .white)
            return true
        }

        if piece.color == .black && square.row == 7 {
            board[square.row][square.col].piece = CheckersPiece(type: .king, color: .black)
            return true
        }

        return false
    }

    private func colorForTurn() -> CheckersPieceColor {
        isWhiteTurn ? .white : .black
    }

    private func opponent(of color: CheckersPieceColor) -> CheckersPieceColor {
        color == .white ? .black : .white
    }

    private func inBounds(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < 8 && col >= 0 && col < 8
    }

    private func isDarkSquare(_ row: Int, _ col: Int) -> Bool {
        !(row + col).isMultiple(of: 2)
    }

    private func toSquare(row: Int, col: Int) -> String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        return "\(files[col])\(8 - row)"
    }
}