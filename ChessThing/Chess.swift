import Foundation

struct ChessSnapshot: Codable {
    var board: [[Square]]
    //var selectedSquare: (row: Int, col: Int)?
    var selectedRow: Int?
    var selectedCol: Int?
    var isWhiteTurn: Bool 
    var whiteCastled: Bool 
    var blackCastled: Bool 
    var lastMove: String?
}

//@binding
struct Chess {
    var board: [[Square]]
    var selectedSquare: (row: Int, col: Int)?
    var selectedRow: Int?
    var selectedCol: Int?
    var isWhiteTurn: Bool 
    var whiteCastled: Bool 
    var blackCastled: Bool 
    var lastMove: String?

    func snapshot() -> ChessSnapshot {
        ChessSnapshot(
            board: board, 
            selectedRow: selectedSquare?.row,
            selectedCol: selectedSquare?.col,
            isWhiteTurn: isWhiteTurn,
            whiteCastled: whiteCastled,
            blackCastled: blackCastled,
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
        whiteCastled = snapshot.whiteCastled
        blackCastled = snapshot.blackCastled
        lastMove = snapshot.lastMove
        }

    init(){
        self.board = []
        self.selectedSquare = nil 
        self.isWhiteTurn = true 
        self.whiteCastled = false 
        self.blackCastled = false 
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
        whiteCastled = false 
        blackCastled = false 
        lastMove = nil
    }

    mutating func handleTap(row: Int, col: Int){
        guard row >= 0, row < 8, col >= 0, col < 8 else { 
            return
        }

        if let selected = selectedSquare {
            if selected.row == row && selected.col == col {
                selectedSquare = nil 
                return 
            }

            let movingPiece = board[selected.row][selected.col].piece 
            let destinationPiece = board[row][col].piece 

            guard let movingPiece else {
                selectedSquare = nil 
                return
            }

            if destinationPiece?.color == movingPiece.color {
                selectedSquare = (row, col) 
                return
            }

            board[row][col].piece = movingPiece 
            board[selected.row][selected.col].piece = nil 
            lastMove = "\(toSquare(row: selected.row, col: selected.col))\(toSquare(row: row, col: col))"
            isWhiteTurn.toggle() 
            selectedSquare = nil 
            return 
        }

        guard let tappedPiece = board[row][col].piece else {
            return
        }

        let canSelect = (tappedPiece.color == .white && isWhiteTurn) || (tappedPiece.color == .black && !isWhiteTurn)
        if canSelect {
            selectedSquare = (row, col)
        }
    }

    private func toSquare(row: Int, col: Int) -> String {
        let files = ["a","b","c","d","e","f","g","h"]
        let rank = 8 - row 
        return "\(files[col])\(rank)"
    }
}