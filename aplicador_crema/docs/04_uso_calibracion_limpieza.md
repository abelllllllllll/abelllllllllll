# 4. Firmware, uso, calibración y limpieza

## Cargar el firmware (Arduino IDE 2.x)

1. Ve a *Archivo → Preferencias → URLs adicionales* y añade:
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
2. En *Herramientas → Placa → Gestor de placas*, instala **esp32** de Espressif (versión 3.x).
3. Abre `firmware/aplicador_crema/aplicador_crema.ino`.
4. Elige *Placa*: **ESP32C3 Dev Module** y pon *USB CDC On Boot*: **Enabled**.
5. Con el **interruptor general en OFF**, conecta el USB y pulsa *Subir*.
6. Si no detecta la placa, mantén pulsado el botón BOOT del SuperMini mientras la conectas.

## Uso diario

| Acción | Resultado |
|---|---|
| Pulsación corta en DOSIS | Sale una dosis (2 ml por defecto) |
| Mantener DOSIS | Sale crema mientras lo mantengas (máximo 20 s seguidos, por seguridad) |
| Pulsar DOSIS durante una dosis | La cancela |
| RETRAER | El carro vuelve atrás para cambiar la jeringa. Otra pulsación lo para |
| 2 minutos sin tocarlo | Se duerme. La siguiente pulsación solo lo despierta |

| LED | Significado |
|---|---|
| Destello corto cada 2 s | Listo |
| Fijo | Motor en marcha |
| Doble destello | Jeringa vacía, o es la primera vez: pulsa RETRAER |
| Parpadeo rápido | Batería baja: carga |

## Calibración (una vez, 10 minutos)

Abre el monitor serie a 115200 baudios: el aparato te dice la batería y la posición del carro.

1. **`MM_POR_SEGUNDO`:** sin jeringa, pulsa RETRAER hasta el final. Marca la varilla, mantén DOSIS 10 s exactos y mide cuánto ha subido el carro. Divide entre 10. Anota también la tensión de batería que muestra el monitor y ponla en `V_CALIBRACION`.
2. **`ML_POR_MM`:** mira en la escala de tu jeringa cuántos mm ocupan 10 ml y calcula 10 ÷ esos mm. Para una jeringa de 60 ml de Ø27 sale ≈ 0,573.
3. **`RECORRIDO_MAX_MM`:** pon temporalmente `RECORRIDO_MAX_MM = 120` y carga el firmware. Coloca una jeringa **vacía** con el tapón al fondo. Desde atrás del todo, mantén DOSIS hasta que el empujador toque el tapón (verás que el motor se esfuerza) y suelta. El monitor muestra la posición. Pon ese valor **menos 2 mm**.
4. **Comprobación:** pesa 5 dosis en una báscula de cocina (1 ml de crema pesa ≈ 1 g). Si sale de menos, sube `DOSIS_ML`.

Los valores por defecto (2 ml de dosis; 1,20 mm/s; 106 mm) salen del diseño y del cálculo, y sirven para empezar.

## Ajustes que vas a querer tocar

| Variable | Por defecto | Para qué |
|---|---|---|
| `DOSIS_ML` | 2.0 | Cantidad por pulsación |
| `UMBRAL_MANTENER_MS` | 400 | A partir de cuánto tiempo pulsado cuenta como "mantener" |
| `ANTIGOTEO_MS` | 300 | Más alto si gotea después de soltar |
| `TIEMPO_APAGADO_MS` | 120000 | 2 minutos |
| `INVERTIR_MOTOR` | false | Si el carro va al revés |

## Limpieza: que no se estanque la crema

Las partes que tocan la crema son la jeringa (PP con tapón de goma), el tubo de silicona y la paleta (TPU). **Ninguna toca la electrónica.**

- **Después de cada uso:** limpia la paleta con un pañuelo y luego agua con jabón neutro. La paleta sale tirando del cuello.
- **Cada vez que cambies de jeringa:**
  1. Saca el tubo de silicona y la paleta.
  2. Con una jeringa normal, empuja **agua tibia (≤ 40 °C) con jabón neutro** por el tubo y la paleta, varias veces.
  3. Aclara con agua limpia y sopla aire, o empuja aire con la jeringa vacía.
  4. Deja secar al aire, colgados.
- **Una vez al mes:** pasa **alcohol al 70 %** por el tubo, la paleta y la tapa superior, y deja secar.
- **Jeringas:** las de PP se pueden lavar con agua jabonosa tibia y reutilizar unas cuantas veces. Cuando el tapón deje de deslizar bien o se rayen, se tiran (son baratas).
- **No dejes crema más de 2–3 semanas** en una jeringa montada, ni en un sitio caliente. La crema de un envase abierto también caduca: mira el símbolo del bote abierto (por ejemplo "12M").
- **Nunca** metas el tubo de PVC en agua: la electrónica está dentro. Pásale un paño húmedo.

## Pruebas automáticas del firmware

`firmware/pruebas/` contiene un simulador que ejecuta el `.ino` real en el PC, sin hardware, con 16 situaciones: dosis, mantener, cancelar, apagado, batería, jeringa vacía, etc.

```bash
cd firmware/pruebas
g++ -std=c++17 -I simulador prueba_firmware.cpp -o prueba && ./prueba
```

Pásalo cada vez que cambies el código.
