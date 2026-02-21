import Foundation
import SwiftData

struct WordData: Codable {
    let term: String
    let definition: String
    let synonyms: [String]
    let example: String
    let partOfSpeech: String
    let tags: [String]
}

class WordService {
    
    /// Loads initial words from bundled JSON file into SwiftData
    /// Only loads if database is empty (first launch)
    static func loadInitialWords(into context: ModelContext) {
        // Check if words already exist
        let descriptor = FetchDescriptor<Word>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else {
            print("WordService: \(existingCount) words already loaded")
            return
        }
        
        // Load from bundled JSON
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            print("WordService: words.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let wordData = try JSONDecoder().decode([WordData].self, from: data)
            
            for wd in wordData {
                let word = Word(
                    term: wd.term,
                    definition: wd.definition,
                    synonyms: wd.synonyms,
                    example: wd.example,
                    partOfSpeech: wd.partOfSpeech,
                    tags: wd.tags
                )
                context.insert(word)
            }
            
            print("WordService: Loaded \(wordData.count) words")
        } catch {
            print("WordService: Error loading words - \(error)")
        }
    }
}
