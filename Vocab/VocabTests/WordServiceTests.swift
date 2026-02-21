import Testing
import SwiftData
@testable import Vocab

@MainActor
struct WordServiceTests {

    /// Creates an in-memory ModelContainer for isolated testing.
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Word.self, configurations: config)
    }

    @Test func test_loadInitialWords_emptyDatabase() throws {
        let container = try makeContainer()
        let context = container.mainContext

        WordService.loadInitialWords(into: context)

        let descriptor = FetchDescriptor<Word>()
        let words = try context.fetch(descriptor)

        #expect(words.isEmpty == false, "Expected words to be inserted into an empty database")
    }

    @Test func test_loadInitialWords_alreadyLoaded() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // First load
        WordService.loadInitialWords(into: context)
        let firstCount = try context.fetchCount(FetchDescriptor<Word>())

        // Second load — should not duplicate
        WordService.loadInitialWords(into: context)
        let secondCount = try context.fetchCount(FetchDescriptor<Word>())

        #expect(firstCount == secondCount, "Second load should not insert duplicates (first: \(firstCount), second: \(secondCount))")
    }
}
