import SwiftUI
import SwiftData

@main
struct VocabApp: App {
    private static let currentSeedVersion = 2

    let container: ModelContainer

    init() {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let storeURL = appSupport.appendingPathComponent("default.store")
            let installedVersion = UserDefaults.standard.integer(forKey: "seedDataVersion")

            // Copy bundled seed store on first launch or when seed version changes
            if !FileManager.default.fileExists(atPath: storeURL.path) || installedVersion < Self.currentSeedVersion {
                try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
                // Remove old store files
                for ext in ["default.store", "default.store-wal", "default.store-shm"] {
                    try? FileManager.default.removeItem(at: appSupport.appendingPathComponent(ext))
                }
                if let seedURL = Bundle.main.url(forResource: "vocab_seed", withExtension: "store") {
                    try FileManager.default.copyItem(at: seedURL, to: storeURL)
                }
                UserDefaults.standard.set(Self.currentSeedVersion, forKey: "seedDataVersion")
            }

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
