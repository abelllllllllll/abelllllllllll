# 1. Lista de materiales (final)

Precios orientativos de AliExpress, noviembre de 2026. En Amazon.es suelen ser entre 1,5 y 2 veces más caros. **Total ≈ 59 €** sin contar el filamento de impresión, del que se usan unos 2 € (≈ 90 g de PETG y 20 g de TPU).

## Electrónica

| # | Qué | Cómo buscarlo | Cant. | ≈ € |
|---|---|---|---|---|
| E1 | Microcontrolador | `ESP32-C3 SuperMini` | 1 | 3 |
| E2 | Motorreductor | `N20 6V 150rpm` (reductora **1:210**). Si tu crema es un bálsamo muy denso, compra también uno de `100rpm` (1:298) | 1–2 | 3–6 |
| E3 | Driver de motor | `TB6612FNG módulo` | 1 | 2 |
| E4 | Cargador de batería | `TP4056 Type-C con protección` (6 pines: B+ B− OUT+ OUT−) | 1 | 1 |
| E5 | Batería | Celda **18650 de marca** (Samsung 30Q/35E, LG, Molicel, ~3000 mAh). **Evita** las genéricas que prometen "9900 mAh" | 1 | 6 |
| E6 | Portapilas | `portapilas 18650 1 celda con cables` | 1 | 1 |
| E7 | Interruptor general | `MTS-102 mini palanca 6mm` | 1 | 1 |
| E8 | Pulsadores | `pulsador metálico 12mm IP65 momentáneo` (de cuerpo corto, ≤ 14 mm) | 2 | 4 |
| E9 | Final de carrera | `KW10 micro switch palanca` (12,8 × 5,8 × 6,5 mm) | 1 | 1 |
| E9b | **Sensor de contacto** | `micro switch waterproof IP67 lever` con cables ya puestos (cuerpo ≈ 20 × 10 × 6,5 mm, tipo D2HW). **Tiene que ser estanco**: va en la punta, junto a la crema | 1 | 2 |
| E9c | Cable del sensor | Cable de silicona de **2 hilos** 26 AWG, 1 m (o 2 hilos sueltos y termorretráctil) | 1 | 1 |
| E10 | Varios | LED de 5 mm con portaled; resistencias 330 Ω (1), 10 kΩ (3) y 100 kΩ (2); condensadores 100 µF/16 V (1) y 100 nF (2); placa perforada de 5×7 cm; cable de silicona 26 AWG; termorretráctil | — | 5 |

## Mecánica y contacto con crema

| # | Qué | Cómo buscarlo / dónde | Cant. | ≈ € |
|---|---|---|---|---|
| M1 | Tubo del mango | Tubo PVC de evacuación **Ø40 mm** de 1 m (ferretería) | 1 | 3 |
| M2 | Husillo | Varilla roscada **M5 inox** de 1 m + 4 tuercas M5 inox + 2 arandelas | 1 | 3 |
| M3 | Guía | Varilla **M4 inox** o acero plata Ø4 (se usan 134 mm) | 1 | 2 |
| M4 | Rodamiento | `625ZZ` (5 × 16 × 5), en pack | 1 | 3 |
| M5 | Acoplador | `acoplador rígido 3mm 5mm` (Ø exterior ≤ 13 mm) | 1 | 2 |
| M6 | Tornillería inox | 1 tornillo M4×40 + tuerca mariposa M4; 3 tornillos autorroscantes M3×10; 2 tornillos M2×8 | — | 2 |
| M7 | Depósito | Jeringas **60 ml punta catéter**, estériles, pack de 5–10 (se usan como cartuchos intercambiables) | 5+ | 5 |
| M8 | Tubo de crema | Tubo de **silicona curada con platino, grado alimentario**, 6 × 9 mm, 1 m | 1 | 4 |
| M8b | Muelle de la paleta | Muelle de compresión **inox**, Ø exterior ≤ 12 mm, Ø interior ≥ 9,5 mm, largo ≈ 10 mm, hilo 0,5 mm. Se encuentra en los surtidos de muelles (`surtido muelles compresión inox`) | 1 | 1 |
| M8c | Pasador de la paleta | 1 tornillo M2 × 16 inox | 1 | — |
| M9 | Lubricante | Grasa de silicona **grado alimentario** (para la rosca y el tapón de goma) | 1 | 3 |
| M10 | Impresión 3D | PETG (piezas rígidas) + TPU 95A (paleta). Si no tienes impresora, sirve cualquier servicio de impresión online con los STL de `mecanica/stl/` | — | (2) |

**Herramienta:** soldador (con estaño y flux), multímetro, pie de rey, sierra para PVC, broca escalonada (5 y 12 mm), broca de 4 mm, destornilladores y llave de 8 mm.

## Por qué estos componentes

- **Jeringa empujada por husillo, y no bomba peristáltica.** El cálculo de `calculos/hidraulica.py` muestra que una peristáltica barata necesitaría 1,7 bar para mover una crema emoliente, más de lo que da. La jeringa solo necesita 0,25 bar y unos 30 N de fuerza, y además la dosis sale exacta en ml.
- **Una sola celda 18650 con TP4056.** Es lo más estándar, cabe en el tubo de 40 mm y el módulo ya protege contra sobrecarga y descarga excesiva. Todo el aparato funciona a **3–4,2 V**.
- **ESP32-C3.** Tiene sueño profundo con despertar por botón y memoria para recordar dónde está el carro.
- **TB6612.** Permite invertir el giro para el antigoteo y para retraer.
