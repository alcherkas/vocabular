import SwiftUI
import SwiftData
import UIKit

struct QuizView: View {
    @Environment(\.modelContext) private var context
    let words: [Word]
    let quizMode: QuizMode?
    var onComplete: ((Int, Int) -> Void)?
    
    @State private var quizWords: [Word] = []
    @State private var currentIndex = 0
    @State private var score = 0
    @State private var options: [String] = []
    @State private var currentQuestion: QuizQuestion?
    @State private var activeMode: QuizMode = .termToDefinition
    @State private var selectedAnswer: String?
    @State private var showResult = false
    @State private var quizCompleted = false
    @State private var questionsPerQuiz = 10
    @State private var sameLanguagePool: [Word] = []
    private let feedbackGenerator = UINotificationFeedbackGenerator()

    init(words: [Word], quizMode: QuizMode? = nil, onComplete: ((Int, Int) -> Void)? = nil) {
        self.words = words
        self.quizMode = quizMode
        self.onComplete = onComplete
    }

    private var sessionLanguageWords: [Word] {
        guard let sessionLanguage = words.first?.language else { return [] }
        return words.filter { $0.language == sessionLanguage }
    }

    private var totalQuestions: Int {
        quizWords.isEmpty ? questionsPerQuiz : quizWords.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if quizCompleted {
                    quizResultView
                } else if quizWords.isEmpty {
                    startQuizView
                } else {
                    questionView
                }
            }
            .padding()
            .navigationTitle("Quiz")
        }
    }
    
    // MARK: - Start Quiz View
    private var startQuizView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("Test Your Vocabulary")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose how many questions")
                    .foregroundStyle(.secondary)
            }
            
            // Question count picker
            Picker("Questions", selection: $questionsPerQuiz) {
                Text("5 Questions").tag(5)
                Text("10 Questions").tag(10)
                Text("20 Questions").tag(20)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                startQuiz()
            } label: {
                Text("Start Quiz")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(sessionLanguageWords.count < 4)
            
            if sessionLanguageWords.count < 4 {
                Text("Need at least 4 words to start a quiz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Question View
    @ViewBuilder
    private var questionView: some View {
        if let currentQuestion {
            let currentWord = quizWords[currentIndex]
            VStack(spacing: 24) {
            // Progress bar and score
            VStack(spacing: 8) {
                HStack {
                    Text("Question \(currentIndex + 1) of \(totalQuestions)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("\(score)")
                            .fontWeight(.bold)
                    }
                }
                
                ProgressView(value: Double(currentIndex), total: Double(totalQuestions))
                    .tint(.accentColor)
            }
            
            Spacer()
            
            // Question
            VStack(spacing: 16) {
                Text(promptTitle(for: activeMode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(currentQuestion.prompt)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                
                if showsSpeaker(for: activeMode) {
                    Button {
                        SpeechService.shared.speak(currentWord.term, language: currentWord.language)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selectAnswer(option)
                    } label: {
                        HStack {
                            Text(option)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if showResult {
                                answerIcon(for: option)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonBackground(for: option))
                        .foregroundStyle(buttonForeground(for: option))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(showResult)
                }
            }
            
            // Next button
            if showResult {
                Button {
                    nextQuestion()
                } label: {
                    Text(currentIndex < totalQuestions - 1 ? "Next Question" : "See Results")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
            }
        } else {
            ProgressView("Preparing question...")
        }
    }
    
    // MARK: - Quiz Result View
    private var quizResultView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Result icon
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: resultIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(resultColor)
            }
            
            // Score display
            VStack(spacing: 8) {
                Text("Quiz Complete!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(score)/\(totalQuestions)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                
                Text(resultMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            // Percentage bar
            VStack(spacing: 4) {
                ProgressView(value: Double(score), total: Double(totalQuestions))
                    .tint(resultColor)
                    .scaleEffect(y: 2)
                
                Text("\(Int(Double(score) / Double(max(totalQuestions, 1)) * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    startQuiz()
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button {
                    resetQuiz()
                } label: {
                    Text("Back to Menu")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Properties
    private var resultColor: Color {
        let percentage = Double(score) / Double(max(totalQuestions, 1))
        switch percentage {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    private var resultIcon: String {
        let percentage = Double(score) / Double(max(totalQuestions, 1))
        switch percentage {
        case 0.8...1.0: return "star.fill"
        case 0.6..<0.8: return "hand.thumbsup.fill"
        case 0.4..<0.6: return "book.fill"
        default: return "arrow.clockwise"
        }
    }
    
    private var resultMessage: String {
        let percentage = Double(score) / Double(max(totalQuestions, 1))
        switch percentage {
        case 0.9...1.0: return "Perfect! You're a vocabulary master! 🎉"
        case 0.8..<0.9: return "Excellent work! Almost perfect! 🌟"
        case 0.7..<0.8: return "Great job! Keep it up! 👏"
        case 0.5..<0.7: return "Good effort! Practice makes perfect 📚"
        default: return "Keep learning! You'll improve! 💪"
        }
    }
    
    // MARK: - Helper Methods
    private func buttonBackground(for option: String) -> Color {
        guard showResult else { return Color(.systemGray6) }
        
        let isCorrect = option == currentQuestion?.correctAnswer
        let isSelected = option == selectedAnswer
        
        if isCorrect { return .green }
        if isSelected && !isCorrect { return .red }
        return Color(.systemGray6)
    }
    
    private func buttonForeground(for option: String) -> Color {
        guard showResult else { return .primary }
        
        let isCorrect = option == currentQuestion?.correctAnswer
        let isSelected = option == selectedAnswer
        
        if isCorrect || isSelected { return .white }
        return .primary
    }
    
    @ViewBuilder
    private func answerIcon(for option: String) -> some View {
        let isCorrect = option == currentQuestion?.correctAnswer
        
        if isCorrect {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
        } else if option == selectedAnswer {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Quiz Logic
    private func startQuiz() {
        guard let sessionLanguage = sessionLanguageWords.first?.language else { return }
        let actualQuestionCount = min(questionsPerQuiz, sessionLanguageWords.count)
        guard actualQuestionCount >= 4 else { return }
        sameLanguagePool = sessionLanguageWords
        quizWords = Array(sessionLanguageWords.shuffled().prefix(actualQuestionCount))
        activeMode = resolvedMode(for: sessionLanguage)
        currentIndex = 0
        score = 0
        quizCompleted = false
        currentQuestion = nil
        generateOptions()
    }
    
    private func generateOptions() {
        guard currentIndex < quizWords.count else { return }

        guard let question = QuizService.generateQuestion(
            for: quizWords[currentIndex],
            mode: activeMode,
            sameLanguageWords: sameLanguagePool
        ) else {
            completeQuiz()
            return
        }

        currentQuestion = question
        options = question.options
        selectedAnswer = nil
        showResult = false
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        showResult = true
        
        let currentWord = quizWords[currentIndex]
        currentWord.timesSeen += 1
        currentWord.lastSeen = .now
        
        let isCorrect = answer == currentQuestion?.correctAnswer
        if isCorrect {
            score += 1
            currentWord.timesCorrect += 1
            feedbackGenerator.notificationOccurred(.success)
        } else {
            feedbackGenerator.notificationOccurred(.error)
        }
        
        let quality = isCorrect ? 4 : 1
        SpacedRepetitionService.nextReview(for: currentWord, quality: quality)
    }
    
    private func nextQuestion() {
        if currentIndex < totalQuestions - 1 {
            currentIndex += 1
            generateOptions()
        } else {
            completeQuiz()
        }
    }
    
    private func completeQuiz() {
        let lang = quizWords.first?.language ?? "en"
        let result = QuizResult(score: score, totalQuestions: totalQuestions, language: lang)
        context.insert(result)
        quizCompleted = true
    }
    
    private func resetQuiz() {
        if let onComplete {
            onComplete(score, totalQuestions)
        } else {
            quizWords = []
            currentQuestion = nil
            quizCompleted = false
        }
    }

    private func resolvedMode(for language: String) -> QuizMode {
        if let quizMode {
            return quizMode
        }

        let toggleKey = "quiz.mode.toggle.\(language)"
        let useAlternate = UserDefaults.standard.bool(forKey: toggleKey)
        UserDefaults.standard.set(!useAlternate, forKey: toggleKey)

        if language == "lt" {
            return useAlternate ? .translationToTerm : .termToTranslation
        }

        return useAlternate ? .definitionToTerm : .termToDefinition
    }

    private func promptTitle(for mode: QuizMode) -> String {
        switch mode {
        case .termToDefinition:
            return "What is the meaning of"
        case .definitionToTerm:
            return "Which word matches this definition?"
        case .termToTranslation:
            return "What is the English translation of"
        case .translationToTerm:
            return "How do you say this in Lithuanian?"
        }
    }

    private func showsSpeaker(for mode: QuizMode) -> Bool {
        switch mode {
        case .termToDefinition, .termToTranslation:
            return true
        case .definitionToTerm, .translationToTerm:
            return false
        }
    }
}

#Preview {
    QuizView(words: [])
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
