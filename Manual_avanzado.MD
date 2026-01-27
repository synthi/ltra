LTRA: MANUAL AVANZADO (Ingeniería y Arquitectura)

**Objetivo:** Comprender la lógica interna, el flujo de señal y la estructura de datos.

### A. ARQUITECTURA DE AUDIO (SuperCollider Engine)
El motor `Engine_Ltra` está diseñado con una topología híbrida de síntesis sustractiva y procesado de cinta.

1.  **Generación (Osciladores Morphing):**
    *   Cada voz utiliza una arquitectura de **Modulación de Frecuencia por Ruido**.
    *   El parámetro `Shape` interpola: Ruido Rosa -> Sierra (con FM de ruido decreciente) -> Triángulo -> Pulso -> Seno.
    *   **Just Intonation:** El Engine recibe frecuencias en Hz crudos calculados por Lua, permitiendo afinación microtonal perfecta (Ratios puros).
2.  **Filtrado (Dual DJ Topology):**
    *   No usa filtros estándar. Implementa una curva matemática personalizada que emula un mixer DJ.
    *   **Centro:** Señal limpia.
    *   **Extremos:** Aplica filtros resonantes (RLPF/RHPF) en serie.
    *   **Carácter:** Conmutable entre topología limpia (SVF) y sucia (Moog Ladder) con saturación de entrada (`Drive`).
3.  **Atmósfera (Dirt Injection):**
    *   Antes de los efectos, se inyecta una señal compuesta de Hiss (Ruido rosa), Hum (50Hz) y Dust (Impulsos aleatorios). Esto da textura "física" al silencio.
4.  **Espacio (Tape Echo & Reverb):**
    *   **Tape:** Bucle de feedback real (`LocalIn/Out`) con saturación asimétrica (armónicos pares), EQ de cabezal (Head Bump a 100Hz) y Erosión (Dropouts estocásticos).
    *   **Reverb:** Greyhole modulada.
5.  **Dinámica (Mastering):**
    *   La señal final pasa por un limitador duro (`Limiter.ar`) para prevenir daños por feedback digital.

### B. SISTEMA DE LOOPERS (Softcut Híbrido)
LTRA utiliza las 6 voces de Softcut configuradas como **3 Pistas Estéreo**.

*   **Gestión de Memoria:** El buffer de audio de Norns se particiona estáticamente:
    *   Looper 1: 0s - 40s.
    *   Looper 2: 40s - 80s.
    *   Looper 3: 80s - 120s.
*   **Física de Vari-Speed:** Lua implementa una simulación de inercia. El tiempo de `slew` (deslizamiento) del pitch depende de cuánto tiempo mantienes el dedo en la cinta. Toques rápidos = saltos rápidos. Arrastres largos = cambios lentos y pesados.
*   **Ruteo de Audio:**
    *   **PRE:** Graba la salida de los filtros (antes del Delay).
    *   **POST:** Graba la salida del Compresor (Master).
    *   *Nota:* El envío de los Loopers al Delay (`Send Space`) es una mezcla global debido a la arquitectura de buses de Norns.

### C. LÓGICA DE MODULACIÓN (Matriz y Arp)
*   **Matriz:** Se calcula en el servidor de audio (SuperCollider) a velocidad de control (`.kr`), garantizando suavidad y audio-rate modulation. Lua solo envía los coeficientes.
*   **Arpegiador (Shift Register):**
    *   No es un arpegiador MIDI. Es un generador de voltajes basado en un registro de desplazamiento de 8 bits simulado.
    *   En cada pulso de reloj, los bits rotan y se inyecta un bit de caos. El valor resultante se cuantiza a la escala activa. Esto genera patrones pseudo-aleatorios que se repiten cíclicamente pero mutan con el tiempo (Rungler).

### D. ESTRUCTURA DE DATOS Y PERSISTENCIA
*   **PSET (Project):** Guarda el estado completo.
*   **Sidecar Files:** Debido a la complejidad de las tablas (Matriz, Gestos), LTRA guarda archivos auxiliares (`.data`) y volcados de audio (`.wav`) junto con cada PSET.
*   **Handshake:** Al arrancar, Lua y SuperCollider negocian el ID del bus de audio interno mediante OSC (`/query_config`) para asegurar que el ruteo de Softcut sea correcto independientemente del orden de carga.
