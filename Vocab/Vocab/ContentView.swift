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
        .onAppear {
            if !hasLoadedWords {
                // Debug: list all JSON files in the bundle
                let jsonFiles = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
                print("📦 Bundle JSON files (\(jsonFiles.count)): \(jsonFiles.map { $0.lastPathComponent })")
                print("📦 Bundle path: \(Bundle.main.bundlePath)")

                WordService.migrateExistingWords(context: context)
                WordService.loadWords(language: "en", resourceName: "words", into: context)
                WordService.loadWords(language: "lt", resourceName: "words_lt", into: context)
                hasLoadedWords = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
