import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \QuizResult.date, order: .reverse) private var allResults: [QuizResult]
    @Query private var allWords: [Word]
    @State private var selectedLanguage: String = "all"
    
    private var words: [Word] {
        if selectedLanguage == "all" { return allWords }
        return allWords.filter { $0.language == selectedLanguage }
    }
    
    private var results: [QuizResult] {
        if selectedLanguage == "all" { return allResults }
        return allResults.filter { $0.language == selectedLanguage }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Language picker
                    languagePicker
                    
                    // Overview cards
                    overviewSection
                    
                    // Mastery breakdown
                    if !words.isEmpty {
                        masterySection
                    }
                    
                    // Quiz history chart
                    if !results.isEmpty {
                        chartSection
                    }
                    
                    // Recent quizzes
                    if !results.isEmpty {
                        recentQuizzesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Language Picker
    private var languagePicker: some View {
        Picker("Language", selection: $selectedLanguage) {
            Text("All").tag("all")
            Text("English").tag("en")
            Text("Lithuanian").tag("lt")
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            HStack(spacing: 12) {
                OverviewCard(
                    title: "Total Words",
                    value: "\(words.count)",
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
                    value: "\(results.count)",
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
    
    // MARK: - Mastery Section
    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mastery Breakdown")
                .font(.headline)
            
            VStack(spacing: 16) {
                MasteryRow(label: "Mastered", count: masteredCount, total: words.count, color: .green)
                MasteryRow(label: "Familiar", count: familiarCount, total: words.count, color: .blue)
                MasteryRow(label: "Learning", count: learningCount, total: words.count, color: .orange)
                MasteryRow(label: "New", count: newCount, total: words.count, color: .gray)
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
                ForEach(Array(results.prefix(10).enumerated()), id: \.element.id) { index, result in
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
    private var masteredCount: Int {
        words.filter { $0.masteryLevel >= 0.8 }.count
    }
    
    private var familiarCount: Int {
        words.filter { $0.masteryLevel >= 0.6 && $0.masteryLevel < 0.8 }.count
    }
    
    private var learningCount: Int {
        words.filter { $0.masteryLevel > 0 && $0.masteryLevel < 0.6 }.count
    }
    
    private var newCount: Int {
        words.filter { $0.timesSeen == 0 }.count
    }
    
    private var averageScore: String {
        guard !results.isEmpty else { return "—" }
        let avg = results.map { $0.percentage }.reduce(0, +) / Double(results.count)
        return "\(Int(avg))%"
    }
    
    private var recentResults: [QuizResult] {
        Array(results.prefix(14).reversed())
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
