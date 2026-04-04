import Foundation
import CoreVideo
import Vision
import Combine

class VisionProcessor: VisionProcessorProtocol {
    
    private let resultSubject = PassthroughSubject<ProcessingResult, Never>()
    var processingResultPublisher: AnyPublisher<ProcessingResult, Never> {
        resultSubject.eraseToAnyPublisher()
    }
    
    // Cola dedicada al procesamiento paralelo de visión (Garantiza que no bloqueamos el UI Thread)
    private let processingQueue = DispatchQueue(label: "com.drivesight.vision.processing", qos: .userInitiated)
    
    // MARK: - CoreML Models
    
    // [PLACEHOLDER - CORE ML]: Aquí instanciaríamos el modelo CoreML de semáforos.
    // Idealmente importando el modelo entrenado con CreateML o YOLOv8 mapeado a formato .mlmodel
    // e.g., private let trafficLightModel = try? VNCoreMLModel(for: TrafficLightDetector(configuration: MLModelConfiguration()).model)
    private var dummyTrafficLightModel: VNCoreMLModel?
    
    // MARK: - Process
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // Forzamos el salto inmediato a un background thread
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            self.performVisionRequests(on: pixelBuffer)
        }
    }
    
    private func performVisionRequests(on pixelBuffer: CVPixelBuffer) {
        // Instanciamos el Manejador de la imagen proporcionada.
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        var detectedSpeedLimit: Int? = nil
        var currentTrafficLightState: TrafficLightState = .unknown
        
        // ----------------------------------------------------
        // 1. OCR: Detección de Límites de Velocidad (VNRecognizeTextRequest)
        // ----------------------------------------------------
        let textRequest = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("Error en Vision OCR: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            // Buscamos sobre las cadenas de texto detectadas
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                let recognizedString = topCandidate.string // Ej: "Maximun Speed 80"
                
                if let speed = self?.extractSpeedNumber(from: recognizedString) {
                    detectedSpeedLimit = speed
                    // En caso de que se lean múltiples números, podemos agarrar el primero y continuar
                    break
                }
            }
        }
        
        // Optimizaciones de rendimiento (baja latencia para video)
        textRequest.recognitionLevel = .fast // "fast" prioriza velocidad sobre precisión exacta (requerido para video).
        textRequest.usesLanguageCorrection = false
        // Opcional: Ayudar a que la IA priorice números 
        // textRequest.customWords = ["20", "30", "40", "50", "60", "70", "80", "90", "100", "110", "120"]
        
        // ----------------------------------------------------
        // 2. Detección de Objetos: Semáforos (VNCoreMLRequest)
        // ----------------------------------------------------
        var requests: [VNRequest] = [textRequest]
        
        if let dummyModel = dummyTrafficLightModel {
            let objectRecognitionRequest = VNCoreMLRequest(model: dummyModel) { request, error in
                guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                
                // Aquí iteraríamos resultados y extraeríamos el label detectado con mayor `confidence`.
                // Por ejemplo: si `label == "RedLight"`, currentTrafficLightState = .red
            }
            objectRecognitionRequest.imageCropAndScaleOption = .scaleFill
            requests.append(objectRecognitionRequest)
        } else {
            // Simulamos que el semáforo está `unknown` al no haber un modelo para evaluar la imagen
            currentTrafficLightState = .unknown
        }
        
        // ----------------------------------------------------
        // EJECUCIÓN SÍNCRONA EN BACKGROUND QUEUE
        // ----------------------------------------------------
        do {
            try requestHandler.perform(requests)
            
            // Creamos resultado empaquetado final
            let result = ProcessingResult(
                speedLimit: detectedSpeedLimit,
                trafficLightState: currentTrafficLightState,
                timestamp: Date()
            )
            
            // Emitimos asincrónicamente de forma segura en el Hilo Principal
            DispatchQueue.main.async { [weak self] in
                self?.resultSubject.send(result)
            }
            
        } catch {
            print("Fallo en la ejecución de procesamiento visual: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func extractSpeedNumber(from text: String) -> Int? {
        // Utilizamos expresión regular para obtener grupos de dígitos. (\b\d+\b).
        // e.g. "80", "MAXIMUM 120" -> "120", "ZONA ESCOLAR 30" -> "30"
        let textAsNSString = text as NSString
        let range = NSRange(location: 0, length: textAsNSString.length)
        let regex = try? NSRegularExpression(pattern: "\\b\\d+\\b")
        
        guard let matches = regex?.matches(in: text, range: range),
              let firstMatch = matches.first else {
            return nil
        }
        
        let matchString = textAsNSString.substring(with: firstMatch.range)
        guard let parsedNumber = Int(matchString) else { return nil }
        
        // Validación de cordura (sanity check) para señales viales
        // Filtra cualquier lectura basura que no represente números lógicos de velocidad
        if parsedNumber >= 5 && parsedNumber <= 150 && parsedNumber % 5 == 0 {
            return parsedNumber
        }
        
        return nil
    }
}
