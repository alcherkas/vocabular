import WidgetKit
import SwiftUI

struct WordWidgetEntry: TimelineEntry {
    let date: Date
    let word: WordWidgetData
}

struct WordWidgetData: Codable {
    let term: String
    let partOfSpeech: String
    let definition: String
    let example: String

    static let fallback = WordWidgetData(
        term: "Serendipity",
        partOfSpeech: "noun",
        definition: "The chance occurrence of events in a happy or beneficial way.",
        example: "Meeting her at that cafe was pure serendipity."
    )
}

struct VocabWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordWidgetEntry {
        WordWidgetEntry(date: Date(), word: .fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (WordWidgetEntry) -> Void) {
        completion(WordWidgetEntry(date: Date(), word: WordWidgetStore.word(for: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordWidgetEntry>) -> Void) {
        let now = Date()
        let entry = WordWidgetEntry(date: now, word: WordWidgetStore.word(for: now))
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) ?? Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)

        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

enum WordWidgetStore {
    static let suiteName = "group.com.example.vocabular"
    static let sharedWordKey = "wordOfTheDay"

    static func word(for date: Date) -> WordWidgetData {
        if let sharedWord = loadSharedWord() {
            return sharedWord
        }

        let bundledWords = loadBundledWords()
        guard !bundledWords.isEmpty else { return .fallback }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = dayOfYear % bundledWords.count
        return bundledWords[index]
    }

    private static func loadSharedWord() -> WordWidgetData? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: sharedWordKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(WordWidgetData.self, from: data)
    }

    private static func loadBundledWords() -> [WordWidgetData] {
        guard
            let url = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let words = try? JSONDecoder().decode([BundledWord].self, from: data)
        else {
            return []
        }

        return words.map {
            WordWidgetData(
                term: $0.term,
                partOfSpeech: $0.partOfSpeech,
                definition: $0.definition ?? $0.meanings?.first?.definition ?? "",
                example: $0.example ?? $0.meanings?.first?.example ?? ""
            )
        }
    }
}

private struct BundledWord: Decodable {
    let term: String
    let meanings: [BundledMeaning]?
    let definition: String?
    let example: String?
    let partOfSpeech: String
}

private struct BundledMeaning: Decodable {
    let definition: String
    let example: String?
}

struct VocabWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: VocabWidgetProvider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Word of the Day")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.word.term)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(2)
            Text(entry.word.partOfSpeech)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Word of the Day")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.word.term)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(entry.word.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(entry.word.definition)
                .font(.subheadline)
                .lineLimit(3)
            if !entry.word.example.isEmpty {
                Text("“\(entry.word.example)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct VocabWidget: Widget {
    let kind: String = "VocabWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VocabWidgetProvider()) { entry in
            VocabWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Word of the Day")
        .description("Shows today's word and definition.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
