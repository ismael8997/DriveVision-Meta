import Foundation
import CoreVideo
import Combine

/// Implementación Mock del servicio del dispositivo Meta para el desarrollo
class MetaDeviceService: MetaDeviceProtocol {
    @Published private(set) var isConnected: Bool = false
    var connectionStatePublisher: Published<Bool>.Publisher { $isConnected }
    
    // Sujeto que emitirá los frames de manera constante
    private let videoFrameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    var videoFramePublisher: AnyPublisher<CVPixelBuffer, Never> {
        videoFrameSubject.eraseToAnyPublisher()
    }
    
    private var timer: Timer?
    
    func connect() {
        // Simulamos un retraso en la conexión por Bluetooth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isConnected = true
            self?.startMockVideoStream()
        }
    }
    
    func disconnect() {
        isConnected = false
        stopMockVideoStream()
    }
    
    private func startMockVideoStream() {
        // Cancelamos cualquier timer previo si lo hubiera
        stopMockVideoStream()
        
        // Configuramos la emisión de frames a ~30 FPS (aprox cada 33 ms)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isConnected else { return }
            if let pixelBuffer = self.createMockPixelBuffer() {
                self.videoFrameSubject.send(pixelBuffer)
            }
        }
    }
    
    private func stopMockVideoStream() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopMockVideoStream()
    }
    
    /// Crea un buffer vacío/negro que simula lo recibido por la cámara POV
    private func createMockPixelBuffer() -> CVPixelBuffer? {
        // Resolución simulada
        let width = 640
        let height = 480
        var pixelBuffer: CVPixelBuffer?
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        // Formato 32BGRA es común en flujos de cámara en iOS
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Error creando mock pixel buffer")
            return nil
        }
        
        return buffer
    }
}
