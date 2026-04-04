import Foundation
import Combine

protocol LocationServiceProtocol: ObservableObject {
    /// Publica actualizaciones de la velocidad para la UI
    var speedPublisher: AnyPublisher<Int, Never> { get }
    
    /// Velocidad actual en Kilómetros por Hora
    var currentSpeedKmh: Int { get }
    
    func startUpdatingLocation()
    
    func stopUpdatingLocation()
    
    /// Evalúa si la velocidad actual es mayor al límite provisto con su margen de tolerancia
    func evaluateSpeed(against limit: Int) -> Bool
}
