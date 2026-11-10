# Revisión técnica del plan (antes de diseñar)

Esta es una lectura crítica del plan para detectar problemas **antes** de imprimir piezas.
Los números son **estimaciones de referencia**: hay que medirlos con tu mate y tu yerba.

---

## 🔴 Riesgos grandes (resolver en la Fase 1)

### 1. El mate probablemente no entra en 8 × 12 cm

> **Actualización:** se adoptó la medida del SketchUp (176 × 176 mm). Con el mate real (camionero, ~130 mm) el alto pasa a **200 mm**.
> Con 133 mm entra un mate de 85 mm, pero no queda lugar para que el sinfín y el tobogán dejen la yerba **por encima** de la boca.
> El modelo avisa en la consola si tu mate entra (`mate_alto`). Regla: **alto del equipo ≈ alto del mate + 70 mm**.

- Un mate de calabaza o de cerámica típico mide unos **7-9 cm de ancho y 8-11 cm de alto**.
- Con paredes de 2,5 mm, un cilindro de 8 cm deja **~7,5 cm de diámetro interior**.
- Si el mate va adentro, en el resto de la altura (1-4 cm) no caben motor, batería (la 18650 mide 65 × 18 mm), tolva, sinfín y depósito de residuos.

**Qué hacer:** medir 2-3 mates reales y decidir una de estas opciones:
- **A.** Agrandar el equipo (más o menos 10-11 cm de diámetro y 18-22 cm de alto).
- **B.** Que el mate quede **afuera**: el dispositivo se apoya boca abajo sobre la boca del mate o el mate se encastra debajo.
- **C.** Diseñar para un mate de tamaño fijo (por ejemplo un mate propio incluido con el equipo).

### 2. Limpiar y cargar piden posiciones opuestas

> **Decisión para el MVP:** limpiar **boca abajo** y que el LED pida **dar vuelta el mate** antes de cargar. Girarlo solo queda para una versión posterior.

- Para **sacar** la yerba usada conviene la boca del mate **hacia abajo** (la gravedad ayuda).
- Para **cargar** yerba nueva, la boca tiene que estar **hacia arriba**.

El plan hace las dos cosas en el mismo ciclo sin mover el mate. Hay que elegir: que el usuario dé vuelta el mate entre los dos pasos, un soporte que gire el mate, o una limpieza que funcione con la boca hacia arriba (más difícil).

### 3. El raspador rígido no llega a todo el interior

- La boca del mate es más angosta (~4-5 cm) que el interior, y la calabaza tiene forma irregular.
- La yerba húmeda se pega y se compacta.

**Qué hacer:** probar **paletas flexibles de silicona** que se abren al girar, en vez de un raspador rígido. Antes de imprimir, hacer la prueba a mano con un palito y aletas de silicona para ver qué porcentaje sale.

### 4. Un solo motor N20 para dos mecanismos

El plan lista **1 motor**, pero hay **dos mecanismos** (raspador y sinfín). Opciones:
- **Recomendado para el MVP:** **2 motores N20**. El TB6612FNG ya tiene 2 canales, así que solo agrega unos 3-5 € y permite probar cada mecanismo por separado (Fases 2 y 3).
- Alternativa: 1 motor con **rodamientos de un solo sentido** (un sentido de giro mueve el raspador y el otro el sinfín). Ahorra espacio pero complica el diseño.

---

## 🟡 Cambios de componentes sugeridos

| Componente del plan | Problema | Sugerencia |
|---|---|---|
| Sensor Hall **A3144** | Necesita **4,5 V mínimo**; con 3,3 V del ESP32-C3 puede fallar | **DRV5032** (funciona desde 1,65 V) o un **interruptor reed** |
| Corte de seguridad solo por software | Si el firmware se cuelga, el motor sigue | Que el sensor de tapa corte el pin **STBY** del TB6612 o poner un **microswitch en serie** con el motor |
| Anillo **WS2812** a 5 V | Con 5 V, la señal de 3,3 V del ESP32 queda justa | Alimentarlo directo de la batería (3,5-4,2 V) o usar **SK6812** |
| N20 **sin encoder** | Dosificar por tiempo varía con el nivel de la tolva | N20 **con encoder magnético** (dosificar por vueltas y detectar atascos) |
| Protección contra atascos | El TB6612 no mide corriente | Detectar atasco por encoder (no gira) o agregar resistencia shunt + ADC |
| Motor / batería | — | El TB6612 acepta la 18650 directo (2,5-13,5 V). Elegir N20 de 3-6 V según la prueba de par |

---

## 📐 Números de referencia

### Tolva de yerba
- Densidad aparente de la yerba: aproximadamente **0,3 g/cm³** (medirla con tu marca).
- 1 dosis de 8 g ≈ **27 cm³**.
- Con ~44 cm² de sección interior (diámetro de 7,5 cm): **cada dosis ocupa ~0,6 cm de altura**.
- **20 dosis (160 g) ≈ 530 cm³ ≈ 12 cm de altura de tolva.** En Ø80 no entra: una tolva lleva **3-5 dosis**.
- **Con el tamaño nuevo** (176 × 176 × 200 mm), la tolva trasera tiene ~570 cm³ ≈ **22 dosis** (ver `calculos/dosificador.py`).

### Depósito de residuos
- La yerba usada absorbe agua: 8 g secos pueden ser **25-30 g húmedos** y unos **40-60 cm³**.
- Hay que vaciarlo **cada 1-3 ciclos**, o separar el agua (rejilla y bandeja).

### Batería
- 18650 de 3000 mAh ≈ **10 Wh** útiles.
- Un ciclo de 45 s con motor a ~2 W + ESP32 + LEDs ≈ **0,03-0,05 Wh**, o sea **más de 150 ciclos** en teoría.
- Los 20 ciclos se cumplen sin problema. Lo que más gasta es el **consumo en reposo**: usar el *deep sleep* del ESP32-C3 y despertar con el botón.

### Dosificación (CV < 15 %)
- Es alcanzable con sinfín si se dosifica **por vueltas** (encoder) y no por tiempo.
- La yerba con mucho **polvo** o **palo** cambia el caudal: probar con 2-3 marcas.

---

## El mate real (camionero)

Según las fotos, el mate de referencia es un **camionero**: calabaza forrada (cuero o similar), **virola metálica ancha** con relieve y **base con patas**.

Medidas de camioneros en tiendas (cada mate es artesanal, así que varían):

| Fuente | Diámetro | Alto | Otros datos |
|---|---|---|---|
| Pampa Direct, camionero grande | ~100 mm | ~130 mm | — |
| YVY Mate, camionero | 100 mm | 115 mm | 250-350 ml, hasta 30 g de yerba |
| YVY Mate, camionero | 105 mm | 120 mm | — |
| Mate-tee.de, calabaza forrada | — | ~120 mm de profundidad | boca de ~70 mm |
| Mate Pampa camionero térmico | 90 mm | 85 mm | ~40 g de yerba (modelo chico) |

**Valores de diseño** (el caso más grande, para que entren todos):

| | Valor | De dónde sale |
|---|---|---|
| Alto total | 130 mm | Tiendas (máximo) |
| Diámetro máximo | 105 mm | Tiendas (máximo) |
| Boca interior | 70 mm | Tiendas |
| Alto de la virola | 25 mm | Estimado de la foto (no se publica) |
| Base con patas | 65 mm | Estimado de la foto (no se publica) |

### ⚠️ La dosis cambia: 30 g, no 7-9 g

Un camionero lleva **30-40 g** de yerba. Con 8 g quedaría casi vacío. Consecuencias:
- **Dosificador:** el paso del sinfín sube de 18 a **24 mm** y el motor a ~150 rpm: **~0,95 g por vuelta, ~32 vueltas y ~13 s por dosis** (estimado).
- **Tolva:** 570 cm³ ≈ 170 g ≈ **6 cebadas**. Para 20 harían falta ~600 g (2 litros de tolva), que no entran: la tolva se recarga cada ~6 usos.
- **Residuos:** 30 g de yerba usada mojada son ~150-200 cm³ por ciclo. El cajón (~113 × 120 × 30 mm ≈ 400 cm³) se vacía **cada 2 ciclos**.

**Lo bueno para el diseño:**
- **Boca ancha (~70 mm)**: las paletas de limpieza entran fácil, mucho mejor que en una calabaza de boca chica.
- **Virola plana y rígida**: es el apoyo ideal para poner el mate **boca abajo**. El aro de apoyo se diseña para que la virola apoye en todo su borde.
- **Base con patas**: boca arriba se queda firme para cargar la yerba.

**Lo que complica:**
- **Es alto**: por eso el equipo pasa a 200 mm de alto.
- **Forro de cuero**: no debe mojarse ni rasparse. Las paletas trabajan solo por adentro y el aro de apoyo toca solo la virola.
- **El borde de la virola junta yerba** (se ve en la foto, sobre todo en las letras en relieve). Conviene un **cepillo fijo** en el aro que limpie el borde mientras el rotor gira.
- **Yerba con mucho polvo y palo**: probar el dosificador con esta yerba. El polvo puede pasar por la luz entre el sinfín y el tubo.
- Hay mates camioneros de muchos tamaños: el aro de apoyo debería ser **intercambiable** (un aro por tamaño de virola).

## ✅ Qué falta

1. **Medir el mate con regla** (la tabla de arriba) y cargar las medidas en `mate_*` del `.scad`.
2. **Imprimir y probar el dosificador** ([Fase 2](fase2_banco_dosificador.md)).
3. Con los resultados, diseñar el **rotor de limpieza** (Fase 3) y probarlo con yerba húmeda.
