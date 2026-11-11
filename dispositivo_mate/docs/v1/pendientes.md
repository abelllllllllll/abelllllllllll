# Pendientes del diseño

Lista de trabajo para dejar el diseño lo más fino posible **antes de imprimir**.
Lo que dice "necesita prueba real" no se puede cerrar desde la computadora.

## Hecho

- [x] Equipo genérico de dos estaciones (bocas de 4 a 11 cm, mates de hasta 13 cm).
- [x] Simulación y receta de partida (sinfín Ø24 paso 30, N20 de 100 rpm).
- [x] Exterior minimalista: frente liso, tapa redonda, cajón al ras, tolva cilíndrica.
- [x] Sinfín y motor ocultos detrás del borde del nicho.
- [x] **Bandeja de electrónica**: portapilas, placa sobre 4 columnas, BMS y cargador con USB-C alineado al agujero de atrás.
- [x] **Soporte de sensores de la tapa** (Hall + microinterruptor) en el techo izquierdo.
- [x] **Paso de cables** entre la estación y la torre, elevado 11 mm sobre el piso (barrera de humedad).
- [x] **Tolva con paredes a 60°**, para que la yerba baje sola.
- [x] Rebajes para 4 patas de silicona.
- [x] **Simulaciones con 14 mates, 9 yerbas y 8 estados de la yerba** ([simulaciones.md](simulaciones.md)).
- [x] **Paleta media** (85 mm), **limpieza de 20 s**, **limpieza larga de 40 s** y **3 tamaños de dosis**.

## Diseño (se puede hacer sin imprimir)

| # | Pendiente | Por qué importa |
|---|---|---|
| 1 | **Encastres entre piezas**: techo-carcasa (pestañas o tornillos), tolva-cuello (traba de un cuarto de vuelta) | Hoy apoyan sueltos |
| 2 | **Cajón estanco con rejilla**: hoy tiene la ranura abierta abajo | El mate lavado deja hasta 40 ml de agua por ciclo |
| 2b | **Agitador en la tolva** | Las yerbas finas (uruguaya, chimarrão) hacen puente |
| 2c | **Versión alta y ancha** (`H`, `nicho_ancho`) | Torpedo, uruguayo de boca ancha y guampa no entran |
| 3 | **Tapa de limpieza con bisagra** en vez de suelta | Más cómodo y no se pierde |
| 4 | **Esquema eléctrico y placa (PCB) propia** en KiCad | Reemplaza la placa perforada y los módulos sueltos |
| 5 | **Fijación del motor N20 y su encoder** dentro del módulo derecho (hoy usa el soporte del banco) | Que no quede colgando |
| 6 | **Porta-bombilla y cepillo**: tubo cerrado por abajo para que no gotee adentro | Hoy son dos agujeros |
| 7 | **Bordes redondeados arriba** (chaflán) y texto/logo en relieve | Terminación |
| 8 | **Guías del cajón** y tope para que no se salga de golpe | Uso diario |
| 9 | **Firmware**: compilar con el núcleo ESP32 real y probar en un simulador (Wokwi) | Solo se revisó la sintaxis |
| 10 | **Versión para impresoras de 220 mm**: carcasas partidas en dos | Más gente puede imprimirlo |
| 11 | **Manual de uso y de limpieza** de una página | Para quien lo pruebe |

## Necesita prueba real

| # | Pregunta | Cómo se responde |
|---|---|---|
| A | ¿Las paletas sacan el 90 % de la yerba? | Asiento + rotor + mate usado, pesando antes y después |
| B | ¿Cuántos gramos da cada vuelta del sinfín? ¿Se traba? | Banco de prueba con balanza |
| C | ¿La yerba baja sola en la tolva de 60°? | Tolva + sinfín, hasta vaciarla |
| D | ¿Cuánto ruido hace? | Equipo armado |
| E | ¿Las medidas de encastre entran bien? | Primera impresión de cada pieza |
| F | ¿La yerba mojada llega a la electrónica? | 50 ciclos seguidos |

## Para venderlo

Plásticos aptos para alimentos, certificación eléctrica y de baterías, consulta de patente y costos de fabricación.
Ver [viabilidad_y_produccion.md](viabilidad_y_produccion.md).
