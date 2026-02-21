# Build & Test

## Prerequisites

- Xcode 16+ installed
- iOS Simulator available (check with `xcrun simctl list devices`)
- If `xcode-select -p` prints `CommandLineTools` instead of `Xcode.app`, prefix commands with:
  ```bash
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  ```

## Find Available Simulators

```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
```

Pick an available iPhone simulator from the output (e.g. `iPhone 17 Pro`). Simulator names change across Xcode versions — always run this command first instead of hardcoding a device name.

## Task Destination Fallback Policy

If a task or acceptance criteria hardcodes a simulator destination (for example `iPhone 16 Pro`):

1. Run the requested command once as written.
2. If it fails with "Unable to find a device matching the provided destination specifier", rerun using an available simulator from the discovery step above (or `name=Any iOS Simulator Device`).
3. Report both the requested destination and the fallback destination in your task summary/retro.

## Build (compile only)

```bash
# Replace DEVICE with an available simulator name from the step above
xcodebuild build \
  -project Vocab/Vocab.xcodeproj \
  -scheme Vocab \
  -destination 'platform=iOS Simulator,name=DEVICE,OS=latest' \
  | xcpretty || cat
```

## Run Tests

```bash
xcodebuild test \
  -project Vocab/Vocab.xcodeproj \
  -scheme Vocab \
  -destination 'platform=iOS Simulator,name=DEVICE,OS=latest' \
  | xcpretty || cat
```

If `xcpretty` is not installed: omit `| xcpretty || cat` — raw output still works.

## Verify Success

- Build: exit code 0, no `error:` lines in output.
- Tests: `Test Suite ... passed` in output, 0 failures.

## Adding Unit Tests (one-time Xcode setup)

For projects using file-system synchronized groups (objectVersion 77), the test target can be added by editing `project.pbxproj` directly — the Xcode GUI is not required. See the `VocabTests` target in the project file for reference.

**Via Xcode GUI** (alternative):

1. Open `Vocab/Vocab.xcodeproj` in Xcode.
2. `File → New → Target → Unit Testing Bundle`.
3. Name it `VocabTests`, ensure it targets the `Vocab` scheme.
4. Add test files to `Vocab/VocabTests/`.
5. Tests run automatically with the `xcodebuild test` command above.

## Test File Conventions

- Test class name mirrors tested class: `WordServiceTests`, `SpeechServiceTests`.
- One `@testable import Vocab` at the top of each test file.
- Each test method name: `test_<method>_<scenario>` e.g. `test_loadInitialWords_emptyDatabase`.
