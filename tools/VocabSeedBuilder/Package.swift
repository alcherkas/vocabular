// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VocabSeedBuilder",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "VocabSeedBuilder",
            path: "Sources"
        )
    ]
)
