import Foundation

enum QuizMode {
    case termToDefinition
    case definitionToTerm
    case termToTranslation
    case translationToTerm
}

struct QuizQuestion {
    let prompt: String
    let correctAnswer: String
    let options: [String]
    let sourceWord: Word
}

enum QuizService {
    /// Generates a question using a pre-filtered pool of same-language words (preferred for batch quiz generation).
    static func generateQuestion(for word: Word, mode: QuizMode, sameLanguageWords: [Word], learnerLanguage: String = "en") -> QuizQuestion? {
        guard sameLanguageWords.count >= 4 else { return nil }

        let prompt: String
        let correctAnswer: String
        let answerValue: (Word) -> String?

        switch mode {
        case .termToDefinition:
            prompt = word.term
            correctAnswer = word.definition
            answerValue = { $0.definition }
        case .definitionToTerm:
            prompt = word.definition
            correctAnswer = word.term
            answerValue = { $0.term }
        case .termToTranslation:
            guard let translation = word.translation(for: learnerLanguage), !translation.isEmpty else { return nil }
            prompt = word.term
            correctAnswer = translation
            answerValue = { $0.translation(for: learnerLanguage) }
        case .translationToTerm:
            guard let translation = word.translation(for: learnerLanguage), !translation.isEmpty else { return nil }
            prompt = translation
            correctAnswer = word.term
            answerValue = { $0.term }
        }

        let distractorPool = sameLanguageWords
            .filter { $0.uniqueKey != word.uniqueKey }
            .compactMap(answerValue)
            .filter { !$0.isEmpty && $0 != correctAnswer }

        let uniqueDistractors = Array(Set(distractorPool)).shuffled()
        guard uniqueDistractors.count >= 3 else { return nil }

        let options = (Array(uniqueDistractors.prefix(3)) + [correctAnswer]).shuffled()
        return QuizQuestion(prompt: prompt, correctAnswer: correctAnswer, options: options, sourceWord: word)
    }

    static func generateQuestion(for word: Word, mode: QuizMode, allWords: [Word], learnerLanguage: String = "en") -> QuizQuestion? {
        let sameLanguageWords = allWords.filter { $0.language == word.language }
        return generateQuestion(for: word, mode: mode, sameLanguageWords: sameLanguageWords, learnerLanguage: learnerLanguage)
    }
}
