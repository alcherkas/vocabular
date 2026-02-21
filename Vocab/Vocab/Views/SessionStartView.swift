import SwiftUI
import SwiftData

struct SessionStartView: View {
    @Environment(\.modelContext) private var context
    @Query private var allWords: [Word]
    @Bindable var sessionService: SessionService

    private var hasEverStudied: Bool {
        allWords.contains { $0.timesSeen > 0 }
    }

    private func wordCount(for language: String) -> Int {
        allWords.filter { $0.language == language }.count
    }

    private var selectedLanguageName: String {
        sessionService.language == "en" ? "English" : "Lithuanian"
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
                }
            )) {
                Text("🇬🇧 English").tag("en")
                Text("🇱🇹 Lithuanian").tag("lt")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

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

    // MARK: - Active Session View
    private var sessionActiveView: some View {
        VStack {
            // Progress header
            VStack(spacing: 8) {
                HStack {
                    Text("Question \(sessionService.currentIndex + 1) of \(sessionService.sessionWords.count)")
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

                ProgressView(
                    value: Double(sessionService.currentIndex),
                    total: Double(sessionService.sessionWords.count)
                )
                .padding(.horizontal)
            }
            .padding(.top, 8)

            FlashcardsView(words: sessionService.sessionWords, onAnswer: { correct in
                sessionService.recordAnswer(correct: correct)
            })
        }
    }
}

#Preview {
    SessionStartView(sessionService: SessionService())
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
