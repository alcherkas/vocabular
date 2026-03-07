#!/usr/bin/env swift
//
// build_seed_db.swift — Converts production JSON word files into a pre-seeded
// SwiftData-compatible SQLite store for the Vocab app.
//
// Usage:
//   swift scripts/build_seed_db.swift \
//     --en data/words.json \
//     --lt data/words_lt.json \
//     --output Vocab/Vocab/Resources/vocab_seed.store
//
// This script uses the same data structures as the app's Word model to ensure
// schema compatibility. It must be run on macOS with Xcode installed.

import Foundation

// MARK: - Data types (mirrored from Word.swift)

struct MeaningData: Codable {
    let definition: String
    let example: String?
    let register: String?
    let tags: [String]?
}

struct WordForms: Codable {
    var present3: String
    var past3: String
}

struct CaseSet: Codable {
    var nominative: String
    var genitive: String
    var dative: String
    var accusative: String
    var instrumental: String
    var locative: String
    var vocative: String?
}

struct NumberCases: Codable {
    var singular: CaseSet
    var plural: CaseSet
}

struct WordCases: Codable {
    var masculine: NumberCases?
    var feminine: NumberCases?
}

struct WordMeaning: Codable {
    var definition: String
    var example: String
    var register: String?
    var tags: [String]
}

struct WordData: Codable {
    let term: String
    let meanings: [MeaningData]?
    let definition: String?
    let synonyms: [String]?
    let antonymTerms: [String]?
    let relatedTerms: [String]?
    let example: String?
    let partOfSpeech: String
    let tags: [String]?
    let language: String?
    let translation: String?
    let forms: WordForms?
    let governedCase: String?
    let gender: String?
    let cases: WordCases?
}

// MARK: - CLI

func printUsage() {
    print("""
    Usage: swift build_seed_db.swift --en <en.json> --lt <lt.json> --output <path.store>
    
    Converts production JSON word files into pre-seeded data for the Vocab app.
    Outputs a JSON manifest with word counts for verification.
    """)
}

var enPath: String?
var ltPath: String?
var outputPath: String?

var args = CommandLine.arguments.dropFirst()
while let arg = args.first {
    args = args.dropFirst()
    switch arg {
    case "--en":
        enPath = args.first
        args = args.dropFirst()
    case "--lt":
        ltPath = args.first
        args = args.dropFirst()
    case "--output":
        outputPath = args.first
        args = args.dropFirst()
    case "--help", "-h":
        printUsage()
        exit(0)
    default:
        print("Unknown argument: \(arg)")
        printUsage()
        exit(1)
    }
}

guard let enPath, let ltPath, let outputPath else {
    print("Error: --en, --lt, and --output are all required")
    printUsage()
    exit(1)
}

// MARK: - Load JSON

func loadWords(from path: String) -> [WordData] {
    guard let data = FileManager.default.contents(atPath: path) else {
        print("Error: Cannot read file at \(path)")
        exit(1)
    }
    do {
        return try JSONDecoder().decode([WordData].self, from: data)
    } catch {
        print("Error: Cannot parse JSON at \(path): \(error)")
        exit(1)
    }
}

let enWords = loadWords(from: enPath)
let ltWords = loadWords(from: ltPath)

print("Loaded \(enWords.count) EN words, \(ltWords.count) LT words")

// MARK: - Build output manifest

// Since SwiftData's SQLite schema is internal and version-dependent, we cannot
// reliably create a .store file from a script without importing SwiftData.
// Instead, this script validates the JSON and outputs a manifest that the app's
// seed loading can use for verification.
//
// The actual pre-seeded store should be built using an Xcode build phase that
// runs a small Swift target with SwiftData access. This script serves as the
// validation and preparation step.

struct SeedManifest: Codable {
    let version: Int
    let enCount: Int
    let ltCount: Int
    let ltNounsWithGender: Int
    let ltNounsWithCases: Int
    let ltAdjectivesWithCases: Int
    let ltVerbsWithForms: Int
    let generatedAt: String
}

let ltNouns = ltWords.filter { $0.partOfSpeech == "noun" }
let ltNounsWithGender = ltNouns.filter { $0.gender != nil }.count
let ltNounsWithCases = ltNouns.filter { $0.cases != nil }.count
let ltAdjsWithCases = ltWords.filter { $0.partOfSpeech == "adjective" && $0.cases != nil }.count
let ltVerbsWithForms = ltWords.filter { $0.partOfSpeech == "verb" && $0.forms != nil }.count

let formatter = ISO8601DateFormatter()
let manifest = SeedManifest(
    version: 1,
    enCount: enWords.count,
    ltCount: ltWords.count,
    ltNounsWithGender: ltNounsWithGender,
    ltNounsWithCases: ltNounsWithCases,
    ltAdjectivesWithCases: ltAdjsWithCases,
    ltVerbsWithForms: ltVerbsWithForms,
    generatedAt: formatter.string(from: Date())
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let manifestData = try! encoder.encode(manifest)
let manifestPath = outputPath.replacingOccurrences(of: ".store", with: "_manifest.json")
FileManager.default.createFile(atPath: manifestPath, contents: manifestData)

print("""
Seed manifest written to \(manifestPath):
  EN words: \(manifest.enCount)
  LT words: \(manifest.ltCount)
  LT nouns with gender: \(manifest.ltNounsWithGender)
  LT nouns with cases: \(manifest.ltNounsWithCases)
  LT adjectives with cases: \(manifest.ltAdjectivesWithCases)
  LT verbs with forms: \(manifest.ltVerbsWithForms)
  Version: \(manifest.version)

Note: The pre-seeded SwiftData store must be built using an Xcode target
that imports SwiftData. This script validates the data and produces a manifest.
To build the actual store, use the VocabSeedBuilder Xcode target.
""")
