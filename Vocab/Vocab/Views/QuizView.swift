import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    
    @State private var quizWords: [Word] = []
    @State private var currentIndex = 0
    @State private var score = 0
    @State private var options: [String] = []
    @State private var selectedAnswer: String?
    @State private var showResult = false
    @State private var quizCompleted = false
    @State private var questionsPerQuiz = 10
    
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
            .disabled(words.count < 4)
            
            if words.count < 4 {
                Text("Need at least 4 words to start a quiz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Question View
    private var questionView: some View {
        let currentWord = quizWords[currentIndex]
        
        return VStack(spacing: 24) {
            // Progress bar and score
            VStack(spacing: 8) {
                HStack {
                    Text("Question \(currentIndex + 1) of \(questionsPerQuiz)")
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
                
                ProgressView(value: Double(currentIndex), total: Double(questionsPerQuiz))
                    .tint(.accentColor)
            }
            
            Spacer()
            
            // Question
            VStack(spacing: 16) {
                Text("What is the meaning of")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(currentWord.term)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                
                Button {
                    SpeechService.shared.speak(currentWord.term)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
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
                    Text(currentIndex < questionsPerQuiz - 1 ? "Next Question" : "See Results")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
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
                
                Text("\(score)/\(questionsPerQuiz)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                
                Text(resultMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            // Percentage bar
            VStack(spacing: 4) {
                ProgressView(value: Double(score), total: Double(questionsPerQuiz))
                    .tint(resultColor)
                    .scaleEffect(y: 2)
                
                Text("\(Int(Double(score) / Double(questionsPerQuiz) * 100))%")
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
        let percentage = Double(score) / Double(questionsPerQuiz)
        switch percentage {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    private var resultIcon: String {
        let percentage = Double(score) / Double(questionsPerQuiz)
        switch percentage {
        case 0.8...1.0: return "star.fill"
        case 0.6..<0.8: return "hand.thumbsup.fill"
        case 0.4..<0.6: return "book.fill"
        default: return "arrow.clockwise"
        }
    }
    
    private var resultMessage: String {
        let percentage = Double(score) / Double(questionsPerQuiz)
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
        
        let isCorrect = option == quizWords[currentIndex].definition
        let isSelected = option == selectedAnswer
        
        if isCorrect { return .green }
        if isSelected && !isCorrect { return .red }
        return Color(.systemGray6)
    }
    
    private func buttonForeground(for option: String) -> Color {
        guard showResult else { return .primary }
        
        let isCorrect = option == quizWords[currentIndex].definition
        let isSelected = option == selectedAnswer
        
        if isCorrect || isSelected { return .white }
        return .primary
    }
    
    @ViewBuilder
    private func answerIcon(for option: String) -> some View {
        let isCorrect = option == quizWords[currentIndex].definition
        
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
        let actualQuestionCount = min(questionsPerQuiz, words.count)
        quizWords = Array(words.shuffled().prefix(actualQuestionCount))
        currentIndex = 0
        score = 0
        quizCompleted = false
        generateOptions()
    }
    
    private func generateOptions() {
        guard currentIndex < quizWords.count else { return }
        
        let correctAnswer = quizWords[currentIndex].definition
        let wrongAnswers = words
            .filter { $0.term != quizWords[currentIndex].term }
            .shuffled()
            .prefix(3)
            .map { $0.definition }
        
        options = (Array(wrongAnswers) + [correctAnswer]).shuffled()
        selectedAnswer = nil
        showResult = false
    }
    
    private func selectAnswer(_ answer: String) {
        selectedAnswer = answer
        showResult = true
        
        let currentWord = quizWords[currentIndex]
        currentWord.timesSeen += 1
        currentWord.lastSeen = .now
        
        if answer == currentWord.definition {
            score += 1
            currentWord.timesCorrect += 1
        }
    }
    
    private func nextQuestion() {
        if currentIndex < questionsPerQuiz - 1 {
            currentIndex += 1
            generateOptions()
        } else {
            completeQuiz()
        }
    }
    
    private func completeQuiz() {
        let result = QuizResult(score: score, totalQuestions: questionsPerQuiz)
        context.insert(result)
        quizCompleted = true
    }
    
    private func resetQuiz() {
        quizWords = []
        quizCompleted = false
    }
}

#Preview {
    QuizView()
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
