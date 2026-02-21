import SwiftUI
import SwiftData

@main
struct VocabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Word.self, QuizResult.self])
    }
}
