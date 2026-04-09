import SwiftUI
import SwiftData

struct MainMenuView: View {
    let onStartGame: () -> Void
    let onLoadGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chess Thing").font(.largeTitle.bold())
            
            Button("Start New Game") {
                onStartGame()
            }.buttonStyle(.borderedProminent)
            Button("Load Game") {
                onLoadGame()
            }.buttonStyle(.borderedProminent)
        }.padding()
    }
}