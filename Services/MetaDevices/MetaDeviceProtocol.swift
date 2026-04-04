import Foundation
import CoreVideo
import Combine

/// Protocolo para interactuar con los dispositivos Meta (Data/Video stream)
protocol MetaDeviceProtocol {
    var isConnected: Bool { get }
    var connectionStatePublisher: Published<Bool>.Publisher { get }
    var videoFramePublisher: AnyPublisher<CVPixelBuffer, Never> { get }
    
    func connect()
    func disconnect()
}
