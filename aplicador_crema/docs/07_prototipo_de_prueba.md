# 7. Prototipo de prueba: 1 o 2 unidades para ver si es viable

La idea es **no comprarlo todo de golpe**. Se avanza en 3 etapas y al final de cada una hay una **decisión**: seguir, ajustar o parar. Lo más arriesgado (que la bomba empuje *tu* crema) se comprueba primero y con el menor gasto posible.

| Etapa | Qué compruebas | Gasto 1 ud | Gasto 2 uds | Tiempo |
|---|---|---|---|---|
| **1. Bomba en la mesa** | ¿Empuja tu crema? ¿La dosis sale igual cada vez? ¿Gotea? | ≈ 45 € | ≈ 50 € | 1 fin de semana |
| **2. Aparato completo** | Batería, botones, sensor de contacto, sueño, salpicaduras | ≈ 35 € | ≈ 60 € | 1–2 fines de semana |
| **3. Uso real** | ¿Llegas a toda la espalda? ¿Es cómodo? ¿Se limpia bien? ¿Falla? | ≈ 22 € (silicona) | ≈ 22 € | 2 semanas usándolo |
| **Total** | | **≈ 100 €** | **≈ 130 €** | |

La 2ª unidad sale más barata porque comparte packs: jeringas, varillas, rodamientos, muelles, silicona y grasa.

**Además, si no los tienes:**
- **Herramientas:** soldador, multímetro, pie de rey, broca escalonada y sierra, ≈ 65 €.
- **Impresión 3D:** un servicio online cobra ≈ 35 € por unidad (PETG).
- **Báscula de cocina con precisión de 0,1 g** (≈ 10 €), para medir las dosis. Muy recomendable.

---

## Etapa 1 · La bomba en la mesa (¿empuja tu crema?)

### Compra

| Qué | Buscar | 1 ud | 2 uds | ≈ € (1 / 2) |
|---|---|---|---|---|
| Microcontrolador | `ESP32-C3 SuperMini` | 1 | 2 | 3 / 6 |
| Motor | `N20 6V 150rpm` (1:210) | 1 | 2 | 3 / 6 |
| Motor de repuesto, más fuerte | `N20 6V 100rpm` (1:298), por si tu crema es muy densa | 1 | 1 | 3 |
| Driver | `TB6612FNG módulo` | 1 | 2 | 2 / 4 |
| Varilla roscada | M5 inox 1 m + 4 tuercas M5 + 2 arandelas (por unidad) | 1 | 1 (+4 tuercas) | 3 / 4 |
| Varilla guía | M4 inox o acero plata Ø4, 1 m | 1 | 1 | 2 |
| Rodamientos | `625ZZ` pack de 10 | 1 | 1 | 3 |
| Acoplador | `acoplador rígido 3mm 5mm` | 1 | 2 | 2 / 4 |
| Final de carrera | `KW10 micro switch palanca` (pack) | 1 | 1 | 1 |
| Jeringas | 60 ml **punta catéter**, pack de 10 | 1 | 1 | 6 |
| Tubo de crema | Silicona platino 6 × 9 mm, 1 m | 1 | 1 | 4 |
| Tubo PVC | Evacuación Ø40, 1 m (ferretería) | 1 | 2 | 3 / 6 |
| Tornillería | M3 × 10 autorroscantes, M4 × 40 + tuerca mariposa | 1 | 2 | 2 / 3 |
| Grasa | Grasa de silicona grado alimentario | 1 | 1 | 3 |
| Montaje de prueba | **Protoboard + cables dupont** (sin soldar nada) | 1 | 1 | 4 |
| | | | **Total** | **≈ 45 / 50 €** |

### Imprimir (PETG)

`soporte_motor`, `carro`, `tapa_superior`, `plantilla_taladro`. Son unas 9 h de impresora.

### Montaje provisional
1. Monta la mecánica como en `03_montaje_mecanico.md` (pasos 1–6): tubo cortado, soporte del motor con rodamiento, carro y guía.
2. **Electrónica en la protoboard, sin soldar:** ESP32-C3, TB6612 y final de carrera, con las conexiones de `02_esquema_conexiones.md`. Diferencia: **sin batería**. El TB6612 VM va al pin **5V** del ESP32, y todo se alimenta del USB del ordenador. Un N20 de 6 V funciona bien a 5 V.
3. Carga **`firmware/prueba_banco/prueba_banco.ino`** y abre el monitor serie a 115200 baudios, con "Nueva línea".

### Pruebas (anota todo en `08_hoja_de_resultados.md`)

| # | Prueba | Cómo | ✅ Bien si… |
|---|---|---|---|
| 1.1 | Sentido de giro | `a 3` con el carro fuera del tubo | El carro **sube**. Si baja, cambia `INVERTIR_MOTOR` o invierte los cables del motor |
| 1.2 | Final de carrera | `e` y pisa el microinterruptor con el dedo; luego `h` | Pone "PISADO", y `h` vuelve y para solo |
| 1.3 | Velocidad en vacío | Fuera del tubo: `h`, marca la posición, `a 10` y mide con el pie de rey cuánto ha subido | 10–16 mm en 10 s (1,0–1,6 mm/s) |
| 1.4 | Resistencia | Sin jeringa: `c 100` | Termina los 100 ciclos, el motor solo se pone **templado**, el acoplador no patina y la varilla no se afloja |
| 1.5 | **Empuje con tu crema** ⭐ | Jeringa llena montada. `h`, luego `a` hasta que salga crema por el tubo. Después `d 10` sobre la báscula | Salen **≥ 3 g en 10 s** (≥ 0,3 ml/s) y el motor no se para ni "zumba" atascado |
| 1.6 | **Repetibilidad** ⭐ | 10 veces `d 3`, pesando cada dosis | Ninguna dosis se aleja más de un **±15 %** de la media |
| 1.7 | Goteo | Tras una `d 3`, espera 30 s con la salida hacia abajo | Como mucho cae **1 gota** |

### 🔶 Decisión de la etapa 1
- **1.5 y 1.6 bien** → la idea funciona con tu crema. **Pasa a la etapa 2.**
- **1.5 justo** (sale poca crema o el motor va forzado) → cambia al **N20 de 100 rpm** (1:298), que tiene un 40 % más de fuerza, y repite.
- **1.5 sigue mal con el N20 de 100 rpm** → tu crema es demasiado densa para este diseño. Opciones: acortar el tubo de crema, usar tubo de 8 mm, o probar con una crema algo más fluida. Si nada funciona, **para aquí**: solo habrás gastado ≈ 45 €, y gran parte (ESP32, jeringas, motor) se reutiliza en otros proyectos.
- **1.7 gotea** → sube `ANTIGOTEO_MS` en el firmware normal (por ejemplo a 500).

Con los resultados de la báscula calcula **`MM_POR_SEGUNDO`** para el firmware normal:

`MM_POR_SEGUNDO = (gramos en 10 s ÷ 10) ÷ ML_POR_MM`

(con la jeringa de 60 ml, `ML_POR_MM` = 0,573).

---

## Etapa 2 · El aparato completo

### Compra

| Qué | Buscar | 1 ud | 2 uds | ≈ € (1 / 2) |
|---|---|---|---|---|
| Batería | 18650 **de marca** (Samsung, LG, Molicel) | 1 | 2 | 6 / 12 |
| Portapilas | 18650 de 1 celda con cables | 1 | 2 | 1 / 2 |
| Cargador | `TP4056 Type-C con protección` | 1 | 2 | 1 / 2 |
| Interruptor | `MTS-102` mini palanca | 1 | 2 | 1 / 2 |
| Pulsadores | Metálicos 12 mm IP65, momentáneos, cuerpo corto | 2 | 4 | 4 / 8 |
| Sensor de contacto | Microinterruptor **IP67** con palanca y cables | 1 | 2 | 2 / 4 |
| Muelle | `surtido muelles compresión inox` (trae el de Ø12 × 10) | 1 | 1 | 6 |
| Tornillos M2 | Surtido M2 inox | 1 | 1 | 3 |
| Cable | Silicona de 2 hilos 26 AWG, 1 m | 1 | 2 | 1 / 2 |
| Electrónica varia | Kit de resistencias y condensadores, placa perforada, LED de 5 mm con portaled, termorretráctil | 1 | 1 (+1 placa) | 8 / 10 |
| Tapón | Tapón PVC Ø40 (ferretería) | 1 | 2 | 0,5 / 1 |
| | | | **Total** | **≈ 35 / 60 €** |

### Imprimir

`trineo`, `plantilla_tapon`, `pinza_cable` (×3) y **`paleta`** en TPU, o en PETG si no tienes TPU. Esta paleta es solo provisional; la definitiva es la de silicona de la etapa 3.

### Montaje
Suelda la electrónica en la placa perforada (`02_esquema_conexiones.md`), monta el sensor y la cabeza (`03_montaje_mecanico.md`), y carga el **firmware normal** `aplicador_crema.ino` con `MM_POR_SEGUNDO` calculado en la etapa 1. Para las pruebas 2.1–2.3 puedes volver a cargar `prueba_banco.ino`.

### Pruebas

| # | Prueba | Cómo | ✅ Bien si… |
|---|---|---|---|
| 2.1 | Lectura de batería | `b` en `prueba_banco`, y mide la batería con el multímetro | Coinciden con ±0,05 V |
| 2.2 | Botones y sensor | `e` y pulsa cada cosa | Cada una aparece al pulsarla y desaparece al soltar |
| 2.3 | **Sensor de contacto** ⭐ | Firmware normal: apoya la paleta en el antebrazo 20 veces, y 20 veces pulsa DOSIS con la paleta en el aire | **20/20** sale crema al apoyar y **0/20** con la paleta en el aire |
| 2.4 | Levantar a mitad | Pulsa DOSIS, levanta la paleta a mitad y vuelve a apoyar | Se para al levantar y completa la dosis al volver a apoyar |
| 2.5 | Consumo dormido | Multímetro en mA, en serie con la batería, tras 2 min sin uso | ≤ 3 mA (o ≤ 1 mA si quitaste el LED rojo del SuperMini) |
| 2.6 | Despertar | Pulsa un botón con el aparato dormido | Despierta y la 1ª pulsación no suelta crema |
| 2.7 | Salpicaduras | Rocía el mango con un pulverizador 30 s y sécalo | Sigue funcionando y no entra agua por los botones ni el tapón |
| 2.8 | Peso | Báscula, con la jeringa llena | Anótalo (orientativo: 450–550 g) |

### 🔶 Decisión de la etapa 2
- **2.3 bien** → pasa a la etapa 3.
- **El sensor falla a veces** → ajusta la palanca (ver `03_montaje_mecanico.md`). Si sigue fallando, pon `REQUIERE_CONTACTO = false` y continúa: el aparato funciona igual, solo pierdes esa función.

---

## Etapa 3 · Uso real (2 semanas)

### Compra
Kit de silicona de platino apta para piel, Shore 20–30A, 500 g (≈ 18 €), y desmoldeante (≈ 4 €). Imprime `alma_paleta`, `molde_paleta_base` y `molde_paleta_tapa` y cuela la paleta (`03_montaje_mecanico.md`).

### Pruebas (en la hoja de resultados hay una tabla diaria)

| # | Prueba | ✅ Bien si… |
|---|---|---|
| 3.1 | **Alcance**: ¿cubres sin ayuda espalda alta, espalda baja, parte de atrás de las piernas y pies? | Todas las zonas, o todas menos una |
| 3.2 | Tiempo total de aplicación | Igual o menos que como lo haces ahora |
| 3.3 | Comodidad (peso, agarre, botón) de 1 a 5 | ≥ 4 |
| 3.4 | Piel: rojeces o roces por la paleta | Ninguno |
| 3.5 | Limpieza tras cada uso | < 5 minutos y sin restos en la paleta ni en la cabeza |
| 3.6 | Fallos en 14 días (atascos, sensor, batería, goteo) | 0–1 fallos leves y ninguno grave |
| 3.7 | Batería | Anota cuántos días aguanta con una carga (orientativo: semanas) |

### 🔶 Decisión final

| Resultado | Qué hacer |
|---|---|
| Todo bien, o casi todo | **Es viable.** Apunta las mejoras que se te ocurran y, si quieres más unidades, sigue `06_costes.md` |
| Funciona, pero algo concreto molesta (peso, ángulo del brazo, tamaño de la paleta…) | Es viable con cambios. Casi todo se ajusta con una variable del `.scad`: `brazo_45`, `pal_l`, `pal_a`, `DOSIS_ML`… |
| No llegas a la espalda o es más incómodo que a mano | Replantear la forma, por ejemplo un mango más largo o articulado, antes de fabricar más |

---

## Consejos para no perder tiempo ni dinero
- **Mide antes de imprimir:** la jeringa, el tubo de PVC, el motor y los microinterruptores varían según el vendedor. Ajusta la sección `MEDIDAS` del `.scad`.
- **Imprime primero el `carro` y el `soporte_motor`** y prueba que encajan en tu tubo antes de imprimir lo demás.
- **No tires nada** si una etapa falla: el ESP32, el motor y las jeringas sirven para el siguiente intento.
- **La 2ª unidad**, si la haces, móntala cuando la 1ª haya pasado la etapa 1. Así la montas ya con las correcciones.
