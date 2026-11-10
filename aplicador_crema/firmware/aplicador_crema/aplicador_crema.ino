/*
 * ============================================================================
 *  APLICADOR DE CREMA MOTORIZADO  ·  Firmware para ESP32-C3 SuperMini
 * ============================================================================
 *
 *  Cómo funciona la máquina:
 *    Un motorreductor N20 gira una varilla roscada M5. Una tuerca metida en un
 *    "carro" sube por la varilla y empuja el émbolo de una jeringa de 60 ml
 *    llena de crema (igual que una pistola de silicona). La crema sale por un
 *    tubo corto hasta la paleta de la punta.
 *
 *  DETECCIÓN DE CONTACTO CON LA PIEL:
 *    La paleta está montada "flotante" sobre un muelle. Al apoyarla en la piel
 *    se hunde 2-3 mm y pisa un microinterruptor. La crema SOLO sale mientras
 *    la paleta está apoyada: si la levantas, el motor para (y retrocede un
 *    instante para que no gotee) y sigue cuando la vuelves a apoyar.
 *
 *  Uso:
 *    BOTÓN DOSIS
 *      · pulsación corta   -> dosis fija (DOSIS_ML). Puedes pulsar y luego
 *        apoyar: la dosis espera hasta ESPERA_CONTACTO_MS a que haya contacto.
 *      · mantener pulsado  -> sale crema mientras mantengas el botón Y la
 *        paleta apoyada.
 *      · pulsar durante una dosis -> la cancela.
 *    BOTÓN RETRAER
 *      · el carro vuelve atrás hasta el final de carrera para cambiar la
 *        jeringa. Pulsar cualquier botón lo detiene.
 *    ANTIGOTEO: tras cada dosis (y al levantar la paleta) el motor retrocede
 *      un instante para quitar presión y que la crema no siga saliendo.
 *    APAGADO AUTOMÁTICO: a los 2 minutos sin uso se duerme (consume casi nada).
 *      Se despierta con cualquier botón; esa pulsación solo despierta.
 *
 *  El firmware lleva la cuenta de por dónde va el carro (en mm) y la guarda
 *  en memoria aunque se apague el interruptor. Así sabe cuándo está vacía la
 *  jeringa sin necesitar un segundo final de carrera. La primera vez que se
 *  enciende no lo sabe: pide RETRAER una vez (LED con doble destello).
 *
 *  Arduino IDE:
 *    Placa:  "ESP32C3 Dev Module"  (gestor de placas: "esp32" de Espressif, 3.x)
 *    Tools > USB CDC On Boot > "Enabled"  (para ver mensajes en el monitor serie)
 *    Monitor serie a 115200 baudios.
 *
 *  Para ajustar el aparato solo hace falta tocar la sección AJUSTES.
 * ============================================================================
 */

#include <Arduino.h>
#include <Preferences.h>
#include <esp_sleep.h>

// ============================================================================
//  AJUSTES  (cambia estos valores a tu gusto)
// ============================================================================

// --- Dosis ---
const float DOSIS_ML = 2.0;            // ml que suelta una pulsación corta

// --- Contacto con la piel ---
const bool REQUIERE_CONTACTO = true;   // false = ignorar el sensor (si se estropea)
const unsigned long ESPERA_CONTACTO_MS = 5000;  // una dosis espera esto a que apoyes
                                                // la paleta; si no, se cancela

// --- Calibración (ver docs/04_uso_calibracion_limpieza.md) ---
const float ML_POR_MM       = 0.573;   // ml por mm de émbolo (jeringa 60 ml de Ø27 mm)
const float MM_POR_SEGUNDO  = 1.20;    // velocidad medida del carro a V_CALIBRACION
const float V_CALIBRACION   = 3.80;    // tensión de batería a la que mediste lo anterior
const float RECORRIDO_MAX_MM = 106.0;  // desde el final de carrera trasero hasta
                                       // "jeringa vacía" (se mide una vez)

// --- Botón ---
const unsigned long UMBRAL_MANTENER_MS = 400;  // más que esto = "mantener" (continuo)
const unsigned long ANTIRREBOTE_MS     = 30;   // filtro de rebotes de pulsadores y sensor

// --- Motor ---
const uint8_t VELOCIDAD_AVANCE   = 255;   // 0-255. 255 = máxima fuerza
const uint8_t VELOCIDAD_RETRAER  = 255;
const unsigned long ANTIGOTEO_MS = 300;   // retroceso tras cada dosis (0 = desactivado)
const bool INVERTIR_MOTOR        = false; // true si el motor gira al revés

// --- Seguridad ---
const unsigned long CONTINUO_MAX_MS   = 20000;   // máximo de un "mantener" seguido
const unsigned long RETRACCION_MAX_MS = 150000;  // máximo para volver atrás del todo

// --- Ahorro de batería ---
const unsigned long TIEMPO_APAGADO_MS = 120000;  // 2 minutos sin uso -> dormir

// --- Batería (una celda 18650 de litio) ---
const float DIVISOR_BATERIA = (100.0 + 100.0) / 100.0;  // resistencias 100k / 100k
const float BATERIA_BAJA_V  = 3.50;   // avisa (LED parpadea rápido): toca cargar
const float BATERIA_VACIA_V = 3.30;   // no mueve el motor y se duerme

// ============================================================================
//  PINES  (coinciden con docs/02_esquema_conexiones.md)
// ============================================================================
const uint8_t PIN_AIN1          = 0;   // TB6612 AIN1 (sentido)
const uint8_t PIN_AIN2          = 1;   // TB6612 AIN2 (sentido)
const uint8_t PIN_PWMA          = 10;  // TB6612 PWMA (velocidad)
const uint8_t PIN_STBY          = 21;  // TB6612 STBY (alto = driver activo)
const uint8_t PIN_BOTON_DOSIS   = 3;   // pulsador a GND + pull-up 10k a 3V3
const uint8_t PIN_BOTON_RETRAER = 5;   // pulsador a GND + pull-up 10k a 3V3
const uint8_t PIN_BATERIA       = 4;   // punto medio del divisor 100k/100k
const uint8_t PIN_FC_ATRAS      = 6;   // final de carrera trasero (a GND al pisarlo)
const uint8_t PIN_CONTACTO      = 7;   // microinterruptor de la paleta (a GND = apoyada)
const uint8_t PIN_LED           = 20;  // LED de estado (con resistencia 330 Ω)
const uint8_t PIN_LED_PLACA     = 8;   // LED azul de la placa (se enciende con LOW)

const uint32_t PWM_FRECUENCIA = 20000; // 20 kHz: el motor no pita
const uint8_t  PWM_RESOLUCION = 8;     // 0-255

// ============================================================================
//  ESTADO INTERNO  (no hace falta tocar nada de aquí hacia abajo)
// ============================================================================
enum Estado {
  REPOSO,          // esperando órdenes
  ESPERA_SOLTAR,   // esperar a que suelte el botón antes de aceptar otra orden
  AVANCE_PULSADO,  // botón recién pulsado; aún no sabemos si es corta o mantenida
  DOSIS_FIJA,      // pulsación corta: completando la dosis
  CONTINUO,        // mantener pulsado: avanzar mientras siga pulsado
  ANTIGOTEO,       // retroceso corto tras la dosis
  RETRAYENDO,      // volviendo atrás para cambiar jeringa
  SIN_BATERIA      // batería agotada: avisar y dormir
};

enum Movimiento { PARADO, AVANZAR, RETROCEDER };

// Pulsador o interruptor con antirrebote. "pulsado" ya está filtrado.
struct Boton {
  uint8_t pin;
  bool pulsado;
  bool lecturaAnterior;
  unsigned long cambioMs;
  bool flancoBajada;     // se acaba de pulsar (dura una vuelta de loop)
  bool flancoSubida;     // se acaba de soltar  (dura una vuelta de loop)
};

Estado estado = REPOSO;
Movimiento movimiento = PARADO;
uint8_t velocidadActual = 0;
Boton botonDosis   = {PIN_BOTON_DOSIS,   false, false, 0, false, false};
Boton botonRetraer = {PIN_BOTON_RETRAER, false, false, 0, false, false};
Boton sensorContacto = {PIN_CONTACTO,    false, false, 0, false, false};
Preferences memoria;

unsigned long inicioEstadoMs    = 0;
unsigned long ultimaActividadMs = 0;
unsigned long ultimaBateriaMs   = 0;
unsigned long ultimoCalculoMs   = 0;
float voltajeBateria   = 3.8;
float posicionMm       = 0;      // dónde está el carro (0 = atrás del todo)
float frenteMm         = 0;      // hasta dónde ha empujado ya el émbolo: a partir de
                                 // aquí, cada mm de avance es crema que sale
bool  posicionConocida = false;
bool  conocidaGuardada = false;
float posicionGuardada = -1;
float objetivoMm       = 0;      // dónde termina la dosis fija en curso

// Pausa por falta de contacto durante una dosis
bool enPausa = false;
unsigned long inicioPausaMs = 0;

bool hayContacto() { return !REQUIERE_CONTACTO || sensorContacto.pulsado; }

bool jeringaVacia() { return posicionConocida && frenteMm >= RECORRIDO_MAX_MM - 0.01; }

// Velocidad estimada del carro. El N20 va directo a la batería, así que gira
// más rápido con la batería llena: se compensa con la tensión medida.
float velocidadMmPorMs(uint8_t pwm) {
  return MM_POR_SEGUNDO / 1000.0 * (voltajeBateria / V_CALIBRACION) * (pwm / 255.0);
}

// ============================================================================
//  MEMORIA (posición del carro)
// ============================================================================
void guardarPosicion() {
  if (!posicionConocida) return;
  if (!conocidaGuardada) { memoria.putBool("conocida", true); conocidaGuardada = true; }
  if (fabs(frenteMm - posicionGuardada) < 0.05) return;   // nada nuevo que guardar
  memoria.putFloat("pos", frenteMm);
  posicionGuardada = frenteMm;
  Serial.printf("Carro en %.1f mm (jeringa: %.1f ml usados)\n", frenteMm, frenteMm * ML_POR_MM);
}

void cargarPosicion() {
  posicionConocida = memoria.getBool("conocida", false);
  conocidaGuardada = posicionConocida;
  posicionMm = memoria.getFloat("pos", 0);
  frenteMm = posicionMm;
  posicionGuardada = posicionMm;
}

// ============================================================================
//  MOTOR
// ============================================================================
void moverMotor(Movimiento m, uint8_t velocidad) {
  movimiento = m;
  velocidadActual = velocidad;
  if (m == PARADO) {
    // Freno: ambas entradas en alto cortocircuitan el motor y lo paran en seco.
    digitalWrite(PIN_AIN1, HIGH);
    digitalWrite(PIN_AIN2, HIGH);
    ledcWrite(PIN_PWMA, 0);
    return;
  }
  bool adelante = (m == AVANZAR) != INVERTIR_MOTOR;
  digitalWrite(PIN_STBY, HIGH);
  digitalWrite(PIN_AIN1, adelante ? HIGH : LOW);
  digitalWrite(PIN_AIN2, adelante ? LOW : HIGH);
  ledcWrite(PIN_PWMA, velocidad);
}

void pararMotor() {
  moverMotor(PARADO, 0);
  guardarPosicion();
}

// Suma a la posición lo que se ha movido el carro desde la última vez.
void actualizarPosicion(unsigned long ahora) {
  unsigned long dt = ahora - ultimoCalculoMs;
  ultimoCalculoMs = ahora;
  if (movimiento == PARADO) return;
  float d = velocidadMmPorMs(velocidadActual) * dt;
  if (movimiento == AVANZAR) {
    posicionMm += d;
    frenteMm = max(frenteMm, posicionMm);
  } else {
    posicionMm = max(0.0f, posicionMm - d);
    if (estado == RETRAYENDO) frenteMm = posicionMm;   // jeringa nueva: frente desconocido
  }
}

// Durante una dosis: avanza solo si se quiere avanzar Y hay contacto.
// Al perder el contacto hace un antigoteo corto y espera.
void controlarAvance(unsigned long ahora, bool quiereAvanzar) {
  if (quiereAvanzar && hayContacto()) {
    if (movimiento != AVANZAR) moverMotor(AVANZAR, VELOCIDAD_AVANCE);
    enPausa = false;
    return;
  }
  if (!enPausa) {
    enPausa = true;
    inicioPausaMs = ahora;
    if (movimiento == AVANZAR && ANTIGOTEO_MS > 0 && digitalRead(PIN_FC_ATRAS) != LOW) {
      moverMotor(RETROCEDER, VELOCIDAD_AVANCE);
    } else {
      pararMotor();
    }
    if (quiereAvanzar) Serial.println("Esperando contacto: apoya la paleta en la piel.");
  } else if (movimiento == RETROCEDER && ahora - inicioPausaMs >= ANTIGOTEO_MS) {
    pararMotor();
  }
}

// ============================================================================
//  ENTRADAS
// ============================================================================
void leerBoton(Boton &b, unsigned long ahora) {
  b.flancoBajada = false;
  b.flancoSubida = false;
  bool lectura = (digitalRead(b.pin) == LOW);   // LOW = pulsado (va a GND)
  if (lectura != b.lecturaAnterior) {
    b.lecturaAnterior = lectura;
    b.cambioMs = ahora;
  }
  if (lectura != b.pulsado && (ahora - b.cambioMs) >= ANTIRREBOTE_MS) {
    b.pulsado = lectura;
    if (lectura) b.flancoBajada = true; else b.flancoSubida = true;
  }
}

bool finalCarreraAtras() { return digitalRead(PIN_FC_ATRAS) == LOW; }

float leerBateria() {
  uint32_t suma = 0;
  for (int i = 0; i < 8; i++) suma += analogReadMilliVolts(PIN_BATERIA);   // media de 8
  return (suma / 8.0) / 1000.0 * DIVISOR_BATERIA;
}

// ============================================================================
//  LED
//    motor en marcha         -> fijo
//    dosis esperando contacto -> parpadeo medio (apoya la paleta)
//    listo                   -> destello corto cada 2 s
//    batería baja / agotada  -> parpadeo rápido
//    jeringa vacía o posición desconocida -> doble destello (pulsa RETRAER)
// ============================================================================
void escribirLed(bool encendido) {
  digitalWrite(PIN_LED, encendido ? HIGH : LOW);
  digitalWrite(PIN_LED_PLACA, encendido ? LOW : HIGH);   // el de la placa va al revés
}

void actualizarLed(unsigned long ahora) {
  bool dosificando = (estado == AVANCE_PULSADO || estado == DOSIS_FIJA || estado == CONTINUO);
  bool on;
  if (movimiento != PARADO) {
    on = true;
  } else if (dosificando && enPausa) {
    on = (ahora / 300) % 2;
  } else if (estado == SIN_BATERIA || voltajeBateria < BATERIA_BAJA_V) {
    on = (ahora / 125) % 2;
  } else if (jeringaVacia() || !posicionConocida) {
    unsigned long f = ahora % 1500;
    on = (f < 100) || (f > 250 && f < 350);
  } else {
    on = (ahora % 2000) < 60;
  }
  escribirLed(on);
}

// ============================================================================
//  CAMBIOS DE ESTADO
// ============================================================================
void cambiarEstado(Estado nuevo, unsigned long ahora) {
  estado = nuevo;
  inicioEstadoMs = ahora;
  ultimaActividadMs = ahora;

  switch (nuevo) {
    case REPOSO:
    case ESPERA_SOLTAR:
    case SIN_BATERIA:
      pararMotor();
      break;
    case AVANCE_PULSADO:
      // La dosis se mide desde el frente: así el hueco que dejó el último
      // antigoteo se recupera y no cuenta como crema.
      objetivoMm = frenteMm + DOSIS_ML / ML_POR_MM;
      enPausa = false;
      controlarAvance(ahora, true);
      break;
    case DOSIS_FIJA:
    case CONTINUO:
      break;
    case ANTIGOTEO:
      if (ANTIGOTEO_MS > 0 && movimiento == AVANZAR && !finalCarreraAtras())
        moverMotor(RETROCEDER, VELOCIDAD_AVANCE);
      else pararMotor();
      break;
    case RETRAYENDO:
      moverMotor(RETROCEDER, VELOCIDAD_RETRAER);
      break;
  }
}

// Fin de una dosis. Si estaba avanzando hace antigoteo; si ya estaba en pausa
// (sin contacto) el antigoteo ya está hecho.
void terminarAvance(unsigned long ahora) {
  if (movimiento == AVANZAR && ANTIGOTEO_MS > 0) {
    cambiarEstado(ANTIGOTEO, ahora);
  } else {
    pararMotor();
    cambiarEstado(botonDosis.pulsado ? ESPERA_SOLTAR : REPOSO, ahora);
  }
}

// ============================================================================
//  SUEÑO PROFUNDO (apagado automático)
// ============================================================================
void dormir() {
  Serial.println("Sin uso: me duermo. Pulsa un botón para despertar.");
  pararMotor();
  digitalWrite(PIN_AIN1, LOW);
  digitalWrite(PIN_AIN2, LOW);
  digitalWrite(PIN_STBY, LOW);     // driver en reposo: no consume
  escribirLed(false);
  memoria.end();
  delay(20);
  esp_deep_sleep_enable_gpio_wakeup((1ULL << PIN_BOTON_DOSIS) | (1ULL << PIN_BOTON_RETRAER),
                                    ESP_GPIO_WAKEUP_GPIO_LOW);
  esp_deep_sleep_start();          // al despertar, el chip arranca de nuevo en setup()
}

// ============================================================================
//  ARRANQUE
// ============================================================================
void setup() {
  Serial.begin(115200);

  pinMode(PIN_AIN1, OUTPUT);
  pinMode(PIN_AIN2, OUTPUT);
  pinMode(PIN_STBY, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_LED_PLACA, OUTPUT);
  pinMode(PIN_BOTON_DOSIS, INPUT_PULLUP);
  pinMode(PIN_BOTON_RETRAER, INPUT_PULLUP);
  pinMode(PIN_FC_ATRAS, INPUT_PULLUP);
  pinMode(PIN_CONTACTO, INPUT_PULLUP);
  ledcAttach(PIN_PWMA, PWM_FRECUENCIA, PWM_RESOLUCION);
  analogSetPinAttenuation(PIN_BATERIA, ADC_11db);   // permite medir hasta ~3,1 V

  digitalWrite(PIN_STBY, HIGH);
  moverMotor(PARADO, 0);

  memoria.begin("aplicador", false);
  cargarPosicion();
  if (finalCarreraAtras()) { posicionMm = 0; frenteMm = 0; posicionConocida = true; }

  unsigned long ahora = millis();
  voltajeBateria = leerBateria();
  ultimaBateriaMs = ahora;
  ultimoCalculoMs = ahora;

  Serial.printf("Aplicador listo. Batería %.2f V. Carro en %.1f mm%s. Dosis %.1f ml. Contacto %s\n",
                voltajeBateria, posicionMm, posicionConocida ? "" : " (desconocido)", DOSIS_ML,
                REQUIERE_CONTACTO ? "obligatorio" : "desactivado");

  bool despertadoPorBoton = (esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_GPIO);
  if (voltajeBateria < BATERIA_VACIA_V) cambiarEstado(SIN_BATERIA, ahora);
  else if (despertadoPorBoton)          cambiarEstado(ESPERA_SOLTAR, ahora);
  else                                  cambiarEstado(REPOSO, ahora);
}

// ============================================================================
//  BUCLE PRINCIPAL
// ============================================================================
void loop() {
  unsigned long ahora = millis();
  actualizarPosicion(ahora);
  leerBoton(botonDosis, ahora);
  leerBoton(botonRetraer, ahora);
  leerBoton(sensorContacto, ahora);
  unsigned long enEstado = ahora - inicioEstadoMs;

  // Final de carrera trasero: ahí la posición es 0 seguro (corrige la estimación).
  if (finalCarreraAtras()) { posicionMm = 0; posicionConocida = true; if (estado == RETRAYENDO) frenteMm = 0; }

  // Batería: cada 5 s y solo con el motor parado (al arrancar cae la tensión).
  if (estado == REPOSO && ahora - ultimaBateriaMs > 5000) {
    voltajeBateria = leerBateria();
    ultimaBateriaMs = ahora;
    if (voltajeBateria < BATERIA_VACIA_V) cambiarEstado(SIN_BATERIA, ahora);
  }

  // Límite de recorrido: jeringa vacía -> parar.
  bool dosificando = (estado == AVANCE_PULSADO || estado == DOSIS_FIJA || estado == CONTINUO);
  if (dosificando && jeringaVacia()) {
    Serial.println("Jeringa vacía: pulsa RETRAER y cambia la jeringa.");
    terminarAvance(ahora);
    actualizarLed(ahora);
    return;
  }
  // Mientras se dosifica con contacto, el aparato está "en uso".
  if (dosificando) ultimaActividadMs = ahora;

  switch (estado) {
    case REPOSO:
      if (botonDosis.flancoBajada) {
        if (!posicionConocida)  Serial.println("No sé dónde está el carro: pulsa RETRAER una vez.");
        else if (jeringaVacia()) Serial.println("Jeringa vacía: pulsa RETRAER y cambia la jeringa.");
        else cambiarEstado(AVANCE_PULSADO, ahora);
        ultimaActividadMs = ahora;
      } else if (botonRetraer.flancoBajada) {
        if (finalCarreraAtras()) Serial.println("Ya estoy atrás del todo.");
        else cambiarEstado(RETRAYENDO, ahora);
        ultimaActividadMs = ahora;
      }
      if (botonDosis.pulsado || botonRetraer.pulsado) ultimaActividadMs = ahora;
      if (ahora - ultimaActividadMs >= TIEMPO_APAGADO_MS) dormir();
      break;

    case ESPERA_SOLTAR:
      if (!botonDosis.pulsado && !botonRetraer.pulsado && enEstado > ANTIRREBOTE_MS)
        cambiarEstado(REPOSO, ahora);
      break;

    case AVANCE_PULSADO:
      controlarAvance(ahora, frenteMm < objetivoMm || botonDosis.pulsado);
      if (botonDosis.flancoSubida) {
        estado = DOSIS_FIJA;           // pulsación corta: completar la dosis
      } else if (enEstado >= UMBRAL_MANTENER_MS) {
        estado = CONTINUO;             // sigue pulsado: modo continuo
        Serial.println("Modo continuo");
      }
      break;

    case DOSIS_FIJA:
      if (botonDosis.flancoBajada || botonRetraer.flancoBajada) {
        Serial.println("Dosis cancelada");
        terminarAvance(ahora);
      } else if (frenteMm >= objetivoMm) {
        terminarAvance(ahora);
      } else if (enPausa && ahora - inicioPausaMs >= ESPERA_CONTACTO_MS) {
        Serial.println("Sin contacto con la piel: dosis cancelada.");
        terminarAvance(ahora);
      } else {
        controlarAvance(ahora, true);
      }
      break;

    case CONTINUO:
      if (!botonDosis.pulsado) {
        terminarAvance(ahora);
      } else if (enEstado >= CONTINUO_MAX_MS) {
        Serial.println("Límite de continuo: suelta y vuelve a pulsar.");
        terminarAvance(ahora);
      } else {
        controlarAvance(ahora, true);
      }
      break;

    case ANTIGOTEO:
      if (enEstado >= ANTIGOTEO_MS || finalCarreraAtras()) {
        pararMotor();
        // Si aún mantiene el botón (corte por límite), esperar a que suelte.
        cambiarEstado(botonDosis.pulsado ? ESPERA_SOLTAR : REPOSO, ahora);
      }
      break;

    case RETRAYENDO:
      if (finalCarreraAtras()) {
        Serial.println("Atrás del todo: ya puedes cambiar la jeringa.");
        cambiarEstado(REPOSO, ahora);
      } else if (enEstado > ANTIRREBOTE_MS * 2 &&
                 (botonDosis.flancoBajada || botonRetraer.flancoBajada)) {
        Serial.println("Retroceso detenido");
        cambiarEstado(ESPERA_SOLTAR, ahora);
      } else if (enEstado >= RETRACCION_MAX_MS) {
        Serial.println("Retroceso demasiado largo: ¿falla el final de carrera trasero?");
        cambiarEstado(REPOSO, ahora);
      }
      break;

    case SIN_BATERIA:
      if (enEstado > 5000) dormir();   // 5 s de aviso y a dormir
      break;
  }

  actualizarLed(ahora);
}
