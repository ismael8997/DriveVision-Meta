import Foundation
import CoreVideo
import Combine

protocol VisionProcessorProtocol {
    /// Publica los resultados (límites de velocidad, estado del semáforo) después de procesar el frame
    var processingResultPublisher: AnyPublisher<ProcessingResult, Never> { get }
    
    /// Recibe el frame en crudo emitido por la cámara POV (o el mock)
    func processFrame(_ pixelBuffer: CVPixelBuffer)
}
