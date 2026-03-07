import Testing
import SwiftData
import Foundation
@testable import Vocab

@MainActor
struct WordServiceTests {

    /// Creates an in-memory ModelContainer for isolated testing.
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Word.self, configurations: config)
    }

    @Test func test_loadInitialWords_emptyDatabase() throws {
        // The app now uses a pre-seeded SwiftData store instead of JSON loading.
        // Verify that the seed store exists in the bundle.
        let seedURL = Bundle.main.url(forResource: "vocab_seed", withExtension: "store")
        #expect(seedURL != nil, "Expected vocab_seed.store to be bundled")
    }

    @Test func test_loadInitialWords_alreadyLoaded() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Verify that calling loadInitialWords on an empty DB with no JSON is safe
        WordService.loadInitialWords(into: context)
        let count = try context.fetchCount(FetchDescriptor<Word>())
        // No JSON in bundle → no words loaded, but no crash either
        #expect(count == 0, "No JSON in bundle, so no words should be loaded")
    }
}
