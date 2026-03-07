import Foundation
import SwiftData

struct WordMeaning: Codable {
    var definition: String
    var example: String
    var register: String?
    var tags: [String]
}

struct WordForms: Codable, Equatable {
    var present3: String
    var past3: String
}

struct CaseSet: Codable, Equatable {
    var nominative: String
    var genitive: String
    var dative: String
    var accusative: String
    var instrumental: String
    var locative: String
    var vocative: String?
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

    var language: String = "en"
    var translation: String?
    @Attribute(.unique) var uniqueKey: String
    @Relationship(deleteRule: .nullify) var antonyms: [Word] = []
    @Relationship(deleteRule: .nullify) var relatedWords: [Word] = []

    var nextReview: Date?
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0

    var formsData: Data = Data()
    var governedCase: String?

    var gender: String?
    var casesData: Data = Data()

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
}
