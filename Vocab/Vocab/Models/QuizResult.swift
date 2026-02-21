import Foundation
import SwiftData

@Model
class QuizResult {
    var date: Date
    var score: Int
    var totalQuestions: Int
    
    init(date: Date = .now, score: Int, totalQuestions: Int) {
        self.date = date
        self.score = score
        self.totalQuestions = totalQuestions
    }
    
    var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions) * 100
    }
    
    var isPassing: Bool {
        percentage >= 70
    }
}
