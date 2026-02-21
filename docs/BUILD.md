# Build & Test

## Prerequisites

- Xcode 16+ installed
- iOS Simulator available (check with `xcrun simctl list devices`)

## Find Available Simulators

```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
```

Use an iPhone 16 or later for iOS 26 compatibility.

## Build (compile only)

```bash
xcodebuild build \
  -project Vocab/Vocab.xcodeproj \
  -scheme Vocab \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  | xcpretty || cat
```

## Run Tests

```bash
xcodebuild test \
  -project Vocab/Vocab.xcodeproj \
  -scheme Vocab \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  | xcpretty || cat
```

If `xcpretty` is not installed: omit `| xcpretty || cat` — raw output still works.

## Verify Success

- Build: exit code 0, no `error:` lines in output.
- Tests: `Test Suite ... passed` in output, 0 failures.

## Adding Unit Tests (one-time Xcode setup)

Unit tests require a test target created in Xcode (cannot be done via CLI):

1. Open `Vocab/Vocab.xcodeproj` in Xcode.
2. `File → New → Target → Unit Testing Bundle`.
3. Name it `VocabTests`, ensure it targets the `Vocab` scheme.
4. Add test files to `Vocab/VocabTests/`.
5. Tests run automatically with the `xcodebuild test` command above.

## Test File Conventions

- Test class name mirrors tested class: `WordServiceTests`, `SpeechServiceTests`.
- One `@testable import Vocab` at the top of each test file.
- Each test method name: `test_<method>_<scenario>` e.g. `test_loadInitialWords_emptyDatabase`.
