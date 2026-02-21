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

    enum EmptyReason {
        case none
        case noWordsForLanguage
        case allCaughtUp
    }

    private(set) var state: State = .idle
    var emptyReason: EmptyReason = .none
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
    static let maxOverdue = 10
    static let maxNew = 5
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
        emptyReason = .none

        let lang = language
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.language == lang },
            sortBy: [SortDescriptor(\Word.term)]
        )

        do {
            let allWords = try context.fetch(descriptor)
            let selected = buildSession(from: allWords)

            if selected.isEmpty {
                emptyReason = allWords.isEmpty ? .noWordsForLanguage : .allCaughtUp
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

    private func buildSession(from allWords: [Word], now: Date = .now) -> [Word] {
        let overdue = allWords
            .filter { $0.nextReview != nil && $0.nextReview! < now }
            .sorted { ($0.nextReview ?? .distantFuture) < ($1.nextReview ?? .distantFuture) }
        let newWords = allWords.filter { $0.nextReview == nil }
        let isZeroHistory = allWords.allSatisfy { $0.nextReview == nil && $0.timesSeen == 0 }

        var selected: [Word] = []
        selected.append(contentsOf: overdue.prefix(Self.maxOverdue))

        let remaining = Self.maxSessionSize - selected.count
        if remaining > 0 {
            let newLimit = isZeroHistory ? remaining : min(remaining, Self.maxNew)
            selected.append(contentsOf: newWords.shuffled().prefix(newLimit))
        }

        return selected.shuffled()
    }

    func recordAnswer(correct: Bool) {
        guard state == .active, currentIndex < sessionWords.count else { return }
        let word = sessionWords[currentIndex]

        word.timesSeen += 1
        word.lastSeen = .now
        if correct {
            word.timesCorrect += 1
        }

        // Update spaced repetition schedule
        let quality = correct ? 4 : 1
        SpacedRepetitionService.nextReview(for: word, quality: quality)

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
        emptyReason = .none
        sessionWords = []
        currentIndex = 0
        results = []
    }
}
