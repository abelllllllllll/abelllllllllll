# Equipo v1 · Impresión y montaje

![Equipo v1 en corte](../../mecanica/imagenes/v1_corte.png)

## 1. Imprimir

STL en [`mecanica/stl_v1/`](../../mecanica/stl_v1/), ya orientados para imprimir.

| Pieza | Material | Relleno | Soportes | Notas |
|---|---|---|---|---|
| `carcasa_izq`, `carcasa_der` | ASA o PETG negro | 15 % | No | 135 × 230 × 220 mm. Poné los 230 mm a lo largo de la cama. ~10-12 h c/u |
| `techo_izq`, `techo_der` | ASA o PETG negro | 15 % | No | Se imprimen boca abajo (cara de arriba sobre la cama) |
| `puerta` | PETG negro | 20 % | No | Pegar acrílico de 2 mm por dentro |
| `tapa_tolva` | PETG negro | 20 % | No | |
| `asiento` | PETG natural | 30 % | No | |
| `cubo_rotor` | PETG natural | 100 % | No | Lleva un prisionero M3 |
| `paleta_larga` ×3, `paleta_corta` ×3 | **TPU 85-95A** | 100 % | No | Acostadas. Usá un set u otro según el mate |
| `columna_motor` | PETG natural | 30 % | No | |
| `cajon` | PETG natural | 15 % | No | |
| `plato` | PETG natural | 30 % | No | |
| `dosificador` | PETG natural | 20 % | **Sí, solo bajo el tubo** | Se imprime con la boca de la tolva sobre la cama |
| `sinfin_v1` | PETG natural | 100 % | **Sí** | De pie, 0,16 mm. Lijar hasta que gire libre |

Todas las piezas que tocan yerba van en **PETG natural (sin pigmento)**. Igual, ver
[viabilidad](viabilidad_y_produccion.md): una pieza impresa no se considera apta para alimentos.

## 2. Preparar las carcasas

1. Poné **insertos M3** con el soldador en las paredes de unión (9 por módulo) y en las repisas.
2. Atornillá los dos módulos entre sí (M3 × 12).
3. Pegá las patas de silicona.

## 3. Estación de limpieza (izquierda)

1. Meté el motor **JGA25-370** en la `columna_motor`, con el eje hacia arriba, y atornillalo por arriba (2 × M3 × 6).
2. Pasá los cables por la ranura de atrás de la columna y atornillá la columna al piso (3 × M3).
3. Encastrá las 3 **paletas** en el `cubo_rotor` y metelo en el eje. Apretá el prisionero M3 contra la cara plana.
4. Apoyá el `asiento` sobre las 4 repisas. Tiene que quedar **centrado con el rotor** y sin tocarlo.
5. Meté el `cajon` por el frente: la ranura en U rodea la columna.
6. Colocá la `puerta` con 2 varillas de Ø3 como bisagra. Pegá el imán Ø6 × 3 en su hueco.
7. Montá el **microinterruptor** y el **sensor Hall** en la pared, frente al imán: con la puerta cerrada, el micro tiene que hacer clic.

## 4. Estación de carga (derecha)

1. Meté el `sinfin_v1` en el tubo del `dosificador` por el lado de la brida.
2. Pasá un tornillo M3 por el agujero del extremo de arriba: se enrosca en el sinfín y hace de eje. No lo aprietes.
3. Atornillá el **N20** a la brida con el soporte del banco de prueba (`mecanica/stl/soporte_motor.stl`).
4. Bajá el dosificador por arriba dentro de la torre derecha y fijalo a la pared.
5. Apoyá el `plato` sobre sus repisas.

## 5. Electrónica (torre izquierda)

Seguí [conexiones.md](conexiones.md). Orden recomendado:

1. Armá la placa en el perforado: ESP32-C3, TB6612, DRV8871, MP1584, 74AHCT125 y divisor.
2. Ajustá el MP1584 a 5,0 V **antes** de conectarle nada.
3. Cargá el [firmware](../../firmware/dispositivo_mate/dispositivo_mate.ino) por USB.
4. Conectá batería, BMS y cargador USB-C. El conector USB-C va en el agujero de atrás.
5. Conectá botón y anillo LED en el `techo_der`.

## 6. Primeras pruebas

1. Abrí el monitor serie a 115200 y escribí `?`: tiene que mostrar batería y puerta.
2. Con la tolva vacía, tocá el botón dos veces seguidas: el sinfín debe girar sin trabarse.
3. **Calibración**: llená la tolva, poné un vaso en el plato sobre una balanza y mantené el botón **6 s**.
   Gira 20 vueltas. Pesá y escribí `g=<gramos/20>`.
4. Con un mate usado boca abajo, cerrá la puerta y tocá el botón una vez.
5. Anotá los resultados en la tabla de [la Fase 2](../fase2_banco_dosificador.md).
