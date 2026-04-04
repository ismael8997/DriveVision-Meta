import Foundation
import AVFoundation

class AudioAlertManager {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenMessage: String?
    private var debounceTimer: Timer?
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // CRÍTICO PARA WEARABLES: ".playback" mantiene el audio activo aún en mute.
            // [.mixWithOthers, .duckOthers] es la magia: baja el volumen de la música/podcast sin pausarlo.
            try audioSession.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.mixWithOthers, .duckOthers]
            )
            try audioSession.setActive(true)
        } catch {
            print("AudioAlertManager: Error crítico configurando AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    func speakAlert(message: String) {
        // Sistema Anti-Spam: Si el sintetizador ya está hablando este exacto mensaje, no lo encolamos.
        // También usamos un simple debounce para que no repita el alert 30 veces por segundo.
        guard lastSpokenMessage != message else { return }
        
        let utterance = AVSpeechUtterance(string: message)
        // Configuramos la voz (español porque la UI y los prompts están en español)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.53 // Velocidad natural del habla
        
        lastSpokenMessage = message
        synthesizer.speak(utterance)
        
        // El bloqueador "lastSpokenMessage" se libera tras 5 segundos.
        // Si sigues haciéndole caso omiso a la alerta, te lo volverá a recordar pasados 5s.
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.lastSpokenMessage = nil
        }
    }
}
