import Foundation
import SwiftData

@Model
class Word {
    var term: String
    var definition: String
    var synonyms: [String]
    var example: String
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

    init(term: String, definition: String, synonyms: [String], example: String, partOfSpeech: String, tags: [String] = [], language: String = "en", translation: String? = nil) {
        self.term = term
        self.definition = definition
        self.synonyms = synonyms
        self.example = example
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
