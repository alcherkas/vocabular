import Foundation

struct CaseExercise {
    let verb: Word
    let noun: Word
    let adjective: Word
    let governedCase: String
    let preposition: String?
    let number: String
    let nominativeNoun: String
    let nominativeAdjective: String
    let correctAnswer: String
}

enum CaseTrainingService {

    static func generateExercise(
        verbs: [Word],
        nouns: [Word],
        adjectives: [Word]
    ) -> CaseExercise? {
        let eligibleVerbs = verbs.filter { $0.governedCase != nil }
        let eligibleNouns = nouns.filter { $0.cases != nil }
        let eligibleAdjectives = adjectives.filter { $0.cases != nil }

        guard let verb = eligibleVerbs.randomElement(),
              let governedCaseStr = verb.governedCase,
              let mapping = CaseMapping.from(governedCase: governedCaseStr) else {
            return nil
        }

        guard let noun = eligibleNouns.randomElement(),
              let nounCases = noun.cases else {
            return nil
        }

        let nounGender: NumberCases?
        let genderKey: String
        if let masc = nounCases.masculine {
            nounGender = masc
            genderKey = "masculine"
        } else if let fem = nounCases.feminine {
            nounGender = fem
            genderKey = "feminine"
        } else {
            return nil
        }

        guard let adjective = eligibleAdjectives.randomElement(),
              let adjCases = adjective.cases else {
            return nil
        }

        let adjGender: NumberCases?
        if genderKey == "masculine" {
            adjGender = adjCases.masculine
        } else {
            adjGender = adjCases.feminine
        }
        guard let adjGender else { return nil }

        // Pick singular or plural, falling back if one is nil (pluralia tantum)
        let hasSingular = nounGender!.singular != nil && adjGender.singular != nil
        let hasPlural = nounGender!.plural != nil && adjGender.plural != nil
        guard hasSingular || hasPlural else { return nil }

        let isSingular: Bool
        if hasSingular && hasPlural { isSingular = Bool.random() }
        else { isSingular = hasSingular }

        let number = isSingular ? "singular" : "plural"

        guard let nounNumberCases = isSingular ? nounGender!.singular : nounGender!.plural,
              let adjNumberCases = isSingular ? adjGender.singular : adjGender.plural else {
            return nil
        }

        let declinedNoun = nounNumberCases.value(for: mapping.grammaticalCase)
        let declinedAdj = adjNumberCases.value(for: mapping.grammaticalCase)

        let nominativeNounForm = nounNumberCases.nominative
        let nominativeAdjForm: String
        if genderKey == "masculine" {
            nominativeAdjForm = (isSingular ? adjCases.masculine?.singular : adjCases.masculine?.plural)?.nominative ?? adjective.term
        } else {
            nominativeAdjForm = (isSingular ? adjCases.feminine?.singular : adjCases.feminine?.plural)?.nominative ?? adjective.term
        }

        let correctAnswer = "\(declinedAdj) \(declinedNoun)"

        return CaseExercise(
            verb: verb,
            noun: noun,
            adjective: adjective,
            governedCase: governedCaseStr,
            preposition: mapping.preposition,
            number: number,
            nominativeNoun: nominativeNounForm,
            nominativeAdjective: nominativeAdjForm,
            correctAnswer: correctAnswer
        )
    }
}
