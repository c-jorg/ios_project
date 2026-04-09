import Foundation 

enum PieceType: String, Codable {
    case king, queen, rook, bishop, knight, pawn
}

enum PieceColor: String, Codable {
    case white, black 
}

struct Piece: Codable {
    let type: PieceType
    let color: PieceColor 
}

struct Square: Identifiable, Codable {
    let id = UUID()
    let row: Int 
    let col: Int 
    var piece: Piece?

    init(id: UUID = UUID(), row: Int, col: Int, piece: Piece?) {
        self.id = id
        self.row = row
        self.col = col
        self. piece = piece
    }
}