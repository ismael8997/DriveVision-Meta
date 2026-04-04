import SwiftUI

struct HUDView: View {
    @StateObject var viewModel: DashboardViewModel
    
    var body: some View {
        ZStack {
            // Tema oscuro puro indispensable en apps automotrices para no cegar en la noche
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header (Conexión + Visión de objetos)
                headerIndicators
                
                Spacer()
                
                // Velocímetro digital masivo central
                speedReadout
                
                Spacer()
            }
            
            // Señal flotante del OCR (Arriba a la derecha)
            if let limit = viewModel.currentSpeedLimit {
                VStack {
                    HStack {
                        Spacer()
                        SpeedLimitView(limit: limit)
                            .padding(.top, 50)
                            .padding(.trailing, 24)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - SubViews
    
    private var headerIndicators: some View {
        HStack {
            // Pill indicador del Bluetooth de las gafas Meta
            HStack {
                Circle()
                    .fill(viewModel.isDeviceConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(viewModel.isDeviceConnected ? "Meta Ray-Ban" : "Desconectadas")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
            
            Spacer()
            
            // Pill indicador del Semáforo
            HStack {
                Text("Visión AI:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Circle()
                    .fill(colorForTrafficLight(viewModel.activeTrafficLight))
                    .frame(width: 14, height: 14)
            }
            .padding(10)
            .background(Color.white.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var speedReadout: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.currentSpeed)")
                .font(.system(size: 160, weight: .heavy, design: .rounded))
                // Transformación visual inmediata sin retrasos al sobrepasar el límite
                .foregroundColor(viewModel.isSpeeding ? Color.red : Color.white)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isSpeeding)
            
            Text("km/h")
                .font(.title2.bold())
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Helpers
    
    private func colorForTrafficLight(_ state: TrafficLightState) -> Color {
        switch state {
        case .red: return .red
        case .yellow: return .yellow
        case .green: return .green
        case .unknown: return .gray
        }
    }
}
