import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}

    func isVoiceAvailable(for language: String) -> Bool {
        let localeMap = ["en": "en-US", "lt": "lt-LT"]
        let locale = localeMap[language] ?? "en-US"
        return AVSpeechSynthesisVoice(language: locale) != nil
    }
    
    func speak(_ text: String, language: String = "en", rate: Float = 0.45) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let localeMap = ["en": "en-US", "lt": "lt-LT"]
        let locale = localeMap[language] ?? "en-US"
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
