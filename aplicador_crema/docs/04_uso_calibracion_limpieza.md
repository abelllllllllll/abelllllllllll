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

**La crema solo sale con la paleta apoyada en la piel.** Al apoyarla notarás que se hunde un poco: es el sensor. Si la levantas, la crema se para al instante (y retrocede un poco para no gotear). Cuando la vuelves a apoyar, sigue donde lo dejó.

| Acción | Resultado |
|---|---|
| Apoyar la paleta y pulsación corta en DOSIS | Sale una dosis (2 ml por defecto) |
| Pulsación corta con la paleta en el aire | La dosis espera hasta 5 s a que apoyes la paleta. Si no, se cancela |
| Levantar la paleta a mitad de dosis | Se pausa y la completa al volver a apoyar (5 s máximo) |
| Mantener DOSIS | Sale crema mientras mantengas el botón **y** la paleta esté apoyada (máximo 20 s seguidos) |
| Pulsar DOSIS durante una dosis | La cancela |
| RETRAER | El carro vuelve atrás para cambiar la jeringa. Otra pulsación lo para |
| 2 minutos sin tocarlo | Se duerme. La siguiente pulsación solo lo despierta |

| LED | Significado |
|---|---|
| Destello corto cada 2 s | Listo |
| Parpadeo medio | Hay una dosis pedida esperando a que apoyes la paleta |
| Fijo | Motor en marcha |
| Doble destello | Jeringa vacía, o es la primera vez: pulsa RETRAER |
| Parpadeo rápido | Batería baja: carga |

## Calibración (una vez, 10 minutos)

Abre el monitor serie a 115200 baudios: el aparato te dice la batería y la posición del carro.

0. Para calibrar es más cómodo poner `REQUIERE_CONTACTO = false` mientras tanto (o sujetar la paleta apretada con una goma). **Vuelve a ponerlo en `true` al acabar.**
1. **`MM_POR_SEGUNDO`:** sin jeringa, pulsa RETRAER hasta el final. Marca la varilla, mantén DOSIS 10 s exactos y mide cuánto ha subido el carro. Divide entre 10. Anota también la tensión de batería que muestra el monitor y ponla en `V_CALIBRACION`.
2. **`ML_POR_MM`:** mira en la escala de tu jeringa cuántos mm ocupan 10 ml y calcula 10 ÷ esos mm. Para una jeringa de 60 ml de Ø27 sale ≈ 0,573.
3. **`RECORRIDO_MAX_MM`:** pon temporalmente `RECORRIDO_MAX_MM = 120` y carga el firmware. Coloca una jeringa **vacía** con el tapón al fondo. Desde atrás del todo, mantén DOSIS hasta que el empujador toque el tapón (verás que el motor se esfuerza) y suelta. El monitor muestra la posición. Pon ese valor **menos 2 mm**.
4. **Comprobación:** pesa 5 dosis en una báscula de cocina (1 ml de crema pesa ≈ 1 g). Si sale de menos, sube `DOSIS_ML`.

Los valores por defecto (2 ml de dosis; 1,20 mm/s; 106 mm) salen del diseño y del cálculo, y sirven para empezar.

## Ajustes que vas a querer tocar

| Variable | Por defecto | Para qué |
|---|---|---|
| `DOSIS_ML` | 2.0 | Cantidad por pulsación |
| `REQUIERE_CONTACTO` | true | Ponlo en `false` si el sensor falla, para seguir usándolo sin él |
| `ESPERA_CONTACTO_MS` | 5000 | Cuánto espera una dosis a que apoyes la paleta |
| `UMBRAL_MANTENER_MS` | 400 | A partir de cuánto tiempo pulsado cuenta como "mantener" |
| `ANTIGOTEO_MS` | 300 | Más alto si gotea después de soltar |
| `TIEMPO_APAGADO_MS` | 120000 | 2 minutos |
| `INVERTIR_MOTOR` | false | Si el carro va al revés |

## Limpieza: que no se estanque la crema

Las partes que tocan la crema son la jeringa (PP con tapón de goma), el tubo de silicona y la paleta (silicona de platino, o TPU si usas la impresa). **Ninguna toca la electrónica.**

- **Después de cada uso:** limpia la paleta con un pañuelo y luego agua con jabón neutro. Para sacarla, afloja el tornillo M2 y tira del cuello; no pierdas el muelle. Limpia también la cara de la cabeza alrededor del interruptor: si se acumula crema seca, la palanca puede quedarse pegada.
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

`firmware/pruebas/` contiene un simulador que ejecuta el `.ino` real en el PC, sin hardware, con 21 situaciones: dosis, mantener, cancelar, apagado, batería, jeringa vacía, contacto con la piel (en el aire, levantar a mitad, roces), etc.

```bash
cd firmware/pruebas
g++ -std=c++17 -I simulador prueba_firmware.cpp -o prueba && ./prueba
```

Pásalo cada vez que cambies el código.

## Cómo aplicarse la crema en todo el cuerpo

El aparato detecta si la paleta está apoyada en la piel, pero **no sabe en qué zona estás ni dónde falta crema**. Eso lo guías tú. Lo que mejor funciona:

| Zona | Cómo |
|---|---|
| Espalda alta | Pasa el mango por encima del hombro, con la paleta mirando a la espalda. El brazo a 45° está pensado para esto |
| Espalda baja y lumbares | Por el costado, con el mango casi horizontal |
| Piernas y pies | Sentado, sin agacharte |
| Brazos, pecho y abdomen | Con el aparato o echando una dosis en la mano |

- **Apoya, pulsa y arrastra:** apoya la paleta (sale crema), y en cuanto sale, arrástrala en pasadas largas. Para una zona grande, mantén el botón mientras mueves la paleta.
- **Rutina fija:** sigue siempre el mismo orden de zonas para no olvidarte de ninguna.
- **Dosis contadas:** por ejemplo, "espalda = 4 dosis". En pocos días sabrás cuántas necesita cada zona.
- **Un espejo** detrás ayuda a ver la espalda las primeras veces.
