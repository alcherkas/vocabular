import SwiftUI
import SwiftData

struct WordListView: View {
    @Query(sort: \Word.term) private var words: [Word]
    @State private var searchText = ""
    @State private var selectedFilter: WordFilter = .all
    @State private var selectedLanguage: LanguageFilter = .all

    enum LanguageFilter: String, CaseIterable {
        case all = "All"
        case english = "English"
        case lithuanian = "Lithuanian"

        var code: String? {
            switch self {
            case .all: return nil
            case .english: return "en"
            case .lithuanian: return "lt"
            }
        }
    }

    enum WordFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case mastered = "Mastered"
        case learning = "Learning"
    }
    
    var filteredWords: [Word] {
        var result = words
        
        // Apply language filter
        if let code = selectedLanguage.code {
            result = result.filter { $0.language == code }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.term.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .mastered:
            result = result.filter { $0.masteryLevel >= 0.8 }
        case .learning:
            result = result.filter { $0.timesSeen > 0 && $0.masteryLevel < 0.8 }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Language filter
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(LanguageFilter.allCases, id: \.self) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WordFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                count: countFor(filter),
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))
                
                // Word list
                if filteredWords.isEmpty {
                    if let code = selectedLanguage.code, words.filter({ $0.language == code }).isEmpty {
                        ContentUnavailableView(
                            "No \(selectedLanguage.rawValue) Words",
                            systemImage: "tray",
                            description: Text("No words have been loaded for \(selectedLanguage.rawValue) yet.\nWords will appear here once added.")
                        )
                    } else {
                        ContentUnavailableView(
                            "No Words Found",
                            systemImage: "magnifyingglass",
                            description: Text(emptyMessage)
                        )
                    }
                } else {
                    List(filteredWords) { word in
                        NavigationLink {
                            WordDetailView(word: word)
                        } label: {
                            WordRowView(word: word)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Words (\(filteredWords.count))")
            .searchable(text: $searchText, prompt: "Search words or definitions")
        }
    }
    
    private var filterCounts: (favorites: Int, mastered: Int, learning: Int) {
        var favorites = 0, mastered = 0, learning = 0
        for word in words {
            if word.isFavorite { favorites += 1 }
            if word.timesSeen > 0 {
                if word.masteryLevel >= 0.8 { mastered += 1 }
                else { learning += 1 }
            }
        }
        return (favorites, mastered, learning)
    }

    private func countFor(_ filter: WordFilter) -> Int {
        switch filter {
        case .all: return words.count
        case .favorites: return filterCounts.favorites
        case .mastered: return filterCounts.mastered
        case .learning: return filterCounts.learning
        }
    }
    
    private var emptyMessage: String {
        if !searchText.isEmpty {
            return "Try a different search term"
        }
        switch selectedFilter {
        case .favorites: return "Star some words to see them here"
        case .mastered: return "Keep practicing to master words"
        case .learning: return "Take some quizzes to start tracking"
        default: return "No words available"
        }
    }
}

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct WordRowView: View {
    let word: Word
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(word.term)
                        .font(.headline)
                    
                    if word.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    
                    Text(word.partOfSpeech)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                
                Text(word.definition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Mastery indicator
            if word.timesSeen > 0 {
                MasteryBadge(level: word.masteryLevel)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MasteryBadge: View {
    let level: Double
    
    var color: Color {
        switch level {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .blue
        case 0.25..<0.5: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: level)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(level * 100))")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .frame(width: 36, height: 36)
    }
}

struct WordDetailView: View {
    @Bindable var word: Word
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.term)
                            .font(.system(size: 36, weight: .bold, design: .serif))
                        
                        HStack(spacing: 8) {
                            Text(word.partOfSpeech)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                            
                            if word.timesSeen > 0 {
                                Text(word.masteryDescription)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        if SpeechService.shared.isVoiceAvailable(for: word.language) {
                            Button {
                                SpeechService.shared.speak(word.term, language: word.language)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        
                        Button {
                            word.isFavorite.toggle()
                        } label: {
                            Image(systemName: word.isFavorite ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(word.isFavorite ? .yellow : .gray)
                        }
                    }
                }
                
                Divider()
                
                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Label("Definition", systemImage: "text.book.closed")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(word.definition)
                        .font(.body)
                }
                
                // Example
                VStack(alignment: .leading, spacing: 8) {
                    Label("Example", systemImage: "quote.opening")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\u{201C}\(word.example)\u{201D}")
                        .font(.body)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                
                // Synonyms
                if !word.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Synonyms", systemImage: "arrow.triangle.branch")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(word.synonyms, id: \.self) { synonym in
                                Text(synonym)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Progress section
                if word.timesSeen > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Progress", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 24) {
                            StatItem(title: "Seen", value: "\(word.timesSeen)", icon: "eye")
                            StatItem(title: "Correct", value: "\(word.timesCorrect)", icon: "checkmark")
                            StatItem(title: "Accuracy", value: "\(Int(word.masteryLevel * 100))%", icon: "percent")
                        }
                        
                        if let lastSeen = word.lastSeen {
                            Text("Last practiced: \(lastSeen.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .navigationTitle(word.term)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Simple flow layout for synonyms
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    WordListView()
        .modelContainer(for: Word.self, inMemory: true)
}
