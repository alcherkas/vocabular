import Foundation
import SwiftData

@MainActor
func run() throws {
    let args = CommandLine.arguments

    func flagValue(_ flag: String) -> String? {
        guard let idx = args.firstIndex(of: flag), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    guard let enPath = flagValue("--en"),
          let ltPath = flagValue("--lt"),
          let outputPath = flagValue("--output") else {
        print("Usage: VocabSeedBuilder --en <path> --lt <path> --output <path>")
        exit(1)
    }

    let outputURL = URL(fileURLWithPath: outputPath)

    // Remove existing store files so we start fresh
    let fm = FileManager.default
    for suffix in ["", "-wal", "-shm"] {
        let file = outputURL.path + suffix
        if fm.fileExists(atPath: file) {
            try fm.removeItem(atPath: file)
        }
    }

    let config = ModelConfiguration(url: outputURL)
    let container = try ModelContainer(for: Word.self, QuizResult.self, configurations: config)
    let context = ModelContext(container)

    var totalEN = 0
    var totalLT = 0
    var nounsWithGender = 0
    var wordsWithCases = 0

    func loadWords(from path: String, language: String) throws -> Int {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let wordDataList = try JSONDecoder().decode([WordData].self, from: data)

        // Only include published words in the seed store
        let publishedWords = wordDataList.filter { $0.status == "published" || $0.status == nil }

        for wd in publishedWords {
            let meanings: [WordMeaning]
            if let decodedMeanings = wd.meanings, !decodedMeanings.isEmpty {
                meanings = decodedMeanings.map {
                    WordMeaning(
                        definition: $0.definition,
                        example: $0.example ?? "",
                        register: $0.register,
                        tags: $0.tags ?? []
                    )
                }
            } else {
                meanings = [
                    WordMeaning(
                        definition: wd.definition ?? "",
                        example: wd.example ?? "",
                        register: nil,
                        tags: wd.tags ?? []
                    )
                ]
            }

            let word = Word(
                term: wd.term,
                definition: wd.definition ?? meanings.first?.definition ?? "",
                synonyms: wd.synonyms ?? [],
                example: wd.example ?? meanings.first?.example ?? "",
                partOfSpeech: wd.partOfSpeech,
                tags: wd.tags ?? [],
                language: language,
                translation: wd.translation,
                meanings: meanings,
                forms: wd.forms,
                governedCase: wd.governedCase,
                gender: wd.gender,
                cases: wd.cases
            )
            context.insert(word)

            if wd.gender != nil { nounsWithGender += 1 }
            if wd.cases != nil { wordsWithCases += 1 }
        }

        return publishedWords.count
    }

    print("Loading EN words from \(enPath)...")
    totalEN = try loadWords(from: enPath, language: "en")

    print("Loading LT words from \(ltPath)...")
    totalLT = try loadWords(from: ltPath, language: "lt")

    try context.save()

    print("")
    print("=== Seed Store Stats ===")
    print("EN words:          \(totalEN)")
    print("LT words:          \(totalLT)")
    print("Total:             \(totalEN + totalLT)")
    print("Nouns with gender: \(nounsWithGender)")
    print("Words with cases:  \(wordsWithCases)")
    print("Output:            \(outputURL.path)")

    let attrs = try fm.attributesOfItem(atPath: outputURL.path)
    if let size = attrs[.size] as? Int {
        let mb = Double(size) / 1_048_576.0
        print("File size:         \(String(format: "%.2f", mb)) MB")
    }
    print("========================")
}

do {
    try run()
} catch {
    print("Error: \(error)")
    exit(1)
}
