# Firmware del equipo v1

[`dispositivo_mate/dispositivo_mate.ino`](dispositivo_mate/dispositivo_mate.ino) — ESP32-C3 SuperMini.

## Instalar

1. Arduino IDE 2 → Gestor de placas → **esp32** de Espressif (versión 3.x).
2. Gestor de librerías → **Adafruit NeoPixel**.
3. Placa: **ESP32C3 Dev Module**, "USB CDC On Boot: Enabled".
4. Abrí el `.ino`, conectá por USB-C y subilo.

> **Estado:** se revisó que el código no tenga errores de sintaxis, pero **todavía no se compiló
> con el núcleo ESP32 real ni se probó en una placa**. Puede necesitar ajustes menores.

## Qué hace

- Máquina de estados: reposo → limpieza → esperar que des vuelta el mate → carga → listo.
- **Seguridad**: no limpia con la tapa abierta y frena el rotor si se abre (además del corte por hardware).
- **Atascos**: si el sinfín deja de girar, retrocede media vuelta y reintenta 3 veces; si el rotor se frena, cambia de sentido.
- **Dosis por vueltas** (encoder), con antigoteo al final.
- **Batería**: no arranca por debajo de 6,6 V y avisa por debajo de 7,0 V.
- **Sueño profundo** después de 2 minutos sin uso; el botón lo despierta.

## Valores a medir y ajustar

| Constante | Valor por defecto | Cómo medirla |
|---|---|---|
| `PULSOS_POR_VUELTA` | 7 × 298 | Pulsos del encoder × reducción del N20 que compres |
| `gramos_por_vuelta` | 1,46 | Calibración con balanza (mantener el botón 6 s) |
| `dosis_g` | 30 | `d=30` por el monitor serie |
| `LIMPIEZA_TRAMO_MS`, `LIMPIEZA_TRAMOS` | 2,5 s × 6 | Según cuánto tarde en limpiar |
