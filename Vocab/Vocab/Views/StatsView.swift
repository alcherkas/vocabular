import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \QuizResult.date, order: .reverse) private var results: [QuizResult]
    @Query private var words: [Word]
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

    private var filteredWords: [Word] {
        guard let code = selectedLanguage.code else { return words }
        return words.filter { $0.language == code }
    }

    private var filteredResults: [QuizResult] {
        guard let code = selectedLanguage.code else { return results }
        return results.filter { $0.language == code }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Language filter
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(LanguageFilter.allCases, id: \.self) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)

                    if filteredWords.isEmpty && filteredResults.isEmpty {
                        noStatsView
                    } else {
                        // Overview cards
                        overviewSection

                        // Streak section
                        if !filteredResults.isEmpty {
                            streakSection
                        }
                        
                        // Mastery breakdown
                        if !filteredWords.isEmpty {
                            masterySection
                        }
                        
                        // Quiz history chart
                        if !filteredResults.isEmpty {
                            chartSection
                        }
                        
                        // Recent quizzes
                        if !filteredResults.isEmpty {
                            recentQuizzesSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - No Stats View
    private var noStatsView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No stats yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete a study session to see your progress for \(selectedLanguage.rawValue).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            HStack(spacing: 12) {
                OverviewCard(
                    title: "Total Words",
                    value: "\(filteredWords.count)",
                    icon: "book.fill",
                    color: .blue
                )
                
                OverviewCard(
                    title: "Mastered",
                    value: "\(masteredCount)",
                    icon: "star.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                OverviewCard(
                    title: "Quizzes Taken",
                    value: "\(filteredResults.count)",
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                OverviewCard(
                    title: "Avg. Score",
                    value: averageScore,
                    icon: "percent",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        HStack(spacing: 12) {
            OverviewCard(
                title: "Current Streak",
                value: "\(currentStreak) day\(currentStreak == 1 ? "" : "s")",
                icon: "flame.fill",
                color: .red
            )

            OverviewCard(
                title: "Days Practiced",
                value: "\(daysPracticed)",
                icon: "calendar",
                color: .teal
            )
        }
    }
    
    // MARK: - Mastery Section
    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mastery Breakdown")
                .font(.headline)
            
            VStack(spacing: 16) {
                MasteryRow(label: "Mastered", count: masteredCount, total: filteredWords.count, color: .green)
                MasteryRow(label: "Familiar", count: familiarCount, total: filteredWords.count, color: .blue)
                MasteryRow(label: "Learning", count: learningCount, total: filteredWords.count, color: .orange)
                MasteryRow(label: "New", count: newCount, total: filteredWords.count, color: .gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Performance")
                .font(.headline)
            
            Chart(recentResults) { result in
                BarMark(
                    x: .value("Date", result.date, unit: .day),
                    y: .value("Score", result.percentage)
                )
                .foregroundStyle(result.isPassing ? Color.green.gradient : Color.orange.gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 50, 100]) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Recent Quizzes Section
    private var recentQuizzesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiz History")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(Array(filteredResults.prefix(10).enumerated()), id: \.element.id) { index, result in
                    if index > 0 {
                        Divider()
                    }
                    QuizHistoryRow(result: result)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Computed Properties
    private var masteryCounts: (mastered: Int, familiar: Int, learning: Int, new: Int) {
        var mastered = 0, familiar = 0, learning = 0, new = 0
        for word in filteredWords {
            if word.timesSeen == 0 { new += 1 }
            else if word.masteryLevel >= 0.8 { mastered += 1 }
            else if word.masteryLevel >= 0.6 { familiar += 1 }
            else { learning += 1 }
        }
        return (mastered, familiar, learning, new)
    }

    private var masteredCount: Int { masteryCounts.mastered }
    private var familiarCount: Int { masteryCounts.familiar }
    private var learningCount: Int { masteryCounts.learning }
    private var newCount: Int { masteryCounts.new }
    
    private var averageScore: String {
        guard !filteredResults.isEmpty else { return "—" }
        let avg = filteredResults.map { $0.percentage }.reduce(0, +) / Double(filteredResults.count)
        return "\(Int(avg))%"
    }

    private var daysPracticed: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(filteredResults.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(filteredResults.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)
        guard let latest = uniqueDays.first else { return 0 }

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard latest == today || latest == yesterday else { return 0 }

        var streak = 1
        for i in 1..<uniqueDays.count {
            let expected = calendar.date(byAdding: .day, value: -1, to: uniqueDays[i - 1])!
            if uniqueDays[i] == expected {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    private var recentResults: [QuizResult] {
        Array(filteredResults.prefix(14).reversed())
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MasteryRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

struct QuizHistoryRow: View {
    let result: QuizResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(result.score)/\(result.totalQuestions) correct")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(result.percentage))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(result.isPassing ? .green : .orange)
        }
        .padding()
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [Word.self, QuizResult.self], inMemory: true)
}
