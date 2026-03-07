import Foundation
import SwiftData

struct WordMeaning: Codable {
    var definition: String
    var example: String
    var register: String?
    var tags: [String]
}

struct WordForms: Codable, Equatable {
    var present3: String   // 3rd person present (e.g., "eina")
    var past3: String      // 3rd person past (e.g., "ėjo")
}

struct CaseSet: Codable, Equatable {
    var nominative: String
    var genitive: String
    var dative: String
    var accusative: String
    var instrumental: String
    var locative: String
    var vocative: String?
    
    func value(for grammaticalCase: GrammaticalCase) -> String {
        switch grammaticalCase {
        case .nominative: nominative
        case .genitive: genitive
        case .dative: dative
        case .accusative: accusative
        case .instrumental: instrumental
        case .locative: locative
        }
    }
}

struct NumberCases: Codable, Equatable {
    var singular: CaseSet?
    var plural: CaseSet?
}

struct WordCases: Codable, Equatable {
    var masculine: NumberCases?
    var feminine: NumberCases?
}

@Model
class Word {
    var term: String
    var meaningsData: Data = Data()
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
    @Relationship(deleteRule: .nullify) var antonyms: [Word] = []
    @Relationship(deleteRule: .nullify) var relatedWords: [Word] = []

    // Spaced repetition (SM-2)
    var nextReview: Date?
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0

    // Verb grammar (LT verbs: 3 principal forms + governed case)
    var formsData: Data = Data()
    var governedCase: String?

    // Noun/adjective grammar (LT: gender + declension cases)
    var gender: String?
    var casesData: Data = Data()

    @Transient private var _cachedMeanings: [WordMeaning]?

    var meanings: [WordMeaning] {
        get {
            if let cached = _cachedMeanings { return cached }
            guard !meaningsData.isEmpty,
                  let decoded = try? JSONDecoder().decode([WordMeaning].self, from: meaningsData) else {
                return []
            }
            _cachedMeanings = decoded
            return decoded
        }
        set {
            meaningsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            _cachedMeanings = newValue
        }
    }

    var forms: WordForms? {
        get {
            guard !formsData.isEmpty else { return nil }
            return try? JSONDecoder().decode(WordForms.self, from: formsData)
        }
        set {
            formsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var cases: WordCases? {
        get {
            guard !casesData.isEmpty else { return nil }
            return try? JSONDecoder().decode(WordCases.self, from: casesData)
        }
        set {
            casesData = (try? JSONEncoder().encode(newValue)) ?? Data()
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

    init(term: String, definition: String, synonyms: [String], example: String, partOfSpeech: String, tags: [String] = [], language: String = "en", translation: String? = nil, meanings: [WordMeaning]? = nil, forms: WordForms? = nil, governedCase: String? = nil, gender: String? = nil, cases: WordCases? = nil) {
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
        self.formsData = (try? JSONEncoder().encode(forms)) ?? Data()
        self.governedCase = governedCase
        self.gender = gender
        self.casesData = (try? JSONEncoder().encode(cases)) ?? Data()
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
