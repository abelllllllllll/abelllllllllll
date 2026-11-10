# 3. Montaje mecánico

![Conjunto en corte](../mecanica/imagenes/conjunto_corte.png)

De abajo arriba: **tapa inferior** (USB-C e interruptor) → **trineo** con el TP4056, la batería y la placa → **soporte del motor** (N20, acoplador, rodamiento y final de carrera) → **carro con tubo empujador** → **jeringa de 60 ml** → **tapa superior con brazo a 45°** → **paleta**.

## Cómo funciona el empujador

Se quita el vástago (la varilla con el disco para el pulgar) del émbolo de la jeringa y se deja **solo el tapón de goma** dentro. Lo empuja un **tubo hueco impreso** que forma parte del carro. Al avanzar, la varilla roscada M5 se va metiendo dentro de ese tubo hueco. Así cabe todo en línea dentro de un tubo de Ø40.

El empuje se transmite así: tapón → crema → hombro de la jeringa → tapa superior → tornillo M4 → tubo de PVC. En el otro sentido: carro → tuercas → varilla M5 → rodamiento 625 → escalón del soporte → tornillos M3 → tubo de PVC. **El motor no recibe empuje axial**, solo par.

## Archivo OpenSCAD

`mecanica/aplicador.scad` es paramétrico. **Antes de imprimir, mide con el pie de rey tu tubo, tu jeringa, tu motor y tu acoplador**, y corrige la sección `MEDIDAS`. Al renderizar, la consola de OpenSCAD te dice:

```
=== CORTAR TUBO PVC Ø40 A: 511 mm
=== VARILLA M5 INOX: 153 mm   VARILLA GUÍA Ø4: 134 mm
=== RECORRIDO_MAX_MM para el firmware: 106
=== AGUJEROS EN EL PVC (desde el extremo de abajo): DOSIS Ø12 a 165 mm, LED Ø5 a 152 mm, RETRAER Ø12 a 140 mm
```

Además lleva comprobaciones automáticas (`assert`) que avisan si alguna medida hace que dos piezas choquen.

Los STL ya generados con las medidas típicas están en `mecanica/stl/`.

## Impresión

| Pieza | Material | Orientación | Notas |
|---|---|---|---|
| `soporte_motor` | PETG | De pie, como está | 5 perímetros, 40 % de relleno |
| `carro` | PETG | De pie, con el tubo hacia arriba | 6 perímetros (las tuercas M5 van a presión) |
| `tapa_superior` | PETG | Tumbada de lado | Con soportes, por el codo del brazo |
| `trineo` | PETG | Con la bandeja apoyada en la cama | — |
| `tapa_inferior` | PETG | Con el reborde abajo | — |
| `paleta` | **TPU 95A** | Con la cara de aplicación abajo | 3 perímetros, 25 % de relleno; queda blanda |
| `plantilla_taladro` | PLA o PETG | — | Solo sirve para marcar los agujeros |

## Pasos

1. **Tubo:** córtalo a la medida que indica OpenSCAD (≈ 511 mm), recto, y lija las rebabas. Apoya la plantilla en el extremo de abajo, marca y taladra: botones Ø12, LED Ø5, y luego los agujeros de los tornillos (M3 Ø2,6 y M4 Ø4,4) presentando cada pieza en su sitio.
2. **Jeringas (cartuchos):** recorta las aletas en círculo de Ø33 mm, con cúter y lima. Saca el vástago del émbolo girándolo y tirando: el tapón de goma se queda dentro. **Guarda un vástago** para colocar el tapón al rellenar.
3. **Soporte del motor:**
   - Mete el N20 desde abajo (va justo de medida; una gota de pegamento si queda flojo) y pon el acoplador en su eje.
   - Pasa la varilla M5 desde arriba por el escalón y rósca una tuerca por debajo, que queda en la cámara del acoplador. Mete el rodamiento 625 desde arriba hasta que apoye en el escalón, y encima pon arandela y tuerca M5. **Aprieta las dos tuercas contra el rodamiento**: la varilla debe girar con el aro interior sin holgura arriba-abajo.
   - Mete el extremo de la varilla en el acoplador y aprieta los prisioneros.
   - Pega la varilla guía Ø4 en su agujero ciego con epoxi, bien vertical.
   - Atornilla el microinterruptor (M2) en su rebaje, con la palanca hacia arriba.
4. **Carro:** mete una tuerca M5 a presión en cada hexágono, de arriba y de abajo (con calor del soldador si cuesta). Enróscalo en la varilla, con la guía pasando por su agujero.
5. **Lubrica** la varilla con grasa de silicona.
6. **Trineo:** sujeta con bridas el portapilas, el TP4056 (con el USB-C hacia abajo, alineado con la ventana de la tapa) y la placa. Pasa los cables por el canal de la pared.
7. **Montaje en el tubo:** monta los botones y el LED en el tubo. Mete el trineo y la tapa inferior por abajo, y el soporte del motor con el carro por arriba, hasta su sitio. Fíjalos con los M3.
8. **Tapa superior:** pasa el tubo de silicona por el canal del brazo (con jabón entra mejor) y deja que asome unos 15 mm por cada lado. Encaja el cuello de la paleta en el zócalo y mete el tubo 10 mm en el cuello.

## Cambiar o rellenar la jeringa

1. Pulsa **RETRAER** y espera a que el carro llegue atrás del todo (≈ 90 s; el LED queda fijo mientras se mueve).
2. Quita el tornillo M4 con la mariposa y saca la tapa superior: el tubo de silicona sale con ella. Saca la jeringa.
3. **Rellenar:** saca el tapón de goma con el vástago guardado. Llena el cuerpo por detrás con una espátula o una manga pastelera desechable, dando golpecitos para que no queden burbujas. Mete el tapón con el vástago, pasando un alambre fino entre el tapón y la pared para que escape el aire. Empuja hasta que asome crema por la punta y quita el vástago.
4. Mete la jeringa con la punta hacia arriba, conecta el tubo de silicona, pon la tapa y el tornillo.
5. La primera dosis tarda un poco: el empujador recorre unos 2 mm hasta tocar el tapón.

Lo más práctico es tener **2–3 jeringas llenas** en la nevera o en un cajón, tapadas con su capuchón, y cambiarlas como si fueran cartuchos.
