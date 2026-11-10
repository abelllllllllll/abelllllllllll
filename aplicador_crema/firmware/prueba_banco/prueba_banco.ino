/*
 * ============================================================================
 *  APLICADOR DE CREMA · FIRMWARE DE PRUEBAS DE BANCO (diagnóstico)
 * ============================================================================
 *
 *  Para probar cada parte por separado ANTES de cargar el firmware normal.
 *  Se maneja escribiendo órdenes en el Monitor Serie del Arduino IDE
 *  (115200 baudios, "Nueva línea" activado).
 *
 *  Sirve con todo montado o con la electrónica en una protoboard y
 *  alimentada solo por el USB del ordenador (etapa 1 de docs/07).
 *
 *  ÓRDENES (número opcional detrás):
 *    ?        ayuda
 *    e        ver entradas en vivo 10 s (botones, final de carrera, sensor, batería)
 *    a 5      avanzar 5 segundos  (máx. 30)
 *    r 5      retroceder 5 segundos (máx. 30)
 *    h        ir a casa: retroceder hasta el final de carrera (cronometra)
 *    d 3      dosis de prueba: avanza 3 s + antigoteo (para pesar la crema)
 *    v 255    velocidad del motor 0-255 para las siguientes órdenes
 *    c 50     ciclo de resistencia: 50 x (avanza 2 s, retrocede 2 s), sin jeringa
 *    b        batería: tensión en reposo y con el motor en marcha
 *    x        PARAR (funciona en cualquier momento)
 *
 *  Placa: "ESP32C3 Dev Module", USB CDC On Boot: Enabled.
 *  Los pines son los mismos que en el firmware normal.
 * ============================================================================
 */

#include <Arduino.h>

// --- Pines (igual que aplicador_crema.ino) ---
const uint8_t PIN_AIN1 = 0, PIN_AIN2 = 1, PIN_PWMA = 10, PIN_STBY = 21;
const uint8_t PIN_BOTON_DOSIS = 3, PIN_BOTON_RETRAER = 5, PIN_BATERIA = 4;
const uint8_t PIN_FC_ATRAS = 6, PIN_CONTACTO = 7, PIN_LED = 20, PIN_LED_PLACA = 8;

const float DIVISOR_BATERIA = 2.0;          // 100k / 100k
const unsigned long ANTIGOTEO_MS = 300;
const bool INVERTIR_MOTOR = false;          // true si "a" hace bajar el carro

uint8_t velocidad = 255;

// ---------------------------------------------------------------- motor
void motor(int sentido) {        // +1 avanzar, -1 retroceder, 0 parar (freno)
  if (sentido == 0) {
    digitalWrite(PIN_AIN1, HIGH); digitalWrite(PIN_AIN2, HIGH); ledcWrite(PIN_PWMA, 0);
    digitalWrite(PIN_LED, LOW); digitalWrite(PIN_LED_PLACA, HIGH);
    return;
  }
  bool adelante = (sentido > 0) != INVERTIR_MOTOR;
  digitalWrite(PIN_STBY, HIGH);
  digitalWrite(PIN_AIN1, adelante ? HIGH : LOW);
  digitalWrite(PIN_AIN2, adelante ? LOW : HIGH);
  ledcWrite(PIN_PWMA, velocidad);
  digitalWrite(PIN_LED, HIGH); digitalWrite(PIN_LED_PLACA, LOW);
}

bool finalCarrera() { return digitalRead(PIN_FC_ATRAS) == LOW; }

float bateria() {
  uint32_t s = 0;
  for (int i = 0; i < 16; i++) s += analogReadMilliVolts(PIN_BATERIA);
  return s / 16.0 / 1000.0 * DIVISOR_BATERIA;
}

// ¿Ha escrito "x" el usuario? (parada de emergencia)
bool pidioParar() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == 'x' || c == 'X') return true;
  }
  return false;
}

// Mueve el motor durante ms milisegundos. Devuelve los ms que se movió de verdad.
// Se para antes si pides "x" o si retrocediendo pisa el final de carrera.
unsigned long mover(int sentido, unsigned long ms) {
  unsigned long t0 = millis();
  motor(sentido);
  while (millis() - t0 < ms) {
    if (pidioParar()) { Serial.println("  ¡PARADO!"); break; }
    if (sentido < 0 && finalCarrera()) { Serial.println("  Final de carrera alcanzado"); break; }
    delay(1);
  }
  motor(0);
  return millis() - t0;
}

// ---------------------------------------------------------------- órdenes
void ayuda() {
  Serial.println();
  Serial.println("=== PRUEBAS DE BANCO · aplicador de crema ===");
  Serial.println(" e       ver entradas en vivo 10 s");
  Serial.println(" a 5     avanzar 5 s            r 5   retroceder 5 s");
  Serial.println(" h       ir a casa (cronometra)  d 3   dosis de prueba de 3 s");
  Serial.println(" v 255   velocidad 0-255        c 50  ciclo de resistencia");
  Serial.println(" b       batería en reposo y con motor");
  Serial.println(" x       PARAR");
  Serial.printf(" (velocidad actual: %d)\n\n", velocidad);
}

void verEntradas() {
  Serial.println("Entradas durante 10 s (pulsa botones, apoya la paleta, pisa el final de carrera):");
  for (int i = 0; i < 40; i++) {
    if (pidioParar()) break;
    Serial.printf("  DOSIS:%s  RETRAER:%s  FIN_CARRERA:%s  CONTACTO:%s  BAT:%.2f V\n",
                  digitalRead(PIN_BOTON_DOSIS) == LOW ? "PULSADO" : "-------",
                  digitalRead(PIN_BOTON_RETRAER) == LOW ? "PULSADO" : "-------",
                  finalCarrera() ? "PISADO" : "------",
                  digitalRead(PIN_CONTACTO) == LOW ? "APOYADA" : "-------",
                  bateria());
    delay(250);
  }
}

void irACasa() {
  if (finalCarrera()) { Serial.println("Ya está en casa (final de carrera pisado)."); return; }
  Serial.println("Retrocediendo hasta el final de carrera (x para parar)...");
  unsigned long ms = mover(-1, 150000);
  Serial.printf("  Tardó %.1f s. %s\n", ms / 1000.0,
                finalCarrera() ? "OK: final de carrera detectado." :
                "ATENCIÓN: no llegó al final de carrera (revisa cableado o sentido del motor).");
}

void dosisPrueba(float segundos) {
  Serial.printf("Dosis de prueba: avanza %.1f s + antigoteo. Pon un recipiente en la báscula.\n", segundos);
  unsigned long ms = mover(+1, (unsigned long)(segundos * 1000));
  mover(-1, ANTIGOTEO_MS);
  Serial.printf("  Avanzó %.2f s. Pesa la crema (1 g ~ 1 ml) y apúntalo en la hoja de resultados.\n", ms / 1000.0);
}

void ciclo(int n) {
  Serial.printf("Ciclo de resistencia: %d x (avanza 2 s / retrocede 2 s). SIN jeringa. x para parar.\n", n);
  for (int i = 1; i <= n; i++) {
    if (mover(+1, 2000) < 1990) break;
    if (mover(-1, 2000) < 1990 && !finalCarrera()) break;
    if (i % 10 == 0) Serial.printf("  %d ciclos. Batería %.2f V. Toca el motor: ¿está frío o templado?\n", i, bateria());
  }
  Serial.println("  Fin del ciclo.");
}

void probarBateria() {
  float reposo = bateria();
  motor(+1); delay(1500);
  float carga = bateria();
  motor(0);
  mover(-1, 1500);
  Serial.printf("Batería: %.2f V en reposo, %.2f V con el motor (caída %.2f V)\n", reposo, carga, reposo - carga);
  if (reposo < 1.0) Serial.println("  (≈0 V: estás alimentando solo por USB o el divisor no está conectado)");
  else if (reposo - carga > 0.4) Serial.println("  Caída grande: revisa cables finos o conexiones flojas en la batería.");
}

// ---------------------------------------------------------------- arranque
void setup() {
  Serial.begin(115200);
  pinMode(PIN_AIN1, OUTPUT); pinMode(PIN_AIN2, OUTPUT); pinMode(PIN_STBY, OUTPUT);
  pinMode(PIN_LED, OUTPUT); pinMode(PIN_LED_PLACA, OUTPUT);
  pinMode(PIN_BOTON_DOSIS, INPUT_PULLUP); pinMode(PIN_BOTON_RETRAER, INPUT_PULLUP);
  pinMode(PIN_FC_ATRAS, INPUT_PULLUP); pinMode(PIN_CONTACTO, INPUT_PULLUP);
  ledcAttach(PIN_PWMA, 20000, 8);
  analogSetPinAttenuation(PIN_BATERIA, ADC_11db);
  digitalWrite(PIN_STBY, HIGH);
  motor(0);
  delay(1500);   // tiempo para abrir el monitor serie
  ayuda();
}

void loop() {
  if (!Serial.available()) { delay(10); return; }
  String linea = Serial.readStringUntil('\n');
  linea.trim();
  if (linea.length() == 0) return;
  char orden = tolower(linea.charAt(0));
  float n = linea.length() > 1 ? linea.substring(1).toFloat() : -1;

  switch (orden) {
    case '?': ayuda(); break;
    case 'e': verEntradas(); break;
    case 'a': {
      float s = n > 0 ? min(n, 30.0f) : 2;
      Serial.printf("Avanzando %.1f s...\n", s);
      Serial.printf("  Hecho (%.2f s)\n", mover(+1, s * 1000) / 1000.0);
      break;
    }
    case 'r': {
      float s = n > 0 ? min(n, 30.0f) : 2;
      Serial.printf("Retrocediendo %.1f s...\n", s);
      Serial.printf("  Hecho (%.2f s)\n", mover(-1, s * 1000) / 1000.0);
      break;
    }
    case 'h': irACasa(); break;
    case 'd': dosisPrueba(n > 0 ? min(n, 30.0f) : 3); break;
    case 'v':
      if (n >= 0 && n <= 255) velocidad = (uint8_t)n;
      Serial.printf("Velocidad: %d\n", velocidad);
      break;
    case 'c': ciclo(n > 0 ? (int)n : 50); break;
    case 'b': probarBateria(); break;
    case 'x': motor(0); Serial.println("Parado."); break;
    default: Serial.println("Orden desconocida. Escribe ? para ver la ayuda.");
  }
}
