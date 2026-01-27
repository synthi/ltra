 LTRA: QUICK START GUIDE (Guía de Inicio Rápido)

**Objetivo:** Pasar de "Cero" a "Hacer Música" en menos de 5 minutos.

### A. REQUISITOS Y CONEXIÓN
1.  **Hardware:** Monome Norns + Grid 128 + Controlador 16n Faderbank.
2.  **Conexión:**
    *   Conecta el Grid y el 16n a los puertos USB de Norns.
    *   Asegúrate de que el 16n envía MIDI por el Canal 1 (CC 32-47 es el estándar, pero LTRA se auto-configura).
3.  **Arranque:**
    *   En Norns: `SYSTEM > RESTART` (Si acabas de instalar el script).
    *   Carga el script: `SELECT > LTRA`.
    *   *Esperar 3 segundos:* Verás en pantalla "LTRA v0.6" y "Bus: [Número]". Si dice "Wait...", espera un momento más.

### B. TU PRIMER SONIDO (Drone)
El sistema arranca en silencio.
1.  **Sube el Volumen:** En el 16n, sube los **Faders 5, 6, 7 y 8** al máximo. Estos son los volúmenes de los 4 Osciladores.
2.  **Abre el Filtro:** Coloca los **Faders 9 y 10** (Filtros) en el centro (50%).
3.  **Define el Tono:** Mueve los **Faders 1 al 4** para cambiar la afinación de cada voz.
    *   *Nota:* Si mueves un fader y no cambia, mira la pantalla de Norns. Si ves una flecha (`^` o `v`), mueve el fader en esa dirección hasta "enganchar" el valor (Soft Takeover).

### C. NAVEGACIÓN BÁSICA (Grid)
Mira la **Fila 8** (la de abajo del todo). Los 4 últimos botones (13-16) son el selector de páginas.
*   **Página 1 (Botón 13):** **MAIN**. Aquí ves la Matriz de modulación (arriba) y el Dashboard de módulos (Fila 6).
*   **Página 2 (Botón 14):** **SCALES**. Aquí eliges la escala musical.
*   **Página 3 (Botón 15):** **LOOPERS**. Aquí controlas las 3 cintas de grabación.

### D. CREANDO MOVIMIENTO (La Matriz)
1.  Ve a la **Página 1**.
2.  Mira las **Filas 1 a 4** (Matriz).
    *   Fila 1 = LFO 1.
    *   Columna 1 = Pitch Voz 1.
3.  **Pulsa la intersección** (Fila 1, Columna 1). El LED se encenderá.
    *   Pulsar repetidamente cambia la intensidad: 100% -> 66% -> 33% -> Off.
4.  Ahora el LFO 1 está moviendo la afinación de la Voz 1.
5.  Usa el **Fader 12** del 16n para cambiar la velocidad del LFO 1.

### E. GRABANDO UN LOOP
1.  Ve a la **Página 3** (Botón 15 en Fila 8).
2.  Verás 3 cintas horizontales (Filas 1, 3, 5).
3.  **Grabar:** Toca cualquier punto de la Fila 1 (Cinta 1). El looper empezará a grabar (el botón de estado parpadeará).
4.  **Reproducir:** Toca de nuevo para cerrar el loop y reproducir.
5.  **Jugar:** Desliza el dedo por la cinta para mover el cabezal (Scrubbing). Pon dos dedos para hacer un loop corto entre ellos.
