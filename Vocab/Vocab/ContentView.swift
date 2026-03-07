import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var hasLoadedWords = false
    @State private var sessionService = SessionService()
    
    var body: some View {
        TabView {
            Tab("Study", systemImage: "book.circle.fill") {
                SessionStartView(sessionService: sessionService)
            }
            
            Tab("Words", systemImage: "book.fill") {
                WordListView()
            }
            
            Tab("Stats", systemImage: "chart.line.uptrend.xyaxis") {
                StatsView()
            }
        }
        .task {
            if !hasLoadedWords {
                hasLoadedWords = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
