# 5. Precauciones

## Eléctricas

- **Muy baja tensión:** todo funciona entre 3 y 4,2 V. No hay ningún punto peligroso al tacto, ni aunque se moje.
- **La batería es lo único que pide respeto:**
  - Usa una celda de marca y siempre en portapilas, sin soldarla.
  - La protección del TP4056 corta a ~2,5 V y a 4,2 V. Además, el firmware deja de mover el motor a 3,3 V.
  - Carga fuera del baño, sobre una superficie no inflamable y sin taparlo.
  - Si la celda se hincha, se calienta o huele raro, retírala y llévala a un punto limpio.
- **Programar con el USB:** pon antes el interruptor general en OFF.

## Calor

- **Nada calienta.** El motor N20 consume menos de 0,3 A, y el TB6612 y el ESP32 trabajan en frío.
- Si el motor se queda bloqueado (crema seca o tubo obstruido), el firmware lo corta como mucho a los **20 s**. Un N20 aguanta eso sin calentarse de forma apreciable.

## Agua

- El tubo cerrado con las tapas aguanta **salpicaduras**. **No es sumergible.** Úsalo fuera de la ducha, con la piel ya secada con la toalla.
- Los pulsadores son IP65. Pon una gota de silicona neutra alrededor del LED y del interruptor del tapón inferior si quieres más protección.

## Piel y materiales

- **En contacto con crema o piel** solo hay silicona curada con platino (tubo y paleta, grado alimentario o apta para piel), PP médico (jeringa) e inox. Si usas la paleta impresa, también TPU. Todos se lavan con agua y jabón neutro y aguantan alcohol al 70 %.
- **Paleta:** la de **silicona colada** es la recomendada: lisa, sin poros y suave. Usa silicona de platino que indique "apta para contacto con la piel" o "grado alimentario", **nunca** silicona de estaño (condensación) ni silicona de construcción. La paleta impresa en TPU es una alternativa, pero tiene poros microscópicos entre capas: cámbiala si ves restos que no salen o si cambia de color.
- **No uses esponja:** retiene crema y crían bacterias.
- **Antes del primer uso**, prueba la paleta en una zona pequeña de piel (antebrazo) durante un par de días.
- **Sensor de contacto:** basta un apoyo suave (≈ 1–2 N) para activarlo. No hace falta apretar. Si alguna vez no responde, revisa que no haya crema seca en la palanca. Como último recurso, pon `REQUIERE_CONTACTO = false`.
- La paleta no tiene que hacer fuerza: el aparato solo lleva la crema. Si notas presión excesiva o roces, revisa los bordes de la paleta y lijalos.

## Mecánicas

- El aparato no puede pellizcar: todo lo que se mueve va dentro del tubo cerrado.
- Antes de sacar la tapa superior, pulsa RETRAER, para que la crema no esté a presión.
- **Si notas que el motor "se esfuerza" sin que salga crema**, suelta: hay crema seca en el tubo o en la paleta. Límpialos.

## Lo que no se ha podido probar sin el aparato físico

Todo el diseño se ha verificado con cálculo y simulación, pero hay valores que dependen de tu crema y de tus piezas concretas:

- **La viscosidad real de tu crema.** El cálculo cubre desde loción espesa hasta bálsamo. Si el motor va muy lento con la tuya, cambia al N20 de 100 rpm (1:298), que tiene más fuerza.
- **Las medidas exactas de tu jeringa, tubo y motor.** Mídelas y ajusta el `.scad` antes de imprimir.
- **La calibración de velocidad y recorrido:** se mide una vez (ver `04_uso_calibracion_limpieza.md`).
