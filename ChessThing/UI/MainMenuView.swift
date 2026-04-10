import SwiftUI
import SwiftData

struct MainMenuView: View {
    let onStartGame: () -> Void
    let onStartCheckersGame: () -> Void
    let onLoadGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chess Thing").font(.largeTitle.bold())
            
            Button("Start New Chess Game") {
                onStartGame()
            }.buttonStyle(.borderedProminent)
            Button("start New Checkers Game"){
                onStartCheckersGame()
            }.buttonStyle(.borderedProminent)
            Button("Load Game") {
                onLoadGame()
            }.buttonStyle(.borderedProminent)
        }.padding()
    }
}
