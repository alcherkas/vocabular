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
                let isSeeded = UserDefaults.standard.integer(forKey: "seedDataVersion") > 0
                if !isSeeded {
                    // Legacy path: load from JSON for pre-existing installs
                    WordService.migrateExistingWords(context: context)
                    WordService.loadWords(language: "en", resourceName: "words", into: context)
                    WordService.loadWords(language: "lt", resourceName: "words_lt", into: context)
                    WordService.migrateVerbForms(language: "lt", resourceName: "words_lt", context: context)
                    WordService.migrateCaseForms(language: "lt", resourceName: "words_lt", context: context)
                }
                hasLoadedWords = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
