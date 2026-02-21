import Foundation
import SwiftData

struct WordMeaning: Codable {
    var definition: String
    var example: String
    var register: String?
    var tags: [String]
}

@Model
class Word {
    var term: String
    var meaningsData: Data
    var synonyms: [String]
    var partOfSpeech: String
    var tags: [String] = []
    var isFavorite: Bool = false
    var timesCorrect: Int = 0
    var timesSeen: Int = 0
    var lastSeen: Date?

    // Language support
    var language: String = "en"
    var translation: String?
    @Attribute(.unique) var uniqueKey: String

    // Spaced repetition (SM-2)
    var nextReview: Date?
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0

    var meanings: [WordMeaning] {
        get {
            guard !meaningsData.isEmpty,
                  let decoded = try? JSONDecoder().decode([WordMeaning].self, from: meaningsData) else {
                return []
            }
            return decoded
        }
        set {
            meaningsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var definition: String {
        get { meanings.first?.definition ?? "" }
        set {
            var currentMeanings = meanings
            if currentMeanings.isEmpty {
                currentMeanings = [WordMeaning(definition: newValue, example: "", register: nil, tags: [])]
            } else {
                currentMeanings[0].definition = newValue
            }
            meanings = currentMeanings
        }
    }

    var example: String {
        get { meanings.first?.example ?? "" }
        set {
            var currentMeanings = meanings
            if currentMeanings.isEmpty {
                currentMeanings = [WordMeaning(definition: "", example: newValue, register: nil, tags: [])]
            } else {
                currentMeanings[0].example = newValue
            }
            meanings = currentMeanings
        }
    }

    init(term: String, definition: String, synonyms: [String], example: String, partOfSpeech: String, tags: [String] = [], language: String = "en", translation: String? = nil, meanings: [WordMeaning]? = nil) {
        self.term = term
        let resolvedMeanings = meanings ?? [WordMeaning(definition: definition, example: example, register: nil, tags: tags)]
        let persistedMeanings = resolvedMeanings.isEmpty ? [WordMeaning(definition: definition, example: example, register: nil, tags: tags)] : resolvedMeanings
        self.meaningsData = (try? JSONEncoder().encode(persistedMeanings)) ?? Data()
        self.synonyms = synonyms
        self.partOfSpeech = partOfSpeech
        self.tags = tags
        self.language = language
        self.translation = translation
        self.uniqueKey = "\(language):\(term)"
    }
    
    var masteryLevel: Double {
        guard timesSeen > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesSeen)
    }
    
    var masteryDescription: String {
        switch masteryLevel {
        case 0.8...1.0: return "Mastered"
        case 0.6..<0.8: return "Familiar"
        case 0.3..<0.6: return "Learning"
        default: return "New"
        }
    }
}
