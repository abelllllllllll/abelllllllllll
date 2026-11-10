# Equipo v1 · Lista de materiales

Precios **orientativos** en euros, para **1 unidad** comprada en tiendas online de electrónica
(tipo AliExpress / Mercado Libre). Varían mucho según el país y el vendedor.

## Electrónica

| # | Componente | Cant. | Para qué | Precio aprox. |
|---|---|---|---|---|
| 1 | ESP32-C3 SuperMini | 1 | Cerebro | 3-4 € |
| 2 | Motorreductor **JGA25-370, 6 V, ~130 rpm, con encoder** | 1 | Rotor de limpieza (necesita fuerza) | 10-14 € |
| 3 | Motorreductor **N20, 6 V, ~200 rpm, con encoder** | 1 | Sinfín dosificador | 5-8 € |
| 4 | Driver **DRV8871** (módulo) | 1 | Motor del rotor (3,6 A, limita corriente solo) | 3-5 € |
| 5 | Driver **TB6612FNG** (módulo) | 1 | Motor del sinfín | 2-3 € |
| 6 | Anillo **WS2812B de 12 LEDs** (Ø ~37 mm) | 1 | Indicador alrededor del botón | 2-3 € |
| 7 | **74AHCT125** (o 74AHCT1G125) | 1 | Adapta la señal del LED de 3,3 V a 5 V | 0,5-1 € |
| 8 | Pulsador de 16 mm (momentáneo, sin traba) | 1 | Botón único | 1-2 € |
| 9 | Sensor Hall **DRV5032** (o interruptor reed) + imán Ø6×3 | 1+1 | Detecta la puerta cerrada | 1-2 € |
| 10 | **Microinterruptor** de puerta (5 A) | 1 | Corta el motor del rotor por hardware si se abre | 1 € |
| 11 | Baterías **18650 protegidas** de 2500-3000 mAh | 2 | En serie (2S, 7,4 V) | 8-12 € |
| 12 | Portapilas 2×18650 en serie | 1 | — | 1 € |
| 13 | **Cargador 2S USB-C** (módulo elevador, 5 V → 8,4 V, tipo IP2326) | 1 | Carga por USB-C | 3-4 € |
| 14 | **BMS 2S** (protección) | 1 | Sobrecarga, descarga y corto | 1-2 € |
| 15 | Regulador **MP1584** fijado a 5 V | 1 | ESP32 + LEDs | 1 € |
| 16 | Fusible rearmable (polyfuse) 3 A | 1 | Protección de sobrecorriente | 0,3 € |
| 17 | Resistencias 100 kΩ y 33 kΩ | 1+1 | Medir la batería | 0,1 € |
| 18 | Placa perforada 5×7 cm, cables, conectores JST-XH | — | Montaje | 3-5 € |
| | | | **Subtotal electrónica** | **≈ 45-65 €** |

## Mecánica y ferretería

| Componente | Cant. | Precio aprox. |
|---|---|---|
| Insertos roscados M3 (para calor) + tornillos M3 × 8/12/16 | kit | 6-8 € |
| Imanes de neodimio Ø6×3 (cierre de puerta y tapa de tolva) | 4 | 1-2 € |
| Acrílico transparente 2 mm (ventana de la puerta, ~100×110 mm) | 1 | 2-3 € |
| Varilla de acero Ø3 (eje de bisagras) o 2 clavos de 3 mm | 2 | 0,5 € |
| Patas de silicona autoadhesivas | 4 | 1 € |
| Cepillo de bombilla | 1 | 1-2 € |
| | **Subtotal** | **≈ 12-17 €** |

## Impresión 3D

| Material | Cantidad | Piezas | Precio aprox. |
|---|---|---|---|
| **ASA o PETG negro** | ~1,8 kg | Carcasas, techos, puerta, tapa | 35-45 € |
| **PETG natural** (sin pigmento) | ~250 g | Asiento, cubo, cajón, plato, dosificador, sinfín, columna | 5-7 € |
| **TPU 85A-95A** | ~30 g | Paletas del rotor | 1-2 € |
| | | **Subtotal** | **≈ 41-54 €** |

## Total del prototipo

**≈ 100-135 €** (el plan estimaba 80-120 €). Lo que más pesa es el plástico de las carcasas:
con paredes de 2,4 mm en vez de 3 mm se ahorra ~20 %.

## Herramientas

Impresora 3D con **al menos 230 mm en un eje y 220 mm de alto** (Bambu P1/X1/A1, Prusa MK4, Creality K1 Max…),
soldador, multímetro, balanza de cocina de 0,1 g, calibre.

> En una impresora de 220 × 220 mm (Ender 3) las carcasas no entran: hay que cortarlas en dos
> con el parámetro `D` o en el laminador, y unirlas con tornillos.
