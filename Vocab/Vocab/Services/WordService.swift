import Foundation
import SwiftData

struct MeaningData: Codable {
    let definition: String
    let example: String?
    let register: String?
    let tags: [String]?
}

struct WordData: Codable {
    let term: String
    let meanings: [MeaningData]?
    let definition: String?
    let synonyms: [String]?
    let example: String?
    let partOfSpeech: String
    let tags: [String]?
    let language: String?
    let translation: String?
}

class WordService {

    /// Loads words for a specific language from a bundled JSON file into SwiftData.
    /// Only loads if no words for that language exist yet.
    static func loadWords(language: String, resourceName: String, into context: ModelContext) {
        // Check if words for this language already exist
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.language == language })
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else {
            print("WordService: \(existingCount) \(language) words already loaded")
            return
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            print("WordService: \(resourceName).json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let wordData = try JSONDecoder().decode([WordData].self, from: data)

            for wd in wordData {
                let meanings: [WordMeaning]
                if let decodedMeanings = wd.meanings, !decodedMeanings.isEmpty {
                    meanings = decodedMeanings.map {
                        WordMeaning(
                            definition: $0.definition,
                            example: $0.example ?? "",
                            register: $0.register,
                            tags: $0.tags ?? []
                        )
                    }
                } else {
                    meanings = [
                        WordMeaning(
                            definition: wd.definition ?? "",
                            example: wd.example ?? "",
                            register: nil,
                            tags: wd.tags ?? []
                        )
                    ]
                }

                let word = Word(
                    term: wd.term,
                    definition: wd.definition ?? meanings.first?.definition ?? "",
                    synonyms: wd.synonyms ?? [],
                    example: wd.example ?? meanings.first?.example ?? "",
                    partOfSpeech: wd.partOfSpeech,
                    tags: wd.tags ?? [],
                    language: language,
                    translation: wd.translation,
                    meanings: meanings
                )
                context.insert(word)
            }

            print("WordService: Loaded \(wordData.count) \(language) words")
        } catch {
            print("WordService: Error loading \(language) words - \(error)")
        }
    }

    /// Backwards-compatible entry point: loads English words from words.json
    static func loadInitialWords(into context: ModelContext) {
        loadWords(language: "en", resourceName: "words", into: context)
    }

    /// Populates uniqueKey for any existing words that have an empty key (migration).
    static func migrateExistingWords(context: ModelContext) {
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.uniqueKey == "" })
        if let words = try? context.fetch(descriptor) {
            for word in words {
                word.uniqueKey = "\(word.language):\(word.term)"
            }
            if !words.isEmpty {
                print("WordService: Migrated uniqueKey for \(words.count) words")
            }
        }
    }
}
