import SwiftUI
import SwiftData

@main
struct VocabApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Word.self, QuizResult.self)
        } catch {
            // Migration failed — delete corrupt store and recreate
            print("⚠️ ModelContainer failed: \(error). Deleting store…")
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            for ext in ["default.store", "default.store-wal", "default.store-shm"] {
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent(ext))
            }
            container = try! ModelContainer(for: Word.self, QuizResult.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
