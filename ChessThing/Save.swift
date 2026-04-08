import Foundation
import SwiftData 

@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var snapshot: Data

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), snapshot: Data){
        self.id = id
        self.name = name 
        self.createdAt = createdAt 
        self.snapshot = snapshot
    }
}