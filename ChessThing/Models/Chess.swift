import Foundation

struct ChessSnapshot: Codable {
    var board: [[Square]]
    var selectedRow: Int?
    var selectedCol: Int?
    var isWhiteTurn: Bool
    var whiteKingMoved: Bool
    var blackKingMoved: Bool
    var whiteKingsideRookMoved: Bool
    var whiteQueensideRookMoved: Bool
    var blackKingsideRookMoved: Bool
    var blackQueensideRookMoved: Bool
    var lastMove: String?
}

struct Chess {
    var board: [[Square]]
    var selectedSquare: (row: Int, col: Int)?
    var isWhiteTurn: Bool
    var whiteKingMoved: Bool
    var blackKingMoved: Bool
    var whiteKingsideRookMoved: Bool
    var whiteQueensideRookMoved: Bool
    var blackKingsideRookMoved: Bool
    var blackQueensideRookMoved: Bool
    var lastMove: String?

    func snapshot() -> ChessSnapshot {
        ChessSnapshot(
            board: board,
            selectedRow: selectedSquare?.row,
            selectedCol: selectedSquare?.col,
            isWhiteTurn: isWhiteTurn,
            whiteKingMoved: whiteKingMoved,
            blackKingMoved: blackKingMoved,
            whiteKingsideRookMoved: whiteKingsideRookMoved,
            whiteQueensideRookMoved: whiteQueensideRookMoved,
            blackKingsideRookMoved: blackKingsideRookMoved,
            blackQueensideRookMoved: blackQueensideRookMoved,
            lastMove: lastMove
        )
    }

    mutating func load(from snapshot: ChessSnapshot) {
        board = snapshot.board
        if let r = snapshot.selectedRow, let c = snapshot.selectedCol {
            selectedSquare = (r, c)
        } else {
            selectedSquare = nil
        }
        isWhiteTurn = snapshot.isWhiteTurn
        whiteKingMoved = snapshot.whiteKingMoved
        blackKingMoved = snapshot.blackKingMoved
        whiteKingsideRookMoved = snapshot.whiteKingsideRookMoved
        whiteQueensideRookMoved = snapshot.whiteQueensideRookMoved
        blackKingsideRookMoved = snapshot.blackKingsideRookMoved
        blackQueensideRookMoved = snapshot.blackQueensideRookMoved
        lastMove = snapshot.lastMove
    }

    init() {
        self.board = []
        self.selectedSquare = nil
        self.isWhiteTurn = true
        self.whiteKingMoved = false
        self.blackKingMoved = false
        self.whiteKingsideRookMoved = false
        self.whiteQueensideRookMoved = false
        self.blackKingsideRookMoved = false
        self.blackQueensideRookMoved = false
        self.lastMove = nil
        newGame()
    }

    mutating func newGame() {
        board = (0..<8).map { row in
            (0..<8).map { col in
                Square(row: row, col: col, piece: nil)
            }
        }

        let backRank: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]

        for col in 0..<8 {
            board[0][col].piece = Piece(type: backRank[col], color: .black)
            board[1][col].piece = Piece(type: .pawn, color: .black)
            board[6][col].piece = Piece(type: .pawn, color: .white)
            board[7][col].piece = Piece(type: backRank[col], color: .white)
        }

        selectedSquare = nil
        isWhiteTurn = true
        whiteKingMoved = false
        blackKingMoved = false
        whiteKingsideRookMoved = false
        whiteQueensideRookMoved = false
        blackKingsideRookMoved = false
        blackQueensideRookMoved = false
        lastMove = nil
    }

    mutating func handleTap(row: Int, col: Int) {
        guard inBounds(row, col) else { return }

        if let selected = selectedSquare {
            if selected.row == row && selected.col == col {
                selectedSquare = nil
                return
            }

            guard let movingPiece = board[selected.row][selected.col].piece else {
                selectedSquare = nil
                return
            }

            if let destinationPiece = board[row][col].piece,
               destinationPiece.color == movingPiece.color {
                selectedSquare = (row, col)
                return
            }

            let from = (row: selected.row, col: selected.col)
            let to = (row: row, col: col)

            guard canMovePiece(from: from, to: to, piece: movingPiece) else {
                return
            }

            applyMove(from: from, to: to, piece: movingPiece)
            lastMove = "\(toSquare(row: from.row, col: from.col)) \(toSquare(row: to.row, col: to.col))"
            isWhiteTurn.toggle()
            selectedSquare = nil
            return
        }

        guard let tappedPiece = board[row][col].piece else { return }
        let canSelect = (tappedPiece.color == .white && isWhiteTurn) || (tappedPiece.color == .black && !isWhiteTurn)
        if canSelect {
            selectedSquare = (row, col)
        }
    }

    private func canMovePiece(from: (row: Int, col: Int), to: (row: Int, col: Int), piece: Piece) -> Bool {
        guard inBounds(to.row, to.col) else { return false }
        guard from.row != to.row || from.col != to.col else { return false }

        if let destinationPiece = board[to.row][to.col].piece,
           destinationPiece.color == piece.color {
            return false
        }

        let rowDelta = to.row - from.row
        let colDelta = to.col - from.col

        switch piece.type {
        case .pawn:
            return canMovePawn(from: from, to: to, piece: piece)

        case .knight:
            return (abs(rowDelta), abs(colDelta)) == (2, 1) || (abs(rowDelta), abs(colDelta)) == (1, 2)

        case .bishop:
            return abs(rowDelta) == abs(colDelta) && pathClear(from: from, to: to)

        case .rook:
            return (rowDelta == 0 || colDelta == 0) && pathClear(from: from, to: to)

        case .queen:
            let straight = rowDelta == 0 || colDelta == 0
            let diagonal = abs(rowDelta) == abs(colDelta)
            return (straight || diagonal) && pathClear(from: from, to: to)

        case .king:
            if canCastle(from: from, to: to, piece: piece) {
                return true
            }
            return max(abs(rowDelta), abs(colDelta)) == 1 && !isSquareAttacked(row: to.row, col: to.col, by: oppositeColor(of: piece.color))
        }
    }

    private func canMovePawn(from: (row: Int, col: Int), to: (row: Int, col: Int), piece: Piece) -> Bool {
        let direction = piece.color == .white ? -1 : 1
        let startRow = piece.color == .white ? 6 : 1
        let rowDelta = to.row - from.row
        let colDelta = to.col - from.col
        let destinationPiece = board[to.row][to.col].piece

        if colDelta == 0 {
            if rowDelta == direction {
                return destinationPiece == nil
            }

            if rowDelta == 2 * direction && from.row == startRow {
                let midRow = from.row + direction
                return board[midRow][from.col].piece == nil && destinationPiece == nil
            }

            return false
        }

        if abs(colDelta) == 1 && rowDelta == direction {
            return destinationPiece?.color == oppositeColor(of: piece.color)
        }

        return false
    }

    private func canCastle(from: (row: Int, col: Int), to: (row: Int, col: Int), piece: Piece) -> Bool {
        guard piece.type == .king else { return false }
        guard from.row == to.row else { return false }
        guard abs(to.col - from.col) == 2 else { return false }

        let isWhite = piece.color == .white
        let homeRow = isWhite ? 7 : 0
        guard from.row == homeRow, from.col == 4 else { return false }

        if isWhite {
            guard !whiteKingMoved else { return false }
        } else {
            guard !blackKingMoved else { return false }
        }

        if isSquareAttacked(row: from.row, col: from.col, by: oppositeColor(of: piece.color)) {
            return false
        }

        if to.col == 6 {
            if isWhite {
                guard !whiteKingsideRookMoved else { return false }
            } else {
                guard !blackKingsideRookMoved else { return false }
            }

            guard board[homeRow][5].piece == nil, board[homeRow][6].piece == nil else { return false }
            guard let rook = board[homeRow][7].piece, rook.type == .rook, rook.color == piece.color else { return false }
            guard !isSquareAttacked(row: homeRow, col: 5, by: oppositeColor(of: piece.color)) else { return false }
            guard !isSquareAttacked(row: homeRow, col: 6, by: oppositeColor(of: piece.color)) else { return false }
            return true
        }

        if to.col == 2 {
            if isWhite {
                guard !whiteQueensideRookMoved else { return false }
            } else {
                guard !blackQueensideRookMoved else { return false }
            }

            guard board[homeRow][1].piece == nil, board[homeRow][2].piece == nil, board[homeRow][3].piece == nil else { return false }
            guard let rook = board[homeRow][0].piece, rook.type == .rook, rook.color == piece.color else { return false }
            guard !isSquareAttacked(row: homeRow, col: 3, by: oppositeColor(of: piece.color)) else { return false }
            guard !isSquareAttacked(row: homeRow, col: 2, by: oppositeColor(of: piece.color)) else { return false }
            return true
        }

        return false
    }

    private mutating func applyMove(from: (row: Int, col: Int), to: (row: Int, col: Int), piece: Piece) {
        if piece.type == .king, abs(to.col - from.col) == 2 {
            board[to.row][to.col].piece = piece
            board[from.row][from.col].piece = nil

            if to.col == 6 {
                board[to.row][5].piece = board[to.row][7].piece
                board[to.row][7].piece = nil
                if piece.color == .white {
                    whiteKingsideRookMoved = true
                    whiteKingMoved = true
                } else {
                    blackKingsideRookMoved = true
                    blackKingMoved = true
                }
            } else if to.col == 2 {
                board[to.row][3].piece = board[to.row][0].piece
                board[to.row][0].piece = nil
                if piece.color == .white {
                    whiteQueensideRookMoved = true
                    whiteKingMoved = true
                } else {
                    blackQueensideRookMoved = true
                    blackKingMoved = true
                }
            }
            return
        }

        board[to.row][to.col].piece = piece
        board[from.row][from.col].piece = nil
        markMoved(piece: piece, from: from)
    }

    private mutating func markMoved(piece: Piece, from: (row: Int, col: Int)) {
        switch (piece.color, piece.type, from.row, from.col) {
        case (.white, .king, _, _):
            whiteKingMoved = true
        case (.black, .king, _, _):
            blackKingMoved = true
        case (.white, .rook, 7, 7):
            whiteKingsideRookMoved = true
        case (.white, .rook, 7, 0):
            whiteQueensideRookMoved = true
        case (.black, .rook, 0, 7):
            blackKingsideRookMoved = true
        case (.black, .rook, 0, 0):
            blackQueensideRookMoved = true
        default:
            break
        }
    }

    private func isSquareAttacked(row: Int, col: Int, by attacker: PieceColor) -> Bool {
        for r in 0..<8 {
            for c in 0..<8 {
                guard let piece = board[r][c].piece, piece.color == attacker else { continue }
                if canAttack(piece: piece, from: (row: r, col: c), to: (row: row, col: col)) {
                    return true
                }
            }
        }
        return false
    }

    private func canAttack(piece: Piece, from: (row: Int, col: Int), to: (row: Int, col: Int)) -> Bool {
        let rowDelta = to.row - from.row
        let colDelta = to.col - from.col

        switch piece.type {
        case .pawn:
            let direction = piece.color == .white ? -1 : 1
            return rowDelta == direction && abs(colDelta) == 1

        case .knight:
            return (abs(rowDelta), abs(colDelta)) == (2, 1) || (abs(rowDelta), abs(colDelta)) == (1, 2)

        case .bishop:
            return abs(rowDelta) == abs(colDelta) && pathClear(from: from, to: to)

        case .rook:
            return (rowDelta == 0 || colDelta == 0) && pathClear(from: from, to: to)

        case .queen:
            let straight = rowDelta == 0 || colDelta == 0
            let diagonal = abs(rowDelta) == abs(colDelta)
            return (straight || diagonal) && pathClear(from: from, to: to)

        case .king:
            return max(abs(rowDelta), abs(colDelta)) == 1
        }
    }

    private func pathClear(from: (row: Int, col: Int), to: (row: Int, col: Int)) -> Bool {
        let rowStep = to.row == from.row ? 0 : (to.row > from.row ? 1 : -1)
        let colStep = to.col == from.col ? 0 : (to.col > from.col ? 1 : -1)

        var currentRow = from.row + rowStep
        var currentCol = from.col + colStep

        while currentRow != to.row || currentCol != to.col {
            if board[currentRow][currentCol].piece != nil {
                return false
            }
            currentRow += rowStep
            currentCol += colStep
        }

        return true
    }

    private func oppositeColor(of color: PieceColor) -> PieceColor {
        color == .white ? .black : .white
    }

    private func inBounds(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < 8 && col >= 0 && col < 8
    }

    private func toSquare(row: Int, col: Int) -> String {
        let files = ["a","b","c","d","e","f","g","h"]
        let rank = 8 - row
        return "\(files[col])\(rank)"
    }
}