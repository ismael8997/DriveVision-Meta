import SwiftUI

@main
struct DriveSightApp: App {
    // Inyectamos el Mock en el DashboardViewModel
    @StateObject private var dashboardVM: DashboardViewModel = {
        let mockDevice = MetaDeviceService() // Intercambiable por dispositivo real en el futuro
        return DashboardViewModel(metaDeviceService: mockDevice)
    }()

    var body: some Scene {
        WindowGroup {
            // Utilizamos el orquestador general HUDView
            HUDView(viewModel: dashboardVM)
                // Evitamos que la pantalla del iPhone se apague mientras se conduce
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
