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
    
    var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
    }
    
    var isPassing: Bool {
        percentage >= 70
    }
}
