# 6. Costes

> Son **estimaciones** a partir de precios típicos de AliExpress, ferreterías y talleres en España (noviembre de 2026). Sirven para orientarse, **no** para presupuestar una venta: antes de comprometer un precio, pide presupuestos reales.

## 1. Prototipo (1 unidad)

| Concepto | Coste |
|---|---|
| Electrónica (ESP32-C3, motor, driver, cargador, batería, botones, sensor, varios) | ≈ 30 € |
| Mecánica (tubo y tapón de PVC, varillas, rodamiento, jeringas, tubo de silicona, muelle, tornillería) | ≈ 29 € |
| Filamento PETG (≈ 120 g) | ≈ 2 € |
| Silicona de la paleta (25 ml) | ≈ 0,80 € |
| **Total en piezas** | **≈ 61 €** |
| **Lo que pagas de verdad la primera vez** (packs mínimos: kit de silicona, surtido de muelles, rodamientos, resistencias…, más protoboard para probar y un motor de repuesto) | **≈ 100 €** (2 unidades: ≈ 130 €). Desglose por etapas en `07_prototipo_de_prueba.md` |

Lo que sobra de los packs te vale para repuestos o para una segunda unidad, que costaría unos 30 € más.

**Si no tienes herramientas:** soldador, multímetro, pie de rey, broca escalonada y sierra, unos 60–70 €. **Sin impresora**, un servicio de impresión online cobra unos 25–40 € por todas las piezas.

**Tiempo:** unas 14 h de impresión (la impresora trabaja sola), 6–8 h de montaje, soldadura y colada de la paleta, y 1 h de calibración.

**Coste de uso:** prácticamente cero. La carga de la batería cuesta céntimos al año, cada jeringa vale unos 0,50 € y se reutiliza, y la paleta dura mucho. No cuento la crema.

## 2. Producción en serie SIN moldes de inyección (recomendado hasta ~5.000 unidades)

Supuestos: mano de obra a 20 €/h; piezas rígidas impresas en PETG en impresoras propias; paleta de silicona colada en moldes impresos; tapón de PVC estándar.

| Por unidad | 10 uds | 100 uds | 1.000 uds |
|---|---|---|---|
| Componentes | 35 € | 22–25 € | 15 € |
| Piezas impresas (material + desgaste de impresora) | 3 € | 4 € | 4 € |
| Paleta de silicona | 1 € | 1 € | 0,80 € |
| Impresoras (4 × ≈ 750 €, repartidas entre las unidades) | — (la tuya) | — (la tuya) | 3 € |
| Montaje, colada y prueba | 3 h → 60 € | 1,5 h → 30 € | 40 min → 13 € |
| Embalaje y manual | 2 € | 2 € | 1,5 € |
| **Total por unidad** | **≈ 100 €** | **≈ 60 €** | **≈ 37–40 €** |

- **A 100 unidades:** compensa encargar una placa electrónica propia, ya montada en fábrica (≈ 5–8 € por unidad). Elimina casi toda la soldadura a mano, que es lo que más tiempo lleva.
- **Capacidad de producción:** cada juego de piezas tarda unas 12 h en imprimirse, así que con 4 impresoras salen unas 8 unidades al día (1.000 en unos 6 meses). Con boquilla de 0,6 mm en las piezas no críticas se puede acelerar.
- **Paletas:** cada molde da una paleta al día. Con 4–6 moldes (≈ 1 € de filamento cada uno) se sigue el ritmo de las impresoras.

### Alternativas para las piezas rígidas

| Método | Piezas por unidad | Cuándo |
|---|---|---|
| Impresión FDM propia (lo de arriba) | ≈ 4 € | Casi siempre |
| Servicio de impresión profesional en nylon sinterizado (SLS/MJF) | ≈ 30–45 € | Lotes pequeños donde importa el aspecto (presentaciones, primeras ventas) |
| Colada en silicona (copias de poliuretano) | ≈ 10–15 € + 2.000–3.000 € en moldes cada ~25 copias | No compensa en este producto |

## 3. Producción CON moldes de inyección

| Por unidad | 1.000 uds | 10.000 uds |
|---|---|---|
| Componentes | 15 € | 12 € |
| Piezas inyectadas | 2 € | 1,5 € |
| Moldes (20.000–40.000 € repartidos) | 20–40 € | 2–4 € |
| Montaje y prueba | 10 € | 6 € |
| Embalaje | 1,5 € | 1 € |
| **Total** | **≈ 50–70 €** | **≈ 23–25 €** |

**Punto de equilibrio:** los moldes solo salen más baratos que la impresión a partir de unas **5.000–6.000 unidades**.

## 4. Costes fijos para vender en la UE

| Concepto | Orientativo |
|---|---|
| Marcado CE: ensayos de compatibilidad electromagnética y seguridad | 3.000–8.000 € |
| Batería de litio: certificado de transporte UN38.3 y etiquetado según la normativa europea de baterías | 500–2.000 € (o comprar celdas o packs ya certificados) |
| Diseño de la placa electrónica propia | 500–1.500 € |
| Seguro de responsabilidad civil de producto | 300–1.000 €/año |

**Recomendaciones para una versión comercial:**
- **Cambiar el ESP32-C3 por un microcontrolador sin radio** (≈ 0,30 €). El ESP32 tiene WiFi y Bluetooth, aunque no se usen, y eso puede obligar a ensayos de radio más caros.
- **Cuidar cómo se anuncia.** Si se vende como "aplicador de crema", es un producto de consumo. Si se presenta como tratamiento para dermatitis u otra enfermedad, podría considerarse producto sanitario, con requisitos mucho más caros. Conviene confirmarlo con un especialista en normativa antes de vender.

## 5. Precio de venta orientativo

Lo habitual es multiplicar el coste de fabricación por 2,5–4. Eso cubre margen, tienda, devoluciones y garantía.

| Serie | Coste | Precio de venta orientativo |
|---|---|---|
| 100 uds sin moldes | ≈ 60 € | 150–240 € |
| 1.000 uds sin moldes | ≈ 40 € | 100–160 € |
| 10.000 uds con moldes | ≈ 25 € | 65–100 € |
