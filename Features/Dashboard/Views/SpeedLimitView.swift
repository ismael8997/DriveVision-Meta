import SwiftUI

/// Componente de UI que renderiza una señal circular con el límite de velocidad detectado
struct SpeedLimitView: View {
    let limit: Int
    
    var body: some View {
        ZStack {
            // Fondo blanco opaco
            Circle()
                .fill(Color.white)
                .frame(width: 90, height: 90)
            
            // Aro exterior de advertencia según los estándares euro/latinos de señalética
            Circle()
                .strokeBorder(Color.red, lineWidth: 10)
                .frame(width: 90, height: 90)
            
            // Velocidad Maxima
            Text("\(limit)")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(.black)
        }
    }
}
