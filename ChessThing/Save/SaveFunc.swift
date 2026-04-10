import Foundation 
import SwiftData

enum LoadedGame {
    case chess(Chess)
    case checkers(Checkers)
}

enum SaveGameStore {
    static func save(name: String, game: Chess, context: ModelContext) throws {
        let data = try JSONEncoder().encode(game.snapshot())
        let record = SavedGame(name: name, snapshot: data)
        context.insert(record)
        try context.save()
    }
    
    static func save(name: String, game: Checkers, context: ModelContext) throws {
        let data = try JSONEncoder().encode(game.snapshot())
        let record = SavedGame(name: name, snapshot: data)
        context.insert(record)
        try context.save()
    }

    static func load(record: SavedGame) throws -> LoadedGame {
        let rawObject = try JSONSerialization.jsonObject(with: record.snapshot)
        let dict = rawObject as? [String: Any]
        let gameType = (dict?["gameType"] as? String)?.lowercased()
        
        if gameType == "chess" {
            let snap = try JSONDecoder().decode(ChessSnapshot.self, from: record.snapshot)
            var game = Chess()
            game.load(from: snap)
            return .chess(game)
        }
        
        if gameType == "checkers" {
            let snap = try JSONDecoder().decode(CheckersSnapshot.self, from: record.snapshot)
            var game = Checkers()
            game.load(from: snap)
            return .checkers(game)
        }
        
        throw NSError(domain: "InvalidGameType", code: 0, userInfo: nil)
    }
}
