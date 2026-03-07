import Foundation
import SwiftData

@Model
class QuizResult {
    var date: Date
    var score: Int
    var totalQuestions: Int
    var language: String = "en"

    init(date: Date = .now, score: Int, totalQuestions: Int, language: String = "en") {
        self.date = date
        self.score = score
        self.totalQuestions = totalQuestions
        self.language = language
    }
}
