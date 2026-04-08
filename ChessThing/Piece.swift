import Foundation 

enum PieceType {
    case king, queen, rook, bishop, knight, pawn
}

enum PieceColor {
    case white, black 
}

struct Piece {
    let type: PieceType
    let color: PieceColor 
}

struct Square: Identifiable {
    let id = UUID()
    let row: Int 
    let col: Int 
    var piece: Piece?
}