import Foundation

/// SM-2 spaced repetition algorithm.
struct SpacedRepetitionService {

    /// Updates the word's SR fields and returns the computed next review date.
    /// - Parameters:
    ///   - word: The word to reschedule.
    ///   - quality: Response quality 0–5 (0–2 = fail, 3 = hard, 4 = good, 5 = easy).
    /// - Returns: The next review date.
    @discardableResult
    static func nextReview(for word: Word, quality: Int) -> Date {
        let q = min(max(quality, 0), 5)

        if q >= 3 {
            switch word.repetitions {
            case 0: word.interval = 1
            case 1: word.interval = 6
            default: word.interval = max(1, Int(Double(word.interval) * word.easeFactor))
            }
            word.repetitions += 1
        } else {
            word.repetitions = 0
            word.interval = 1
        }

        let qd = Double(q)
        word.easeFactor = max(1.3, word.easeFactor + 0.1 - (5.0 - qd) * (0.08 + (5.0 - qd) * 0.02))

        let reviewDate = Calendar.current.date(byAdding: .day, value: word.interval, to: .now) ?? .now
        word.nextReview = reviewDate
        return reviewDate
    }
}
