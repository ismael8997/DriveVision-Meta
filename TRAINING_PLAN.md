# Plan de Entrenamiento de IA y Telemetría Visual: DriveSight

Este documento define la hoja de ruta para desarrollar el "cerebro" de la aplicación DriveSight, integrando detección de objetos con cálculos de física real (velocidad y distancia) utilizando las Meta Ray-Ban.

## 1. Estrategia de Desarrollo
- **Lenguaje Principal:** Python 3.10+
- **Framework de IA:** YOLOv8 (Ultralytics)
- **Librerías de Visión:** OpenCV, NumPy
- **Plataforma de Entrenamiento:** Windows (con soporte CUDA para GPU NVIDIA)

## 2. Estructura del Módulo de Entrenamiento (`/Training`)

Se recomienda crear la siguiente estructura en la raíz del proyecto:
```text
/Training
├── /datasets          # Videos y frames extraídos de las Ray-Ban
│   ├── /raw           # Clips de video originales
│   ├── /images        # Frames procesados para entrenamiento
│   └── /labels        # Anotaciones en formato YOLO (.txt)
├── /scripts           # Scripts de Python
│   ├── trainer.py     # Lógica de entrenamiento de YOLO
│   ├── telemetry.py   # Cálculos de píxeles a metros y velocidad
│   └── converter.py   # Exportación de .pt a .mlmodel (CoreML)
└── /models            # Almacenamiento de modelos finales
```

## 3. Telemetría y Física Visual
Para lograr una medición funcional de velocidad y distancia desde un video monocular (las gafas), implementaremos:

### A. Calibración de Píxeles (Referencia)
- Usaremos una **Hoja de Calibración** o una referencia conocida en el suelo (ej. líneas de carretera de 3 metros).
- **Fórmula:** `Relación_Píxel_Metro = Distancia_Real / Distancia_Píxeles`.

### B. Medición de Velocidad ($m/s$)
- **Detección del desplazamiento:** Medir la cantidad de píxeles que recorre un objeto (o el suelo) entre dos frames.
- **Factor Tiempo:** Basado en los FPS del video (ej. 1 frame a 30fps = 0.033 segundos).
- **Cálculo:** `Velocidad = (Delta_Píxeles * Relación) / Delta_Tiempo`.

### C. Detección de Objetos Específicos
- **Baches:** Entrenamiento específico para identificar cambios de textura y profundidad en el asfalto.
- **Distancia de seguridad:** Estimación basada en el tamaño relativo de los vehículos detectados (Bounding Box size).

## 4. Pipeline de Trabajo
1. **Captura:** Grabar con Meta Ray-Ban -> Meta View App -> PC.
2. **Pre-procesamiento:** Script en Python para extraer frames y corregir perspectiva.
3. **Etiquetado:** Usar CVAT o LabelImg para marcar baches y señales.
4. **Entrenamiento:** Correr YOLOv8 en Windows.
5. **Conversión:** Exportar a `.mlmodel` para integrar en la app de iOS.

## 5. Próximos Pasos Recomendados
- [ ] Instalar entorno de Python 3.10.
- [ ] Realizar la primera grabación de "Calibración" (conducir en una calle con medidas conocidas).
- [ ] Configurar el script base de telemetría.

---
**Nota:** Este plan es interactivo. A medida que avancemos, iremos ajustando las fórmulas de física según los resultados de precisión obtenidos de las gafas.
