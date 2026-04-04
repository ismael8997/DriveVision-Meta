import Foundation
import Combine
import CoreVideo

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isDeviceConnected: Bool = false
    
    // Estados observables principales
    @Published var currentSpeedLimit: Int? = nil
    @Published var currentSpeed: Int = 0
    @Published var activeTrafficLight: TrafficLightState = .unknown
    @Published var isSpeeding: Bool = false
    
    // Dependencias
    private let metaDeviceService: MetaDeviceProtocol
    private let visionProcessor: VisionProcessorProtocol
    private let locationManager: LocationServiceProtocol
    private let audioAlertManager: AudioAlertManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(metaDeviceService: MetaDeviceProtocol = MetaDeviceService(),
         visionProcessor: VisionProcessorProtocol = VisionProcessor(),
         locationManager: LocationServiceProtocol = LocationManager(),
         audioAlertManager: AudioAlertManager = AudioAlertManager()) {
        
        self.metaDeviceService = metaDeviceService
        self.visionProcessor = visionProcessor
        self.locationManager = locationManager
        self.audioAlertManager = audioAlertManager
        
        setupBindings()
        
        // Iniciamos todos los streams y hardware
        self.locationManager.startUpdatingLocation()
        self.metaDeviceService.connect()
    }
    
    private func setupBindings() {
        // Enlaza el estado de conexión al ViewModel
        metaDeviceService.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$isDeviceConnected)
            
        // -------------------------
        // TUBERÍA 1: VIDEO ---> AI
        // -------------------------
        metaDeviceService.videoFramePublisher
            .sink { [weak self] pixelBuffer in
                self?.visionProcessor.processFrame(pixelBuffer)
            }
            .store(in: &cancellables)
            
        // -------------------------
        // TUBERÍA 2: AI ---> NEGOCIO
        // -------------------------
        visionProcessor.processingResultPublisher
            .receive(on: DispatchQueue.main) // Actualizamos vistas en Main
            .sink { [weak self] result in
                guard let self = self else { return }
                
                // Actualiza UI del HUD
                if let newLimit = result.speedLimit {
                    self.currentSpeedLimit = newLimit
                }
                self.activeTrafficLight = result.trafficLightState
                
                // Valida colisiones lógicas y dispara alertas auditivas
                self.evaluateBusinessLogicAlarms()
            }
            .store(in: &cancellables)
            
        // -------------------------
        // TUBERÍA 3: GPS ---> NEGOCIO
        // -------------------------
        locationManager.speedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speedKmh in
                guard let self = self else { return }
                self.currentSpeed = speedKmh
                self.evaluateBusinessLogicAlarms()
            }
            .store(in: &cancellables)
    }
    
    private func evaluateBusinessLogicAlarms() {
        // 1. Evaluación de exceso de velocidad.
        if let limit = currentSpeedLimit {
            isSpeeding = locationManager.evaluateSpeed(against: limit)
            if isSpeeding {
                audioAlertManager.speakAlert(message: "Atención, exceso de velocidad")
            }
        } else {
            isSpeeding = false
        }
        
        // 2. Evaluación de Semáforo en Rojo
        // Riesgo inminente: El semáforo está rojo y el conductor avanza a más de 10 km/h (No está frenando/detenido).
        if activeTrafficLight == .red && currentSpeed > 10 {
            audioAlertManager.speakAlert(message: "Semáforo en rojo. Frena.")
        }
    }
    
    deinit {
        metaDeviceService.disconnect()
        locationManager.stopUpdatingLocation()
    }
}
