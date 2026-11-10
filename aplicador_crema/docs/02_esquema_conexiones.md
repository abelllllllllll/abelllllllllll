# 2. Esquema de conexiones

## La idea en términos de maquinaria

| Componente | Equivale a… |
|---|---|
| **Batería 18650** | El depósito de energía: 3,0 V vacía, 3,7 V nominal, 4,2 V llena |
| **TP4056** | Cargador más relé de protección: corta si la batería se sobrecarga o se vacía demasiado |
| **Interruptor general** | El seccionador. Para guardar el aparato mucho tiempo, déjalo en OFF |
| **ESP32-C3** | El autómata (PLC): lee botones y sensores y manda señales |
| **TB6612** | El inversor de giro con variador: con 2 señales eliges el sentido y con la tercera (PWM) la velocidad. El PLC no puede mover el motor directamente, igual que una salida de PLC no arranca un motor sin contactor |
| **Final de carrera** | Exactamente lo mismo que en una máquina: marca el "cero" del carro |
| **Sensor de contacto** | Un detector de presencia de pieza: la paleta se hunde al apoyarla en la piel y cierra el contacto. Funciona como el enclavamiento de una máquina: sin pieza, no hay ciclo |
| **Divisor 100k/100k** | Un "reductor de señal": baja la tensión de la batería a la mitad para que el PLC la pueda medir sin dañarse |
| **Resistencias de 10 k en los botones** | Mantienen la entrada en "1" mientras no pulsas. Pulsar la lleva a GND ("0") |

## Diagrama

```
                         ┌──────────── TP4056 USB-C ────────────┐
   18650 (+) ────────────┤ B+                              OUT+ ├──── INTERRUPTOR ──┬─── VBAT (+3,0…4,2 V)
   18650 (−) ────────────┤ B−                              OUT− ├───────────────────┼─── GND
                         └──────────────────────────────────────┘                   │
                                                                                      │
   VBAT ──┬──────────────► ESP32-C3 pin "5V"   (su regulador saca 3,3 V)             │
          ├──────────────► TB6612 VM  ──┬── 100 µF ── GND   (lo más cerca del TB6612)│
          └── 100 kΩ ──┬──► ESP32 GPIO4  (lectura de batería)                        │
                       ├── 100 kΩ ── GND                                             │
                       └── 100 nF ── GND                                             │
                                                                                      │
   ESP32 3V3 ────────────► TB6612 VCC                                                 │
   ESP32 GND ────────────► TB6612 GND (los dos)  ─────────────────────────────────────┘

   ESP32 GPIO0  ─────────► TB6612 AIN1          TB6612 AO1 ───► motor N20 (+)
   ESP32 GPIO1  ─────────► TB6612 AIN2          TB6612 AO2 ───► motor N20 (−)
   ESP32 GPIO10 ─────────► TB6612 PWMA
   ESP32 GPIO21 ─────────► TB6612 STBY          (BIN1, BIN2, PWMB: sin conectar)

   3V3 ── 10 kΩ ──┬──► GPIO3      BOTÓN DOSIS:   una pata a GPIO3, otra a GND
                  └── botón ── GND
   3V3 ── 10 kΩ ──┬──► GPIO5      BOTÓN RETRAER: igual, en GPIO5
                  └── botón ── GND

   GPIO6 ───────────── final de carrera "NO" (normalmente abierto);  "COM" ── GND
   3V3 ── 10 kΩ ──┬──► GPIO7      SENSOR DE CONTACTO (microinterruptor estanco de la paleta)
                  ├── 100 nF ── GND          (filtra ruido: el cable mide ~60 cm)
                  └── "NO" del sensor;  "COM" del sensor ── GND
   GPIO20 ── 330 Ω ──► LED (+, pata larga);   LED (−) ── GND
```

## Tabla de pines del ESP32-C3 SuperMini

| Pin | Va a | Para qué |
|---|---|---|
| 5V | VBAT (tras el interruptor) | Alimentación del ESP32 |
| GND | GND común | — |
| 3V3 | TB6612 VCC y las dos resistencias de 10 k | Alimentación lógica |
| GPIO0 | TB6612 AIN1 | Sentido de giro |
| GPIO1 | TB6612 AIN2 | Sentido de giro |
| GPIO10 | TB6612 PWMA | Velocidad (PWM a 20 kHz) |
| GPIO21 | TB6612 STBY | Driver activo o en reposo |
| GPIO3 | Botón DOSIS | También despierta del sueño |
| GPIO5 | Botón RETRAER | También despierta del sueño |
| GPIO4 | Punto medio del divisor | Mide la batería |
| GPIO6 | Final de carrera trasero | Cero del carro |
| GPIO7 | Sensor de contacto de la paleta | Solo sale crema con la paleta apoyada |
| GPIO20 | LED con 330 Ω | Estado |

No uses GPIO2, GPIO8 ni GPIO9: son pines de arranque del chip.

## Paso a paso

1. **Antes de soldar nada**, comprueba con el multímetro qué pata del pulsador conecta al apretar y cuáles son NO y COM en el final de carrera.
2. **Placa perforada:** suelda el ESP32-C3 y el TB6612 con tiras de pines, para poder sacarlos. Añade las resistencias de 10 k, el divisor 100k/100k con su condensador de 100 nF, y el condensador de 100 µF entre VM y GND del TB6612, respetando la polaridad: la franja blanca es el negativo.
3. **Tira de GND común:** todo lo que diga GND va al mismo punto. Es el error más típico.
4. **Primera prueba sin batería:** conecta solo el USB del ESP32 al ordenador y carga el firmware (ver `04_uso_calibracion_limpieza.md`). En el monitor serie debe aparecer "Aplicador listo". Al pulsar los botones, el LED tiene que reaccionar.
5. **Motor:** conecta el N20 a AO1 y AO2. Sin jeringa, pulsa DOSIS. Si el carro baja en vez de subir, invierte los dos cables del motor o pon `INVERTIR_MOTOR = true`.
6. **Batería:** con el interruptor en OFF, pon la celda en el portapilas y comprueba la polaridad con el multímetro antes de conectar al TP4056: + en B+, − en B−. Luego pasa el interruptor a ON.
7. **Sensor de contacto:** el cable baja por dentro del brazo, sale por un lateral del collarín de la tapa superior y va por fuera del tubo, sujeto con 3 pinzas impresas, hasta el agujero de Ø4 de la cara trasera. Allí entra y va por el canal interior hasta la placa. Deja **unos 10 cm de cable sobrante** junto a la tapa superior, para poder sacarla al cambiar la jeringa. Sella el agujero de entrada con silicona neutra. Para comprobarlo, con el monitor serie abierto, pulsa DOSIS con la paleta en el aire: debe decir "Esperando contacto". Al apoyar la paleta, el motor arranca.
8. **Comprobación final de la batería:** mide la tensión real en la celda y compárala con la que dice el monitor serie. Si difieren más de 0,05 V, corrige `DIVISOR_BATERIA`.

## Avisos

- ⚠️ **Para programar por USB, pon el interruptor general en OFF.** Así nunca se juntan el USB y la batería.
- La celda 18650 nunca se suelda directamente: usa el portapilas.
- **Consumo en reposo:** dormido gasta alrededor de 1–3 mA, la mayor parte por el LED rojo de encendido del SuperMini. Con eso la batería dura varias semanas en reposo. Si quieres más, desuelda ese LED rojo. Para guardar el aparato mucho tiempo, apaga el interruptor.
- **Carga:** carga **fuera del baño**, con un cargador de móvil normal de 5 V. El LED rojo del TP4056 indica que está cargando y el azul o verde que ha terminado (se ven por la ventanita del tapón inferior).
