import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var hasLoadedWords = false
    
    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max.fill") {
                HomeView()
            }
            
            Tab("Cards", systemImage: "rectangle.stack.fill") {
                FlashcardsView()
            }
            
            Tab("Quiz", systemImage: "brain.head.profile") {
                QuizView()
            }
            
            Tab("Words", systemImage: "book.fill") {
                WordListView()
            }
            
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                StatsView()
            }
        }
        .onAppear {
            if !hasLoadedWords {
                WordService.loadInitialWords(into: context)
                hasLoadedWords = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
