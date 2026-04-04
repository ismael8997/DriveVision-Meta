import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    
    // @Published permite que la interfaz de SwiftUI se actualice instantáneamente a los cambios
    @Published private(set) var currentSpeedKmh: Int = 0
    
    var speedPublisher: AnyPublisher<Int, Never> {
        $currentSpeedKmh.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        // Alta precisión requerida para que el cálculo de velocidad sea fidedigno
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    func startUpdatingLocation() {
        // Manejo de la solicitud de permisos vital para CoreLocation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Evalúa la velocidad contra el límite detectado por Visión.
    /// Devuelve true si la velocidad es estrictamente mayor al (límite + 5 km/h).
    public func evaluateSpeed(against limit: Int) -> Bool {
        let maxAllowedSpeed = limit + 5
        return currentSpeedKmh > maxAllowedSpeed
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        
        let speedMetersPerSecond = latestLocation.speed
        
        // Los valores negativos ocurren cuando no hay una medición de velocidad válida (ej: pérdida de señal)
        guard speedMetersPerSecond >= 0 else { return }
        
        // Conversión precisa: 1 Metro por segundo = 3.6 Kilómetros por hora
        let speedKmhDouble = speedMetersPerSecond * 3.6
        let speedKmhCalculated = Int(round(speedKmhDouble))
        
        // Actualizamos de forma segura dentro del Main Thread, ya que SwiftUI depende de esto
        DispatchQueue.main.async { [weak self] in
            self?.currentSpeedKmh = speedKmhCalculated
        }
    }
    
    // Tratamos los cambios en la autorización para actuar automáticamente
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("LocationManager: Permiso de ubicación denegado. No se podrá medir la velocidad.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Fallo en CoreLocation: \(error.localizedDescription)")
    }
}
