import Foundation 
import SwiftData

enum SaveGameStore {
    static func save(name: String, game: Chess, context: ModelContext) throws {
        let data = try JSONEncoder().encode(game.snapshot())
        let record = SavedGame(name: name, snapshot: data)
        context.insert(record)
        try context.save()
    }

    static func load(record: SavedGame) throws -> Chess {
        let snap = try JSONDecoder().decode(ChessSnapshot.self, from: record.snapshot)
        var game = Chess()
        game.load(from: snap)
        return game
    }
}