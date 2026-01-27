LTRA: MANUAL DE USUARIO (Referencia Completa)

**Objetivo:** Explicación detallada de cada control y flujo de trabajo.

## I. EL CONTROLADOR 16n (Mapa de Faders)
El 16n es el "Cerebro Emocional". Controla la expresividad macro.

| Fader | Función | Descripción |
| :--- | :--- | :--- |
| **1 - 4** | **PITCH (Voces 1-4)** | Selecciona la nota dentro de la escala activa. |
| **5 - 8** | **VOLUMEN (Voces 1-4)** | Nivel de salida de cada oscilador. |
| **9** | **FILTER 1 TONE** | Filtro DJ. Centro=Clean, Izq=LowPass, Der=HighPass. |
| **10** | **FILTER 2 TONE** | Segundo filtro en serie. Igual comportamiento. |
| **11** | **CHAOS AMOUNT** | Cantidad de aleatoriedad en el sistema "Rungler". |
| **12** | **LFO 1 RATE** | Velocidad del primer oscilador de baja frecuencia. |
| **13** | **LFO 2 RATE** | Velocidad del segundo oscilador de baja frecuencia. |
| **14** | **DELAY TIME** | Tiempo del eco de cinta. |
| **15** | **DELAY FEEDBACK** | Cantidad de repeticiones (Cuidado: >90% satura). |
| **16** | **REVERB MIX** | Cantidad de atmósfera/nube. |

*   **Soft Takeover:** Si cargas un Preset, los faders físicos no coincidirán con el sonido. La pantalla mostrará flechas indicando hacia dónde mover el fader para recuperar el control.

## II. EL GRID 128 (Superficie de Control)

### ZONA COMÚN (Fila 8)
*   **Cols 1-4 (Triggers):** Disparadores manuales de las 4 voces. Envían señal al módulo "OUTLINE" de la matriz. Tienen envolvente orgánica (Vactrol).
*   **Cols 13-15 (Páginas):** Cambia la vista del Grid (Main, Scales, Loopers).

### PÁGINA 1: MAIN (Matriz & Dashboard)
*   **Filas 1-4 (La Matriz):** Conecta Fuentes (Y) con Destinos (X).
    *   *Fuentes:* LFO1, LFO2, Chaos, Outline (Triggers), Arp.
    *   *Destinos:* Pitch 1-4, Amp 1-4, Morph 1-4, Filtros y Delay.
    *   **Edición Fina (HOLD):** Mantén pulsado un botón de la matriz para ver en la pantalla de Norns el menú de edición (Ajuste fino de cantidad y Polaridad +/-).
*   **Fila 6 (Dashboard):** Accesos directos a los módulos.
    *   **Botones 1-4 (OSC):** Mantener para editar Forma de onda, Pan, Fine Tune y activar Arpegiador.
    *   **Botones 6-7 (LFO):** Mantener para editar Forma y Profundidad.
    *   **Botones 11-12 (FILT):** Mantener para editar Resonancia, Drive y Tipo (Moog/SVF).
    *   **Botón 13 (DELAY):** Mantener para editar Spread, Wow/Flutter y Erosión.
    *   **Botón 14 (REVERB):** Mantener para editar Dirt, Decay y Damping.

### PÁGINA 2: SCALES (Afinación)
*   **Fila 1:** Banco A (Escalas Occidentales: Mayor, Menor, Dórica...).
*   **Fila 2:** Banco B (Entonación Justa y Exóticas) + 4 Slots Custom.
*   **Filas 4-5:** Teclado Visual (Centrado). Muestra las notas activas.
*   **Fila 6:** Selector de Nota Raíz (Root).

### PÁGINA 3: LOOPERS (Cinta)
*   **Filas 1, 3, 5:** Cintas visuales de los Loopers 1, 2 y 3.
    *   **1 Dedo:** Salto (Seek) con inercia.
    *   **2 Dedos:** Definir Loop (Start/End).
*   **Fila 6 (Selectores):** Botones alineados con cada cinta.
    *   **HOLD:** Abre el menú del Looper en Norns (Envío a Reverb, Feedback/Overdub, Pre/Post Switch).

### FILA 7: SECUENCIADORES DE GESTOS (Global)
*   4 Botones pulsantes. Graban los movimientos de los Triggers (Fila 8).
*   **Click:** Grabar / Play / Overdub.
*   **Doble Click:** Stop.
*   **Hold:** Borrar (Clear).

## III. PANTALLA Y ENCODERS (Norns)
La pantalla es contextual. Cambia según qué botón del Grid estés manteniendo pulsado ("Hold").
*   **Sin Hold:** Muestra información general y Vúmetros.
*   **Con Hold (Dashboard/Matriz):** Muestra los parámetros ocultos.
    *   **E1 / E2 / E3:** Ajustan los valores mostrados.
    *   **K2 / K3:** Actúan como interruptores (Toggles) para opciones binarias (ej. Arp On/Off, Pre/Post).
