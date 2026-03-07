import Foundation

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
    let translation: String?
    let forms: WordForms?
    let governedCase: String?
    let gender: String?
    let cases: WordCases?
    let status: String?
}
