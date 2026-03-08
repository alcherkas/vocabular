import SwiftUI
import SwiftData
import UIKit

struct CaseTrainingView: View {
    @Environment(\.modelContext) private var context
    let words: [Word]
    var learnerLanguage: String = "en"
    var onComplete: ((Int, Int) -> Void)?

    @State private var currentExercise: CaseExercise?
    @State private var score = 0
    @State private var userAnswer = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var trainingCompleted = false
    @State private var questionsAnswered = 0
    @FocusState private var isInputFocused: Bool
    private let feedbackGenerator = UINotificationFeedbackGenerator()

    private var verbs: [Word] {
        words.filter { $0.partOfSpeech == "verb" && $0.governedCase != nil }
    }

    private var nouns: [Word] {
        words.filter { $0.partOfSpeech == "noun" && $0.cases != nil }
    }

    private var adjectives: [Word] {
        words.filter { $0.partOfSpeech == "adjective" && $0.cases != nil }
    }

    private var hasEnoughData: Bool {
        !verbs.isEmpty && !nouns.isEmpty && !adjectives.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if trainingCompleted {
                    resultView
                } else if currentExercise == nil {
                    startView
                } else {
                    exerciseView
                }
            }
            .padding()
            .navigationTitle("Linksniai")
            .toolbar {
                if currentExercise != nil && !trainingCompleted {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Finish") { completeTraining() }
                    }
                }
            }
        }
    }

    // MARK: - Start View
    private var startView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "textformat.abc")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Noun Case Training")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Decline adjective + noun to match the verb's case")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                startTraining()
            } label: {
                Text("Start Training")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!hasEnoughData)

            if !hasEnoughData {
                Text("Need verbs, nouns, and adjectives with case data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Exercise View
    @ViewBuilder
    private var exerciseView: some View {
        if let exercise = currentExercise {
            VStack(spacing: 24) {
                // Score
                HStack {
                    Text("Question \(questionsAnswered + 1)")
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

                Spacer()

                // Verb prompt
                VStack(spacing: 12) {
                    Text(exercise.verb.term)
                        .font(.system(size: 34, weight: .bold, design: .serif))

                    // Verb translation hint
                    if let verbTranslation = exercise.verb.translation(for: learnerLanguage), !verbTranslation.isEmpty {
                        Text(verbTranslation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Governed case hint
                    Text(exercise.governedCase)
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())

                    // Preposition if any
                    if let preposition = exercise.preposition {
                        Text(preposition)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }

                // Nominative form + number
                VStack(spacing: 8) {
                    Text("\(exercise.nominativeAdjective) \(exercise.nominativeNoun)")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text(exercise.number == "singular" ? "vienaskaita" : "daugiskaita")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(exercise.number == "singular" ? Color.purple : Color.indigo)
                        .clipShape(Capsule())
                }

                Spacer()

                // Input + feedback
                VStack(spacing: 12) {
                    TextField("Type declined form…", text: $userAnswer)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isInputFocused)
                        .disabled(showResult)
                        .onSubmit { checkAnswer() }

                    if showResult {
                        HStack(spacing: 8) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isCorrect ? .green : .red)
                            if isCorrect {
                                Text("Correct!")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            } else {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Correct answer:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(exercise.correctAnswer)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if showResult {
                        Button {
                            nextExercise()
                        } label: {
                            Text("Next Question")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        Button {
                            checkAnswer()
                        } label: {
                            Text("Check")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Result View
    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                Image(systemName: resultIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(resultColor)
            }

            VStack(spacing: 8) {
                Text("Training Complete!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(score)/\(questionsAnswered)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))

                Text(resultMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                ProgressView(value: Double(score), total: Double(questionsAnswered))
                    .tint(resultColor)
                    .scaleEffect(y: 2)
                Text("\(Int(Double(score) / Double(max(questionsAnswered, 1)) * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    startTraining()
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    resetTraining()
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

    // MARK: - Helpers
    private var resultColor: Color {
        let pct = Double(score) / Double(max(questionsAnswered, 1))
        switch pct {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }

    private var resultIcon: String {
        let pct = Double(score) / Double(max(questionsAnswered, 1))
        switch pct {
        case 0.8...1.0: return "star.fill"
        case 0.6..<0.8: return "hand.thumbsup.fill"
        case 0.4..<0.6: return "book.fill"
        default: return "arrow.clockwise"
        }
    }

    private var resultMessage: String {
        let pct = Double(score) / Double(max(questionsAnswered, 1))
        switch pct {
        case 0.9...1.0: return "Perfect! Grammar master! 🎉"
        case 0.8..<0.9: return "Excellent case knowledge! 🌟"
        case 0.7..<0.8: return "Great progress! 👏"
        case 0.5..<0.7: return "Keep practicing! 📚"
        default: return "Cases are tricky — keep going! 💪"
        }
    }

    // MARK: - Logic
    private func startTraining() {
        guard let exercise = CaseTrainingService.generateExercise(
            verbs: verbs, nouns: nouns, adjectives: adjectives
        ) else { return }
        currentExercise = exercise
        questionsAnswered = 0
        score = 0
        userAnswer = ""
        showResult = false
        trainingCompleted = false
        isInputFocused = true
    }

    private func checkAnswer() {
        guard let exercise = currentExercise else { return }
        let trimmed = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        isCorrect = trimmed == exercise.correctAnswer.lowercased()

        if isCorrect {
            score += 1
            feedbackGenerator.notificationOccurred(.success)
        } else {
            feedbackGenerator.notificationOccurred(.error)
        }

        let noun = exercise.noun
        noun.timesSeen += 1
        noun.lastSeen = .now
        if isCorrect {
            noun.timesCorrect += 1
        }
        SpacedRepetitionService.nextReview(for: noun, quality: isCorrect ? 4 : 1)

        questionsAnswered += 1
        showResult = true
        isInputFocused = false
    }

    private func nextExercise() {
        guard let exercise = CaseTrainingService.generateExercise(
            verbs: verbs, nouns: nouns, adjectives: adjectives
        ) else { return }
        currentExercise = exercise
        userAnswer = ""
        showResult = false
        isInputFocused = true
    }

    private func completeTraining() {
        let result = QuizResult(score: score, totalQuestions: questionsAnswered, language: "lt")
        context.insert(result)
        trainingCompleted = true
    }

    private func resetTraining() {
        if let onComplete {
            onComplete(score, questionsAnswered)
        } else {
            currentExercise = nil
            trainingCompleted = false
            questionsAnswered = 0
        }
    }
}

#Preview {
    CaseTrainingView(words: [])
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
