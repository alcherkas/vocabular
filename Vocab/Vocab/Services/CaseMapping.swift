import Foundation

/// Lithuanian grammatical cases
enum GrammaticalCase: String, CaseIterable {
    case nominative
    case genitive
    case dative
    case accusative
    case instrumental
    case locative
}

struct CaseMapping {
    let grammaticalCase: GrammaticalCase
    let preposition: String?

    static func from(governedCase: String) -> CaseMapping? {
        switch governedCase {
        case "ką?":
            CaseMapping(grammaticalCase: .accusative, preposition: nil)
        case "ko?":
            CaseMapping(grammaticalCase: .genitive, preposition: nil)
        case "kam?":
            CaseMapping(grammaticalCase: .dative, preposition: nil)
        case "kuo?":
            CaseMapping(grammaticalCase: .instrumental, preposition: nil)
        case "kur?":
            CaseMapping(grammaticalCase: .locative, preposition: nil)
        case "su kuo?":
            CaseMapping(grammaticalCase: .instrumental, preposition: "su")
        case "apie ką?":
            CaseMapping(grammaticalCase: .accusative, preposition: "apie")
        case "į ką?":
            CaseMapping(grammaticalCase: .accusative, preposition: "į")
        case "iš ko?":
            CaseMapping(grammaticalCase: .genitive, preposition: "iš")
        case "nuo ko?":
            CaseMapping(grammaticalCase: .genitive, preposition: "nuo")
        case "dėl ko?":
            CaseMapping(grammaticalCase: .genitive, preposition: "dėl")
        case "prie ko?":
            CaseMapping(grammaticalCase: .genitive, preposition: "prie")
        case "už ko?":
            CaseMapping(grammaticalCase: .genitive, preposition: "už")
        case "kiek?":
            CaseMapping(grammaticalCase: .genitive, preposition: nil)
        default:
            nil
        }
    }
}
