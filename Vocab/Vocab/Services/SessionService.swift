import Foundation
import SwiftData

@Observable
class SessionService {
    enum State {
        case idle
        case loading
        case active
        case complete
    }

    private(set) var state: State = .idle
    private(set) var sessionWords: [Word] = []
    private(set) var currentIndex: Int = 0
    private(set) var results: [(word: Word, correct: Bool)] = []

    var language: String {
        get {
            UserDefaults.standard.string(forKey: "lastUsedLanguage") ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastUsedLanguage")
        }
    }

    // Configurable constants
    static let maxSessionSize = 15

    var itemsReviewed: Int { results.count }
    var correctCount: Int { results.filter(\.correct).count }
    var incorrectCount: Int { results.filter { !$0.correct }.count }

    var currentWord: Word? {
        guard state == .active, currentIndex < sessionWords.count else { return nil }
        return sessionWords[currentIndex]
    }

    func startSession(language: String, context: ModelContext) {
        self.language = language
        state = .loading

        let lang = language
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.language == lang },
            sortBy: [SortDescriptor(\Word.term)]
        )

        do {
            let allWords = try context.fetch(descriptor)
            let selected = Array(allWords.shuffled().prefix(Self.maxSessionSize))

            if selected.isEmpty {
                state = .idle
                return
            }

            sessionWords = selected
            currentIndex = 0
            results = []
            state = .active
        } catch {
            print("SessionService: Error fetching words - \(error)")
            state = .idle
        }
    }

    func recordAnswer(correct: Bool) {
        guard state == .active, currentIndex < sessionWords.count else { return }
        let word = sessionWords[currentIndex]

        word.timesSeen += 1
        word.lastSeen = .now
        if correct {
            word.timesCorrect += 1
        }

        results.append((word: word, correct: correct))

        if currentIndex < sessionWords.count - 1 {
            currentIndex += 1
        } else {
            state = .complete
        }
    }

    func skipWord() {
        guard state == .active, currentIndex < sessionWords.count else { return }
        if currentIndex < sessionWords.count - 1 {
            currentIndex += 1
        } else {
            state = .complete
        }
    }

    func endSession() {
        state = .complete
    }

    func reset() {
        state = .idle
        sessionWords = []
        currentIndex = 0
        results = []
    }
}
