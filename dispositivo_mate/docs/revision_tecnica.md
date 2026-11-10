# Revisión técnica del plan (antes de diseñar)

Esta es una lectura crítica del plan para detectar problemas **antes** de imprimir piezas.
Los números son **estimaciones de referencia**: hay que medirlos con tu mate y tu yerba.

---

## 🔴 Riesgos grandes (resolver en la Fase 1)

### 1. El mate probablemente no entra en 8 × 12 cm

- Un mate de calabaza o de cerámica típico mide unos **7-9 cm de ancho y 8-11 cm de alto**.
- Con paredes de 2,5 mm, un cilindro de 8 cm deja **~7,5 cm de diámetro interior**.
- Si el mate va adentro, en el resto de la altura (1-4 cm) no caben motor, batería (la 18650 mide 65 × 18 mm), tolva, sinfín y depósito de residuos.

**Qué hacer:** medir 2-3 mates reales y decidir una de estas opciones:
- **A.** Agrandar el equipo (más o menos 10-11 cm de diámetro y 18-22 cm de alto).
- **B.** Que el mate quede **afuera**: el dispositivo se apoya boca abajo sobre la boca del mate o el mate se encastra debajo.
- **C.** Diseñar para un mate de tamaño fijo (por ejemplo un mate propio incluido con el equipo).

### 2. Limpiar y cargar piden posiciones opuestas

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
- **20 dosis (160 g) ≈ 530 cm³ ≈ 12 cm de altura de tolva.** No entra. Una tolva realista para este tamaño lleva **3-5 dosis**.

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

## ✅ Qué necesito para seguir

1. **El archivo SketchUp original** (`.skp`). Subilo a `dispositivo_mate/diseno_original/` o pasámelo, y lo reviso.
2. **Medidas de tu mate**: diámetro de la boca, diámetro máximo, altura y material.
3. **Decisión sobre los riesgos 1 y 2**: tamaño del equipo y cómo queda el mate (adentro o afuera, boca arriba o abajo).

Con eso se puede arrancar la **Fase 2 (dosificador)**, que es el mecanismo más independiente y fácil de validar primero: tolva, sinfín, motor y balanza.
