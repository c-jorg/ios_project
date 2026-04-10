import Foundation

enum CheckersPieceType: String, Codable {
    case man, king
}

enum CheckersPieceColor: String, Codable {
    case white, black
}

struct CheckersPiece: Codable {
    let type: CheckersPieceType
    let color: CheckersPieceColor
}

struct CheckersSquare: Identifiable, Codable {
    var id = UUID()
    let row: Int
    let col: Int
    var piece: CheckersPiece?

    init(row: Int, col: Int, piece: CheckersPiece?){
        self.row = row
        self.col = col
        self.piece = piece
    }
}
