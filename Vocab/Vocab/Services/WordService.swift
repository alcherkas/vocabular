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
    let antonymTerms: [String]?
    let relatedTerms: [String]?
    let example: String?
    let partOfSpeech: String
    let tags: [String]?
    let language: String?
    let translations: [String: String]?
    let forms: WordForms?
    let governedCase: String?
    let gender: String?
    let cases: WordCases?
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

        // Try standard bundle lookup first, then search all bundle paths
        var url = Bundle.main.url(forResource: resourceName, withExtension: "json")
        if url == nil {
            // Fallback: search in all .json files in the bundle
            let allJSON = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
            print("WordService: Bundle contains \(allJSON.count) JSON files: \(allJSON.map { $0.lastPathComponent })")
            url = allJSON.first { $0.lastPathComponent == "\(resourceName).json" }
        }

        guard let url else {
            print("WordService: \(resourceName).json not found in bundle")
            print("WordService: Bundle path = \(Bundle.main.bundlePath)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let wordData = try JSONDecoder().decode([WordData].self, from: data)
            var insertedByTerm: [String: Word] = [:]
            var pendingRelations: [(word: Word, antonymTerms: [String], relatedTerms: [String])] = []

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
                    translations: wd.translations,
                    meanings: meanings,
                    forms: wd.forms,
                    governedCase: wd.governedCase,
                    gender: wd.gender,
                    cases: wd.cases
                )
                context.insert(word)
                insertedByTerm[wd.term] = word
                pendingRelations.append((word, wd.antonymTerms ?? [], wd.relatedTerms ?? []))
            }

            for relation in pendingRelations {
                relation.word.antonyms = relation.antonymTerms.compactMap { insertedByTerm[$0] }
                relation.word.relatedWords = relation.relatedTerms.compactMap { insertedByTerm[$0] }
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

    /// Backfills verb forms and governedCase from bundled JSON for existing words missing them.
    static func migrateVerbForms(language: String, resourceName: String, context: ModelContext) {
        let emptyData = Data()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate {
            $0.language == language && $0.formsData == emptyData
        })
        guard let words = try? context.fetch(descriptor), !words.isEmpty else { return }

        // Build lookup from JSON
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonWords = try? JSONDecoder().decode([WordData].self, from: data) else { return }

        var formsLookup: [String: (WordForms, String?)] = [:]
        for wd in jsonWords {
            if let forms = wd.forms {
                formsLookup[wd.term] = (forms, wd.governedCase)
            }
        }

        var updated = 0
        for word in words {
            if let (forms, govCase) = formsLookup[word.term] {
                word.forms = forms
                word.governedCase = govCase
                updated += 1
            }
        }
        if updated > 0 {
            print("WordService: Migrated verb forms for \(updated) \(language) words")
        }
    }

    /// Backfills gender and case forms from bundled JSON for existing words missing them.
    static func migrateCaseForms(language: String, resourceName: String, context: ModelContext) {
        let emptyData = Data()
        let descriptor = FetchDescriptor<Word>(predicate: #Predicate {
            $0.language == language && $0.casesData == emptyData
        })
        guard let words = try? context.fetch(descriptor), !words.isEmpty else { return }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonWords = try? JSONDecoder().decode([WordData].self, from: data) else { return }

        var casesLookup: [String: (String?, WordCases?)] = [:]
        for wd in jsonWords {
            if wd.gender != nil || wd.cases != nil {
                casesLookup[wd.term] = (wd.gender, wd.cases)
            }
        }

        var updated = 0
        for word in words {
            if let (gender, cases) = casesLookup[word.term] {
                if let gender { word.gender = gender }
                if let cases { word.cases = cases }
                updated += 1
            }
        }
        if updated > 0 {
            print("WordService: Migrated case forms for \(updated) \(language) words")
        }
    }
}
