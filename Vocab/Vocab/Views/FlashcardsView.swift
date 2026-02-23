import SwiftUI
import SwiftData

struct FlashcardsView: View {
    let words: [Word]
    var onAnswer: ((Bool) -> Void)?

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var offset: CGSize = .zero
    @State private var showFavoritesOnly = false
    
    private var displayedWords: [Word] {
        let filtered = showFavoritesOnly ? words.filter { $0.isFavorite } : words
        // Surface overdue / never-reviewed words first
        let now = Date.now
        return filtered.sorted { a, b in
            let aDue = a.nextReview == nil || a.nextReview! < now
            let bDue = b.nextReview == nil || b.nextReview! < now
            if aDue != bDue { return aDue }
            return (a.nextReview ?? .distantPast) < (b.nextReview ?? .distantPast)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if displayedWords.isEmpty {
                    ContentUnavailableView(
                        showFavoritesOnly ? "No Favorites" : "No Words",
                        systemImage: showFavoritesOnly ? "star.slash" : "rectangle.stack.badge.plus",
                        description: Text(showFavoritesOnly ? "Star some words to see them here" : "Add words to start learning")
                    )
                } else {
                    // Card stack
                    ZStack {
                        ForEach(visibleIndices, id: \.self) { index in
                            FlashcardView(
                                word: displayedWords[index],
                                isFlipped: index == currentIndex ? isFlipped : false
                            )
                            .offset(index == currentIndex ? offset : .zero)
                            .scaleEffect(cardScale(for: index))
                            .opacity(cardOpacity(for: index))
                            .zIndex(index == currentIndex ? 1 : 0)
                            .gesture(index == currentIndex ? dragGesture : nil)
                            .onTapGesture {
                                if index == currentIndex {
                                    withAnimation(.spring(duration: 0.4)) {
                                        isFlipped.toggle()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Navigation controls
                    VStack(spacing: 16) {
                        // Progress indicator
                        ProgressView(value: Double(currentIndex + 1), total: Double(displayedWords.count))
                            .padding(.horizontal, 40)

                        // Know / Don't Know buttons (session mode)
                        if onAnswer != nil && isFlipped {
                            HStack(spacing: 20) {
                                Button {
                                    onAnswer?(false)
                                } label: {
                                    Label("Don't Know", systemImage: "xmark.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .controlSize(.large)

                                Button {
                                    onAnswer?(true)
                                } label: {
                                    Label("Know It", systemImage: "checkmark.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                                .controlSize(.large)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Navigation buttons
                        HStack(spacing: 60) {
                            Button {
                                previousCard()
                            } label: {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(currentIndex == 0 ? .gray : .accentColor)
                            }
                            .disabled(currentIndex == 0)
                            
                            Text("\(currentIndex + 1) / \(displayedWords.count)")
                                .font(.headline)
                                .monospacedDigit()
                                .frame(minWidth: 80)
                            
                            Button {
                                nextCard()
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(currentIndex >= displayedWords.count - 1 ? .gray : .accentColor)
                            }
                            .disabled(currentIndex >= displayedWords.count - 1)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Flashcards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                        currentIndex = 0
                        isFlipped = false
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(showFavoritesOnly ? .yellow : .gray)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        shuffleCards()
                    } label: {
                        Image(systemName: "shuffle")
                    }
                }
            }
        }
    }
    
    private var visibleIndices: [Int] {
        let indices = [currentIndex - 1, currentIndex, currentIndex + 1]
        return indices.filter { $0 >= 0 && $0 < displayedWords.count }
    }
    
    private func cardScale(for index: Int) -> CGFloat {
        if index == currentIndex { return 1.0 }
        return 0.92
    }
    
    private func cardOpacity(for index: Int) -> Double {
        if index == currentIndex { return 1.0 }
        return 0.5
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                withAnimation(.spring(duration: 0.3)) {
                    if value.translation.width < -100 {
                        nextCard()
                    } else if value.translation.width > 100 {
                        previousCard()
                    }
                    offset = .zero
                }
            }
    }
    
    private func nextCard() {
        guard currentIndex < displayedWords.count - 1 else { return }
        isFlipped = false
        currentIndex += 1
    }
    
    private func previousCard() {
        guard currentIndex > 0 else { return }
        isFlipped = false
        currentIndex -= 1
    }
    
    private func shuffleCards() {
        currentIndex = Int.random(in: 0..<max(displayedWords.count, 1))
        isFlipped = false
    }
}

struct FlashcardView: View {
    let word: Word
    let isFlipped: Bool
    
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 24)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 2)
            
            // Card content
            if isFlipped {
                // Back of card - definition
                VStack(spacing: 20) {
                    if word.language == "lt", let translation = word.translation, !translation.isEmpty {
                        Text(translation)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }

                    Text(word.definition)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                        .padding(.horizontal, 40)
                    
                    Text("\u{201C}\(word.example)\u{201D}")
                        .font(.body)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !word.synonyms.isEmpty {
                        Text(word.synonyms.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(28)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // Front of card - word
                VStack(spacing: 12) {
                    if word.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.title3)
                    }
                    
                    Text(word.term)
                        .font(.system(size: 38, weight: .bold, design: .serif))
                    
                    Text(word.partOfSpeech)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                    
                    Text("Tap to flip")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 20)
                }
            }
        }
        .frame(width: 320, height: 440)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
    }
}

#Preview {
    FlashcardsView(words: [])
        .modelContainer(for: Word.self, inMemory: true)
}
