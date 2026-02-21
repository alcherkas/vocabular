import SwiftUI
import SwiftData

struct SessionStartView: View {
    @Environment(\.modelContext) private var context
    @Bindable var sessionService: SessionService

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
                Text("Start a Session")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Pick a language and begin learning")
                    .foregroundStyle(.secondary)
            }

            // Language picker
            Picker("Language", selection: Binding(
                get: { sessionService.language },
                set: { sessionService.language = $0 }
            )) {
                Text("🇬🇧 English").tag("en")
                Text("🇱🇹 Lithuanian").tag("lt")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

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

            Spacer()
        }
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
