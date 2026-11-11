# Cómo funciona (explicado fácil)

![Infografía: cómo funciona](imagenes/mate_clean_infografia.png)

## 1. El equipo por fuera

![El equipo](../../mecanica/imagenes/v1_ensamble.png)

Es una caja negra de **29 cm de ancho, 23 cm de fondo y 22 cm de alto** (con la tolva arriba llega a 33 cm).
Por fuera tiene muy pocas cosas: una **tapa redonda** arriba a la izquierda, un **botón con luz**, un **nicho**
adelante a la derecha, un **cajón** al ras abajo a la izquierda y la **tolva** transparente arriba.

| | Izquierda: **LIMPIEZA** | Derecha: **CARGA** |
|---|---|---|
| Por dónde entra el mate | **Por arriba**, sacando la tapa redonda | **Por adelante**, en el nicho |
| Cómo va el mate | **Boca abajo** | **Boca arriba** |
| Dónde se apoya | En un **asiento con forma de cono** (apoya la boca) | En un **plato** con agujeritos (apoya la base) |
| Qué pasa | Unas **paletas** de goma giran adentro del mate y la yerba usada cae al **cajón** | Un **tornillo (sinfín)** trae yerba de la **tolva** y la deja caer en la boca |
| Seguridad | Sin la **tapa** puesta, no gira | No hace falta: no hay nada que gire a la vista |

El mate entra por arriba en la limpieza porque tiene que **bajar sobre las paletas**: por adelante no habría lugar.

## 2. El recorrido del mate

![Interior del equipo](../../mecanica/imagenes/v1_corte.png)

1. **Sacás la bombilla**, levantás la tapa redonda y metés el mate **boca abajo**. Ponés la tapa y tocás el botón.
2. Las paletas giran unos **15 segundos** (para un lado y para el otro) y la yerba usada cae al cajón.
3. La luz late en azul: sacás el mate, lo **das vuelta** y lo ponés **boca arriba** en el nicho. Tocás el botón.
4. El sinfín gira unos **15 segundos** y deja caer **30 g** de yerba nueva en la boca.
5. Luz verde: listo para cebar.

**¿Por qué entra cualquier mate?** El asiento es un **cono hecho de costillas**. Una boca chica apoya cerca del centro
(más abajo) y una virola grande apoya más afuera (más arriba). Como es un cono, el mate **se centra solo**.
Sirve para bocas de **4 a 11 cm** de diámetro y mates de hasta **13 cm** de alto.
Entre las costillas queda abierto, así la yerba cae directo al cajón.

## 3. Qué es el "modelo 3D"

El modelo 3D es el **dibujo del equipo en la computadora**, pieza por pieza, con sus medidas exactas.
Sirve para tres cosas:

1. **Verlo antes de fabricarlo** (el visor 3D, las imágenes de arriba).
2. **Imprimir las piezas**: de cada pieza sale un archivo **STL**, que es lo que se carga en la impresora 3D.
3. **Cambiar medidas fácil**: está hecho en **OpenSCAD**, un programa gratis donde el dibujo se escribe con números.
   Si cambiás un número (por ejemplo el alto del mate), se recalculan todas las piezas solas.

| Archivo | Qué es | Con qué se abre |
|---|---|---|
| `mecanica/equipo_v1.scad` | El modelo completo, con todas las medidas | **OpenSCAD** (gratis, openscad.org) |
| `mecanica/stl_v1/*.stl` | Cada pieza lista para imprimir | El laminador de tu impresora (Cura, PrusaSlicer, Bambu Studio…) o cualquier visor 3D |
| `mecanica/imagenes/*.png` | Fotos del modelo | Cualquier visor de imágenes |

**Para mirarlo en tu computadora:**
1. Instalá **OpenSCAD** y abrí `equipo_v1.scad`.
2. Arriba de todo, en la línea `pieza = "ensamble";`, podés poner `"ensamble_opaco"` (como se ve de verdad), `"ensamble_corte"` (cortado al medio) o `"explotado"` (piezas separadas).
3. Apretá **F5** para verlo. Con el mouse lo girás.

**Para imprimir una pieza:** abrí el `.stl` de `stl_v1/` en el programa de tu impresora; ya están acostados en la
posición correcta. La tabla de [montaje](montaje.md) dice material y si lleva soportes.

**Para cambiar una medida:** abrí el `.scad`, buscá el número (están todos arriba, con comentarios en español),
cambialo, apretá **F6** y exportá el STL (*Archivo → Exportar → STL*).
