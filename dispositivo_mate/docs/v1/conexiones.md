# Equipo v1 · Conexiones

## Pines del ESP32-C3 SuperMini

| GPIO | Va a | Notas |
|---|---|---|
| 0 | Encoder del rotor (canal A) | Pull-up interno |
| 1 | Encoder del sinfín (canal A) | Pull-up interno |
| 3 | Botón → GND | Pull-up interno; despierta del sueño profundo |
| 4 | Divisor de batería (100 kΩ arriba / 33 kΩ abajo) | 8,4 V → 2,08 V |
| 5 | DRV5032 (salida) | LOW = imán cerca = tapa de limpieza cerrada |
| 6 | DRV8871 IN1 | PWM 20 kHz |
| 7 | DRV8871 IN2 | PWM 20 kHz |
| 10 | 74AHCT125 entrada → anillo WS2812 DIN | Resistencia de 330 Ω en serie |
| 20 | TB6612 AIN1 | PWM 20 kHz |
| 21 | TB6612 AIN2 | PWM 20 kHz |
| 5V | Salida del MP1584 (5 V) | También alimenta el anillo LED y el 74AHCT125 |
| 3V3 | DRV5032, encoders, TB6612 VCC, PWMA y STBY | |
| GND | Común a todo | |

Quedan libres GPIO 2, 8 y 9 (son pines de arranque: usarlos solo como salidas que no se carguen al encender).

## Esquema de alimentación

```
USB-C ──► Cargador 2S (5 V → 8,4 V) ──► BMS 2S ──► 2×18650 en serie (6,0-8,4 V)
                                          │
                                          └─► Polyfuse 3 A ─┬─► Microinterruptor de la tapa ─► DRV8871 VM ─► Motor rotor (JGA25)
                                                            ├─► TB6612 VM ─► Motor sinfín (N20)
                                                            ├─► MP1584 (5 V) ─► ESP32 5V, anillo LED, 74AHCT125
                                                            └─► Divisor 100k/33k ─► GPIO 4
```

- El **microinterruptor de la tapa de limpieza** está en serie con la alimentación del motor del rotor:
  si se abre la tapa, el rotor se detiene **aunque el programa falle**. El sensor Hall avisa además al programa.
- Los motores son de 6 V y la batería llena da 8,4 V: el firmware **limita el PWM** para no pasarse de 6 V.
- El DRV8871 limita la corriente con una resistencia en el pin ILIM: con **30 kΩ ≈ 2,2 A**
  (fórmula del fabricante: I = 64 / R en kΩ). Medila en tu módulo; muchos traen 30 kΩ.

## Motores

| Motor | Driver | Salida | Encoder |
|---|---|---|---|
| Rotor (JGA25-370) | DRV8871 OUT1/OUT2 | — | Canal A → GPIO 0, VCC 3,3 V |
| Sinfín (N20) | TB6612 AO1/AO2 | — | Canal A → GPIO 1, VCC 3,3 V |

Si un motor gira al revés, **invertí sus dos cables** (no hace falta tocar el programa).

## Antes de enchufar

1. Con el multímetro, ajustá el MP1584 a **5,0 V** sin nada conectado.
2. Revisá que no haya corto entre batería + y GND.
3. Conectá primero solo el ESP32 por USB y cargá el firmware.
4. Después conectá la batería y probá cada motor desde el monitor serie.
