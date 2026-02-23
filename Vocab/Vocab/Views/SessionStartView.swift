import SwiftUI
import SwiftData

struct SessionStartView: View {
    @Environment(\.modelContext) private var context
    @Query private var allWords: [Word]
    @Bindable var sessionService: SessionService
    @State private var showWordOfDayDetails = false
    @State private var studyMode: StudyMode = .flashcards

    enum StudyMode: String, CaseIterable {
        case flashcards = "Flashcards"
        case quiz = "Quiz"
    }

    private var hasEverStudied: Bool {
        allWords.contains { $0.timesSeen > 0 }
    }

    private var selectedLanguageName: String {
        sessionService.language == "en" ? "English" : "Lithuanian"
    }

    private var selectedLanguageWords: [Word] {
        allWords
            .filter { $0.language == sessionService.language }
            .sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
    }

    private func wordCount(for language: String) -> Int {
        if language == sessionService.language {
            return selectedLanguageWords.count
        }
        return allWords.lazy.filter { $0.language == language }.count
    }

    private var dailyWord: Word? {
        let words = selectedLanguageWords
        guard !words.isEmpty else { return nil }
        let index = dailySeed(for: sessionService.language) % words.count
        return words[index]
    }

    var body: some View {
        NavigationStack {
            Group {
                switch sessionService.state {
                case .idle:
                    idleView
                case .loading:
                    ProgressView("Loading session…")
                case .active:
                    sessionActiveView
                case .complete:
                    SessionSummaryView(sessionService: sessionService)
                        .onAppear {
                            saveSessionResult()
                        }
                }
            }
            .navigationTitle("Study")
        }
    }

    // MARK: - Idle View (Language Picker)
    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "book.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                if !hasEverStudied {
                    Text("Welcome! 👋")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Pick a language and start your first session")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Start a Session")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Pick a language and begin learning")
                        .foregroundStyle(.secondary)
                }
            }

            // Language picker
            Picker("Language", selection: Binding(
                get: { sessionService.language },
                set: {
                    sessionService.language = $0
                    sessionService.emptyReason = .none
                    showWordOfDayDetails = false
                }
            )) {
                Text("🇬🇧 English").tag("en")
                Text("🇱🇹 Lithuanian").tag("lt")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Study mode picker
            Picker("Mode", selection: $studyMode) {
                ForEach(StudyMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            wordOfTheDayCard

            // Empty state messages
            if wordCount(for: sessionService.language) == 0 {
                emptyLanguageView
            } else if sessionService.emptyReason == .allCaughtUp {
                allCaughtUpView
            }

            Spacer()

            Button {
                sessionService.startSession(language: sessionService.language, context: context)
            } label: {
                Text("Start Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .disabled(wordCount(for: sessionService.language) == 0)

            Spacer()
        }
    }

    // MARK: - Empty Language View
    private var emptyLanguageView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No words available for \(selectedLanguageName) yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Add words in the Words tab to get started")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - All Caught Up View
    private var allCaughtUpView: some View {
        VStack(spacing: 12) {
            Text("You're all caught up! 🎉")
                .font(.headline)

            Text("No words due for review right now.\nCheck back later or try another language.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var wordOfTheDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Word of the Day")
                .font(.headline)

            if let word = dailyWord {
                Text(word.term)
                    .font(.title3)
                    .fontWeight(.semibold)

                if showWordOfDayDetails {
                    if sessionService.language == "lt" {
                        let translation = (word.translation?.isEmpty == false) ? word.translation ?? "" : "No translation available"
                        wordDetailRow(
                            title: "Translation",
                            value: translation
                        )
                    } else {
                        wordDetailRow(
                            title: "Definition",
                            value: word.definition.isEmpty ? "No definition available" : word.definition
                        )
                    }

                    Text(word.example.isEmpty ? "No example available" : "“\(word.example)”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tap to reveal details")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No words available for \(selectedLanguageName) yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            guard dailyWord != nil else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                showWordOfDayDetails.toggle()
            }
        }
    }

    private func dailySeed(for language: String) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: .now)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1
        let languageSeed = language.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (year * 1_000) + dayOfYear + languageSeed
    }

    @ViewBuilder
    private func wordDetailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }

    private func saveSessionResult() {
        guard sessionService.itemsReviewed > 0 else { return }
        let result = QuizResult(
            score: sessionService.correctCount,
            totalQuestions: sessionService.itemsReviewed,
            language: sessionService.language
        )
        context.insert(result)
    }

    // MARK: - Active Session View
    private var sessionActiveView: some View {
        VStack {
            // Progress header
            VStack(spacing: 8) {
                HStack {
                    Text(studyMode == .quiz
                         ? "Quiz · \(sessionService.sessionWords.count) words"
                         : "Question \(sessionService.currentIndex + 1) of \(sessionService.sessionWords.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("End Session") {
                        sessionService.endSession()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
                .padding(.horizontal)

                if studyMode == .flashcards {
                    ProgressView(
                        value: Double(sessionService.currentIndex),
                        total: Double(sessionService.sessionWords.count)
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)

            if studyMode == .quiz {
                QuizView(words: sessionService.sessionWords, onComplete: { _, _ in
                    sessionService.reset()
                })
            } else {
                FlashcardsView(words: sessionService.sessionWords, onAnswer: { correct in
                    sessionService.recordAnswer(correct: correct)
                })
            }
        }
    }
}

#Preview {
    SessionStartView(sessionService: SessionService())
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
