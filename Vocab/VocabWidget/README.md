# Vocab WidgetKit Extension

This directory contains source files for a `Word of the Day` WidgetKit extension.

## Files
- `VocabWidget.swift`: widget entry, timeline provider, data loading, and views.
- `VocabWidgetBundle.swift`: widget bundle entry point.

## Manual Xcode setup (required)
The CLI cannot update `Vocab.xcodeproj` target settings automatically, so finish setup in Xcode:

1. Open `Vocab/Vocab.xcodeproj` in Xcode.
2. **File → New → Target… → Widget Extension**.
3. Name it `VocabWidgetExtension` (or similar) and choose SwiftUI lifecycle.
4. Replace generated widget files with:
   - `Vocab/VocabWidget/VocabWidget.swift`
   - `Vocab/VocabWidget/VocabWidgetBundle.swift`
5. Add `Vocab/Vocab/Resources/words.json` to the widget target's **Target Membership** (or provide shared app-group data only).
6. In **Signing & Capabilities**, add **App Groups** to both app + widget targets and set a shared group ID.
7. Update `WordWidgetStore.suiteName` in `VocabWidget.swift` to the real app group (currently `group.com.example.vocabular`).
8. If the app writes daily data to shared defaults, store JSON under key `wordOfTheDay` using the `WordWidgetData` shape.
9. Build and run the widget extension scheme, then add the widget on the Home Screen.

## Data sources
The widget reads data in this order:
1. Shared `UserDefaults(suiteName:)` key `wordOfTheDay`.
2. Bundled `words.json` fallback.
3. Hardcoded sample fallback.

Timeline updates are scheduled daily at midnight.
