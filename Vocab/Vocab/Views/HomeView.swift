import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    @State private var wordOfTheDay: Word?
    @State private var showDefinition = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let word = wordOfTheDay {
                    Spacer()
                    
                    // Word display
                    VStack(spacing: 12) {
                        Text(word.term)
                            .font(.system(size: 42, weight: .bold, design: .serif))
                        
                        Text(word.partOfSpeech)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    
                    // Speak button
                    Button {
                        SpeechService.shared.speak(word.term)
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Listen")
                        }
                        .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    
                    // Definition section
                    if showDefinition {
                        VStack(spacing: 16) {
                            Text(word.definition)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("\u{201C}\(word.example)\u{201D}")
                                .font(.body)
                                .italic()
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if !word.synonyms.isEmpty {
                                HStack {
                                    Text("Synonyms:")
                                        .fontWeight(.medium)
                                    Text(word.synonyms.joined(separator: ", "))
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                showDefinition.toggle()
                            }
                        } label: {
                            Text(showDefinition ? "Hide Definition" : "Reveal Definition")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        if showDefinition {
                            Button {
                                word.isFavorite.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: word.isFavorite ? "star.fill" : "star")
                                    Text(word.isFavorite ? "Favorited" : "Add to Favorites")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(word.isFavorite ? .yellow : .gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                } else {
                    ContentUnavailableView(
                        "Loading...",
                        systemImage: "book.closed",
                        description: Text("Preparing your word of the day")
                    )
                }
            }
            .navigationTitle("Word of the Day")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectRandomWord()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if wordOfTheDay == nil {
                    loadWordOfTheDay()
                }
            }
        }
    }
    
    private func loadWordOfTheDay() {
        guard !words.isEmpty else { return }
        
        // Use day of year to get consistent word for the day
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1
        let index = dayOfYear % words.count
        wordOfTheDay = words[index]
        showDefinition = false
    }
    
    private func selectRandomWord() {
        guard !words.isEmpty else { return }
        wordOfTheDay = words.randomElement()
        showDefinition = false
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Word.self, inMemory: true)
}
