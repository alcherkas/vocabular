import Testing
import SwiftData
@testable import Vocab

@MainActor
struct CaseTrainingTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Word.self, configurations: config)
    }

    private func makeNounCases() -> WordCases {
        WordCases(
            masculine: NumberCases(
                singular: CaseSet(nominative: "brolis", genitive: "brolio", dative: "broliui", accusative: "brolį", instrumental: "broliu", locative: "brolyje", vocative: "broli"),
                plural: CaseSet(nominative: "broliai", genitive: "brolių", dative: "broliams", accusative: "brolius", instrumental: "broliais", locative: "broliuose", vocative: "broliai")
            ),
            feminine: nil
        )
    }

    private func makeAdjectiveCases() -> WordCases {
        WordCases(
            masculine: NumberCases(
                singular: CaseSet(nominative: "didelis", genitive: "didelio", dative: "dideliam", accusative: "didelį", instrumental: "dideliu", locative: "dideliame", vocative: "didelis"),
                plural: CaseSet(nominative: "dideli", genitive: "didelių", dative: "dideliems", accusative: "didelius", instrumental: "dideliais", locative: "dideliuose", vocative: "dideli")
            ),
            feminine: NumberCases(
                singular: CaseSet(nominative: "didelė", genitive: "didelės", dative: "didelei", accusative: "didelę", instrumental: "didele", locative: "didelėje", vocative: "didele"),
                plural: CaseSet(nominative: "didelės", genitive: "didelių", dative: "didelėms", accusative: "dideles", instrumental: "didelėmis", locative: "didelėse", vocative: "didelės")
            )
        )
    }

    // MARK: - CaseMapping Tests

    @Test func test_caseMappingAccusative() {
        let mapping = CaseMapping.from(governedCase: "ką?")
        #expect(mapping != nil)
        #expect(mapping?.grammaticalCase == .accusative)
        #expect(mapping?.preposition == nil)
    }

    @Test func test_caseMappingGenitive() {
        let mapping = CaseMapping.from(governedCase: "ko?")
        #expect(mapping != nil)
        #expect(mapping?.grammaticalCase == .genitive)
        #expect(mapping?.preposition == nil)
    }

    @Test func test_caseMappingDative() {
        let mapping = CaseMapping.from(governedCase: "kam?")
        #expect(mapping != nil)
        #expect(mapping?.grammaticalCase == .dative)
        #expect(mapping?.preposition == nil)
    }

    @Test func test_caseMappingInstrumental() {
        let mapping = CaseMapping.from(governedCase: "kuo?")
        #expect(mapping != nil)
        #expect(mapping?.grammaticalCase == .instrumental)
        #expect(mapping?.preposition == nil)
    }

    @Test func test_caseMappingLocative() {
        let mapping = CaseMapping.from(governedCase: "kur?")
        #expect(mapping != nil)
        #expect(mapping?.grammaticalCase == .locative)
        #expect(mapping?.preposition == nil)
    }

    @Test func test_caseMappingWithPreposition() {
        let suKuo = CaseMapping.from(governedCase: "su kuo?")
        #expect(suKuo?.grammaticalCase == .instrumental)
        #expect(suKuo?.preposition == "su")

        let iKa = CaseMapping.from(governedCase: "į ką?")
        #expect(iKa?.grammaticalCase == .accusative)
        #expect(iKa?.preposition == "į")

        let apieKa = CaseMapping.from(governedCase: "apie ką?")
        #expect(apieKa?.grammaticalCase == .accusative)
        #expect(apieKa?.preposition == "apie")
    }

    @Test func test_caseMappingAllGenitive() {
        let genitiveInputs = ["iš ko?", "nuo ko?", "dėl ko?", "prie ko?", "už ko?", "kiek?"]
        for input in genitiveInputs {
            let mapping = CaseMapping.from(governedCase: input)
            #expect(mapping != nil, "Expected mapping for \"\(input)\"")
            #expect(mapping?.grammaticalCase == .genitive, "Expected .genitive for \"\(input)\"")
        }
    }

    @Test func test_caseMappingUnknown() {
        #expect(CaseMapping.from(governedCase: "xyz?") == nil)
        #expect(CaseMapping.from(governedCase: "") == nil)
        #expect(CaseMapping.from(governedCase: "who?") == nil)
    }

    // MARK: - CaseTrainingService Tests

    @Test func test_generateExerciseWithValidData() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let verb = Word(term: "matyti", definition: "to see", synonyms: [], example: "", partOfSpeech: "verb", language: "lt", governedCase: "ką?")
        context.insert(verb)

        let noun = Word(term: "brolis", definition: "brother", synonyms: [], example: "", partOfSpeech: "noun", language: "lt", gender: "masculine", cases: makeNounCases())
        context.insert(noun)

        let adjective = Word(term: "didelis", definition: "big", synonyms: [], example: "", partOfSpeech: "adjective", language: "lt", cases: makeAdjectiveCases())
        context.insert(adjective)

        let exercise = CaseTrainingService.generateExercise(
            verbs: [verb],
            nouns: [noun],
            adjectives: [adjective]
        )

        #expect(exercise != nil)
        #expect(exercise?.governedCase == "ką?")
        #expect(exercise?.preposition == nil)

        let validAnswers = ["didelį brolį", "didelius brolius"]
        #expect(validAnswers.contains(exercise!.correctAnswer),
                "Expected accusative form, got \"\(exercise!.correctAnswer)\"")

        if exercise!.number == "singular" {
            #expect(exercise!.nominativeNoun == "brolis")
            #expect(exercise!.nominativeAdjective == "didelis")
            #expect(exercise!.correctAnswer == "didelį brolį")
        } else {
            #expect(exercise!.nominativeNoun == "broliai")
            #expect(exercise!.nominativeAdjective == "dideli")
            #expect(exercise!.correctAnswer == "didelius brolius")
        }
    }

    @Test func test_generateExerciseNoVerbs() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let noun = Word(term: "brolis", definition: "brother", synonyms: [], example: "", partOfSpeech: "noun", language: "lt", gender: "masculine", cases: makeNounCases())
        context.insert(noun)

        let adjective = Word(term: "didelis", definition: "big", synonyms: [], example: "", partOfSpeech: "adjective", language: "lt", cases: makeAdjectiveCases())
        context.insert(adjective)

        let exercise = CaseTrainingService.generateExercise(
            verbs: [],
            nouns: [noun],
            adjectives: [adjective]
        )
        #expect(exercise == nil)
    }

    @Test func test_generateExerciseNoNounsWithCases() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let verb = Word(term: "matyti", definition: "to see", synonyms: [], example: "", partOfSpeech: "verb", language: "lt", governedCase: "ką?")
        context.insert(verb)

        let nounWithoutCases = Word(term: "brolis", definition: "brother", synonyms: [], example: "", partOfSpeech: "noun", language: "lt")
        context.insert(nounWithoutCases)

        let adjective = Word(term: "didelis", definition: "big", synonyms: [], example: "", partOfSpeech: "adjective", language: "lt", cases: makeAdjectiveCases())
        context.insert(adjective)

        let exercise = CaseTrainingService.generateExercise(
            verbs: [verb],
            nouns: [nounWithoutCases],
            adjectives: [adjective]
        )
        #expect(exercise == nil)
    }

    @Test func test_generateExerciseNoAdjectivesWithCases() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let verb = Word(term: "matyti", definition: "to see", synonyms: [], example: "", partOfSpeech: "verb", language: "lt", governedCase: "ką?")
        context.insert(verb)

        let noun = Word(term: "brolis", definition: "brother", synonyms: [], example: "", partOfSpeech: "noun", language: "lt", gender: "masculine", cases: makeNounCases())
        context.insert(noun)

        let adjWithoutCases = Word(term: "didelis", definition: "big", synonyms: [], example: "", partOfSpeech: "adjective", language: "lt")
        context.insert(adjWithoutCases)

        let exercise = CaseTrainingService.generateExercise(
            verbs: [verb],
            nouns: [noun],
            adjectives: [adjWithoutCases]
        )
        #expect(exercise == nil)
    }
}
