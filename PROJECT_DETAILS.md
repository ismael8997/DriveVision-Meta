# Documentación Técnica: Proyecto DriveSight

**Versión:** 1.0  
**Plataforma:** iOS 17.0+  
**Objetivo:** Asistente de conducción inteligente integrado con dispositivos Meta POV (Ray-Ban Meta).

---

## 1. Arquitectura del Sistema
El proyecto utiliza una **Arquitectura Modular Limpia (Clean Architecture)** orientada a características (`Features`) y servicios compartidos. El proyecto no se gestiona mediante un archivo `.xcodeproj` manual, sino que se genera dinámicamente.

### Gestión de Proyecto (XcodeGen)
- **Archivo Config:** `project.yml`
- **Herramienta:** [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- **Razón:** Facilita el trabajo en equipo evitando conflictos en el archivo de proyecto de Xcode y permite una estructura de carpetas lógica en el disco.

### Estructura de Directorios
- `App/`: Punto de entrada de la aplicación (`@main`).
- `Features/`: Módulos funcionales de la UI (ej. Dashboard).
    - `Views/`: Componentes de SwiftUI (HUD, SpeedLimitView).
    - `ViewModels/`: Lógica de estado y enlace con servicios.
- `Services/`: Lógica de negocio y hardware.
    - `Vision/`: Procesamiento de imágenes mediante Apple Vision Core.
    - `MetaDevices/`: Abstracción de la conexión con las gafas Meta.
    - `Audio/`: Gestor de alertas sonoras.
- `Models/`: Estructuras de datos puras y entidades compartidas.
- `Resources/`: Assets, Iconos y Plists.

---

## 2. Flujo de Datos Principal (Pipeline)

El flujo de información sigue un modelo reactivo utilizando el framework **Combine**:

1.  **Captura (MetaDeviceService):** 
    - El servicio simula/gestiona un flujo de `CVPixelBuffer` desde la cámara de las gafas.
    - Emite los frames mediante un `videoFramePublisher`.
2.  **Procesamiento (VisionProcessor):**
    - Recibe el buffer de imagen en una cola de prioridad de fondo (`DispatchQueue.global`).
    - Ejecuta `VNRecognizeTextRequest` para detectar señales de velocidad (OCR).
    - Ejecuta `VNCoreMLRequest` (Placeholder) para detectar estados de semáforos.
    - Empaqueta los resultados en una estructura `ProcessingResult`.
3.  **Consumo (DashboardViewModel):**
    - El ViewModel se suscribe a los resultados del procesador de visión.
    - Actualiza las propiedades `@Published` observadas por la UI.
4.  **Visualización (SwiftUI):**
    - `HUDView` y `SpeedLimitView` reaccionan a los cambios de estado, mostrando alertas visuales al conductor.

---

## 3. Tecnologías Core
- **SwiftUI:** Framework de interfaz declarativa.
- **Vision Framework:** Para OCR y detección de objetos nativa de Apple.
- **CoreML:** Para la ejecución de modelos personalizados de IA.
- **Combine:** Para la comunicación asíncrona entre servicios.
- **CoreVideo:** Gestión eficiente de buffers de imagen.

---

## 4. Componentes Clave para Desarrolladores

### `VisionProcessor.swift`
Es el núcleo de la inteligencia. Implementa la lógica de extracción de números de velocidad mediante expresiones regulares y filtrado de "cordura" (evitando lecturas falsas superiores a 150 km/h o inferiores a 5 km/h).

### `MetaDeviceService.swift`
Actualmente es un **Mock**. Para producción, este servicio debe implementar la comunicación real (vía Wi-Fi/Bluetooth) con las gafas Meta. Implementa `MetaDeviceProtocol` para facilitar el intercambio de la versión simulada por la real.

### `project.yml`
Define los targets, permisos de cámara y dependencias. Cualquier archivo nuevo añadido al disco es detectado automáticamente al regenerar el proyecto con `xcodegen generate`.

---

## 5. Guía de Desarrollo Futuro

Para expandir la aplicación, cualquier desarrollador (o agente de IA) debe seguir estas reglas:
1.  **Nuevas Funcionalidades:** Crear una subcarpeta en `Features/` con su propio View y ViewModel.
2.  **Nuevos Sensores:** Añadir un nuevo servicio en `Services/` y definir un Protocolo para permitir Mocking.
3.  **Modelos de IA:** Los nuevos modelos `.mlmodel` deben colocarse en `Resources/Models/` y ser referenciados en `VisionProcessor`.

---

## 6. Configuración del Entorno
1.  Instalar Xcode 15+.
2.  Instalar XcodeGen: `brew install xcodegen`.
3.  Ejecutar `xcodegen generate` en la raíz para crear `DriveSight.xcodeproj`.
4.  Abrir el proyecto y ejecutar en un dispositivo físico (necesario para funciones de cámara/vision reales).
