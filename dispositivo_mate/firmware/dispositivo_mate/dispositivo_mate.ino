// ============================================================================
//  DISPOSITIVO AUTOMÁTICO DE MATE · firmware v1 (ESP32-C3)
// ============================================================================
//  Placa: ESP32-C3 SuperMini (Arduino core ESP32 3.x)
//  Librería: Adafruit NeoPixel
//
//  BOTÓN (único):
//    toque corto  en reposo        -> ciclo completo (limpiar -> dar vuelta -> cargar)
//    toque corto  esperando vuelta -> cargar yerba
//    doble toque  en reposo        -> solo cargar yerba
//    mantener 2 s                  -> cancelar / apagar
//    mantener 6 s en reposo        -> calibración (gira 20 vueltas del sinfín)
//
//  LED (anillo de 12):
//    blanco suave    reposo              azul girando   limpiando
//    azul latiendo   dar vuelta el mate  verde girando  cargando yerba
//    verde fijo      listo               naranja        abrí/cerrá la puerta, vaciá el cajón
//    rojo titilando  error (atasco)      rojo 1 LED     batería baja
//
//  Monitor serie (115200): "g=0.95" guarda gramos por vuelta, "d=30" guarda la
//  dosis en gramos, "?" muestra la configuración.
// ============================================================================

#include <Arduino.h>
#include <Preferences.h>
#include <Adafruit_NeoPixel.h>
#include <esp_sleep.h>

// ---------------------------------------------------------------- PINES
const int PIN_ENC_ROTOR   = 0;   // encoder del motor del rotor (canal A)
const int PIN_ENC_SINFIN  = 1;   // encoder del N20 del sinfín (canal A)
const int PIN_BOTON       = 3;   // a GND, pull-up interno (despierta del sueño)
const int PIN_VBAT        = 4;   // divisor 100k / 33k desde la batería 2S
const int PIN_PUERTA      = 5;   // DRV5032: LOW = imán cerca = puerta cerrada
const int PIN_ROTOR_IN1   = 6;   // DRV8871 IN1
const int PIN_ROTOR_IN2   = 7;   // DRV8871 IN2
const int PIN_LED         = 10;  // anillo WS2812 (vía 74AHCT125)
const int PIN_SINFIN_IN1  = 20;  // TB6612 AIN1 (PWMA y STBY a 3,3 V)
const int PIN_SINFIN_IN2  = 21;  // TB6612 AIN2

// ---------------------------------------------------------------- AJUSTES
const int   LEDS             = 12;
const uint32_t PWM_HZ        = 20000;
const int   PWM_BITS         = 10;          // 0..1023
const float VBAT_DIVISOR     = (100.0f + 33.0f) / 33.0f;
const float VBAT_MIN         = 6.6f;        // 3,3 V por celda: no arrancar
const float VBAT_BAJA        = 7.0f;        // avisar
const float VBAT_MAX_MOTOR   = 6.0f;        // motores de 6 V: limitar el PWM

// Limpieza
const uint32_t LIMPIEZA_TRAMO_MS   = 2500;   // cambia de sentido cada tramo
const int      LIMPIEZA_TRAMOS     = 6;      // 15 s en total
const float    ROTOR_POTENCIA      = 1.0f;   // fracción de 6 V

// Sinfín
const int   PULSOS_POR_VUELTA      = 7 * 150;   // N20 con encoder 7 PPR y reductora 1:150 (MEDIR)
const float SINFIN_POTENCIA        = 0.9f;
const uint32_t ATASCO_MS           = 600;       // sin pulsos durante este tiempo = atasco
const int   REINTENTOS_ATASCO      = 3;
const uint32_t DOSIS_MAX_MS        = 40000;     // tiempo máximo de una carga

const uint32_t ESPERA_VUELTA_MAX_MS = 60000;    // si no dan vuelta el mate, se cancela
const uint32_t REPOSO_A_DORMIR_MS   = 120000;   // 2 min sin uso -> sueño profundo

// ---------------------------------------------------------------- ESTADO
enum Estado { REPOSO, LIMPIANDO, ESPERA_VUELTA, CARGANDO, LISTO, ERROR_ATASCO, CALIBRANDO };
Estado estado = REPOSO;
uint32_t t_estado = 0;

Preferences prefs;
float gramos_por_vuelta = 0.95f;   // se corrige con la balanza
float dosis_g           = 30.0f;

Adafruit_NeoPixel anillo(LEDS, PIN_LED, NEO_GRB + NEO_KHZ800);

volatile uint32_t pulsos_rotor  = 0;
volatile uint32_t pulsos_sinfin = 0;
void IRAM_ATTR isr_rotor()  { pulsos_rotor++; }
void IRAM_ATTR isr_sinfin() { pulsos_sinfin++; }

// ---------------------------------------------------------------- UTILIDADES
float leer_vbat() {
    uint32_t mv = 0;
    for (int i = 0; i < 8; i++) mv += analogReadMilliVolts(PIN_VBAT);
    return (mv / 8.0f) / 1000.0f * VBAT_DIVISOR;
}
bool puerta_cerrada() { return digitalRead(PIN_PUERTA) == LOW; }

// Escala el PWM para que un motor de 6 V no reciba más de 6 V con la batería llena (8,4 V)
int pwm_para(float fraccion) {
    float v = leer_vbat();
    float limite = (v > VBAT_MAX_MOTOR) ? VBAT_MAX_MOTOR / v : 1.0f;
    float f = constrain(fraccion * limite, 0.0f, 1.0f);
    return (int)(f * ((1 << PWM_BITS) - 1));
}
// sentido: +1, -1 o 0 (frenar)
void motor(int in1, int in2, int sentido, float potencia) {
    int p = pwm_para(potencia);
    if (sentido > 0)      { ledcWrite(in1, p); ledcWrite(in2, 0); }
    else if (sentido < 0) { ledcWrite(in1, 0); ledcWrite(in2, p); }
    else                  { ledcWrite(in1, (1 << PWM_BITS) - 1); ledcWrite(in2, (1 << PWM_BITS) - 1); } // freno
}
void rotor(int s)  { motor(PIN_ROTOR_IN1,  PIN_ROTOR_IN2,  s, ROTOR_POTENCIA); }
void sinfin(int s) { motor(PIN_SINFIN_IN1, PIN_SINFIN_IN2, s, SINFIN_POTENCIA); }
void parar_todo()  { rotor(0); sinfin(0); }

void cambiar(Estado e) {
    estado = e; t_estado = millis();
    Serial.printf("[estado] %d\n", (int)e);
}

// ---------------------------------------------------------------- LED
uint32_t col(uint8_t r, uint8_t g, uint8_t b) { return anillo.Color(r, g, b); }
void led_lleno(uint32_t c) { for (int i = 0; i < LEDS; i++) anillo.setPixelColor(i, c); anillo.show(); }
void led_girando(uint8_t r, uint8_t g, uint8_t b) {
    int p = (millis() / 80) % LEDS;
    for (int i = 0; i < LEDS; i++) {
        int d = (p - i + LEDS) % LEDS;
        float k = d == 0 ? 1.0f : (d < 4 ? 0.35f / d : 0.0f);
        anillo.setPixelColor(i, col(r * k, g * k, b * k));
    }
    anillo.show();
}
void led_latiendo(uint8_t r, uint8_t g, uint8_t b) {
    float k = 0.15f + 0.85f * (0.5f + 0.5f * sinf(millis() / 300.0f));
    led_lleno(col(r * k, g * k, b * k));
}
void led_titilando(uint8_t r, uint8_t g, uint8_t b) {
    led_lleno((millis() / 250) % 2 ? col(r, g, b) : 0);
}
void actualizar_led() {
    switch (estado) {
        case REPOSO:        led_lleno(col(10, 10, 10)); break;
        case LIMPIANDO:     led_girando(0, 60, 255); break;
        case ESPERA_VUELTA: led_latiendo(0, 60, 255); break;
        case CARGANDO:      led_girando(0, 255, 40); break;
        case CALIBRANDO:    led_girando(255, 255, 255); break;
        case LISTO:         led_lleno(col(0, 200, 30)); break;
        case ERROR_ATASCO:  led_titilando(255, 0, 0); break;
    }
    if (leer_vbat() < VBAT_BAJA) { anillo.setPixelColor(0, col(255, 0, 0)); anillo.show(); }
}
void avisar_naranja(int veces) {
    for (int i = 0; i < veces; i++) { led_lleno(col(255, 90, 0)); delay(250); led_lleno(0); delay(200); }
}

// ---------------------------------------------------------------- BOTÓN
enum Toque { NADA, CORTO, DOBLE, LARGO, MUY_LARGO };
Toque leer_boton() {
    static bool antes = false;
    static uint32_t t_baja = 0, t_ultimo_corto = 0;
    static bool largo_avisado = false, corto_pendiente = false;
    bool ahora = digitalRead(PIN_BOTON) == LOW;
    uint32_t t = millis();
    Toque r = NADA;
    if (ahora && !antes) { t_baja = t; largo_avisado = false; }
    if (ahora && !largo_avisado && t - t_baja > 2000) {
        largo_avisado = true;
        // esperar a ver si llega a "muy largo" (6 s) solo en reposo
        if (estado != REPOSO) r = LARGO;
    }
    if (!ahora && antes) {
        uint32_t dur = t - t_baja;
        if (dur > 6000 && estado == REPOSO) r = MUY_LARGO;
        else if (dur > 2000) r = (estado == REPOSO) ? LARGO : NADA;
        else if (dur > 40) {
            if (corto_pendiente && t - t_ultimo_corto < 400) { corto_pendiente = false; r = DOBLE; }
            else { corto_pendiente = true; t_ultimo_corto = t; }
        }
    }
    if (corto_pendiente && !ahora && t - t_ultimo_corto >= 400) { corto_pendiente = false; r = CORTO; }
    antes = ahora;
    return r;
}

// ---------------------------------------------------------------- SUEÑO
void dormir() {
    parar_todo();
    led_lleno(0);
    Serial.println("A dormir. Tocá el botón para despertar.");
    delay(50);
    esp_deep_sleep_enable_gpio_wakeup(1ULL << PIN_BOTON, ESP_GPIO_WAKEUP_GPIO_LOW);
    esp_deep_sleep_start();
}

// ---------------------------------------------------------------- CICLOS
// Limpieza: el rotor gira alternando el sentido. Si no gira (encoder quieto) = traba.
bool ciclo_limpieza() {
    cambiar(LIMPIANDO);
    for (int tramo = 0; tramo < LIMPIEZA_TRAMOS; tramo++) {
        int sentido = (tramo % 2 == 0) ? 1 : -1;
        uint32_t t0 = millis(), t_ult_pulso = millis(), ult = pulsos_rotor;
        rotor(sentido);
        while (millis() - t0 < LIMPIEZA_TRAMO_MS) {
            actualizar_led();
            if (!puerta_cerrada()) { parar_todo(); avisar_naranja(3); return false; }
            if (leer_boton() == LARGO) { parar_todo(); return false; }
            if (pulsos_rotor != ult) { ult = pulsos_rotor; t_ult_pulso = millis(); }
            if (millis() - t_ult_pulso > ATASCO_MS) {     // trabado: cambiar de sentido ya
                Serial.println("Rotor frenado: cambio de sentido");
                break;
            }
            delay(5);
        }
        rotor(0);
        delay(150);
    }
    return true;
}

// Carga: cuenta vueltas del sinfín. Ante un atasco retrocede media vuelta y reintenta.
bool ciclo_carga(float gramos) {
    cambiar(CARGANDO);
    uint32_t objetivo = (uint32_t)(gramos / gramos_por_vuelta * PULSOS_POR_VUELTA);
    uint32_t hechos = 0;
    int reintentos = 0;
    uint32_t t0 = millis();
    while (hechos < objetivo) {
        uint32_t base = pulsos_sinfin, t_ult = millis(), ult = base;
        sinfin(1);
        while (hechos + (pulsos_sinfin - base) < objetivo) {
            actualizar_led();
            if (leer_boton() == LARGO) { parar_todo(); return false; }
            if (pulsos_sinfin != ult) { ult = pulsos_sinfin; t_ult = millis(); }
            if (millis() - t_ult > ATASCO_MS) break;
            if (millis() - t0 > DOSIS_MAX_MS) { parar_todo(); Serial.println("Tolva vacía?"); avisar_naranja(5); return false; }
            delay(2);
        }
        sinfin(0);
        hechos += pulsos_sinfin - base;
        if (hechos >= objetivo) break;
        // atasco
        if (++reintentos > REINTENTOS_ATASCO) { cambiar(ERROR_ATASCO); return false; }
        Serial.printf("Atasco %d: retrocedo\n", reintentos);
        uint32_t b2 = pulsos_sinfin;
        sinfin(-1);
        uint32_t tr = millis();
        while (pulsos_sinfin - b2 < PULSOS_POR_VUELTA / 2 && millis() - tr < 800) delay(2);
        sinfin(0);
        delay(150);
    }
    // antigoteo: un cuarto de vuelta hacia atrás
    uint32_t b3 = pulsos_sinfin;
    sinfin(-1);
    uint32_t ta = millis();
    while (pulsos_sinfin - b3 < PULSOS_POR_VUELTA / 4 && millis() - ta < 500) delay(2);
    sinfin(0);
    Serial.printf("Carga lista: %.1f g (estimado)\n", hechos / (float)PULSOS_POR_VUELTA * gramos_por_vuelta);
    return true;
}

void calibrar() {
    cambiar(CALIBRANDO);
    Serial.println("Calibración: poné un vaso sobre la balanza. Giro 20 vueltas...");
    float g_antes = gramos_por_vuelta;
    gramos_por_vuelta = 1.0f;
    ciclo_carga(20.0f);              // 20 "gramos" de 1 g/vuelta = 20 vueltas
    gramos_por_vuelta = g_antes;
    Serial.println("Pesá y escribí  g=<gramos pesados / 20>  (ej. g=0.95)");
}

// ---------------------------------------------------------------- SERIE
void leer_serie() {
    if (!Serial.available()) return;
    String s = Serial.readStringUntil('\n'); s.trim();
    if (s.startsWith("g=")) { gramos_por_vuelta = s.substring(2).toFloat(); prefs.putFloat("gpv", gramos_por_vuelta); }
    else if (s.startsWith("d=")) { dosis_g = s.substring(2).toFloat(); prefs.putFloat("dosis", dosis_g); }
    Serial.printf("gramos/vuelta=%.3f  dosis=%.1f g  bateria=%.2f V  puerta=%s\n",
                  gramos_por_vuelta, dosis_g, leer_vbat(), puerta_cerrada() ? "cerrada" : "abierta");
}

// ---------------------------------------------------------------- SETUP / LOOP
void setup() {
    Serial.begin(115200);
    pinMode(PIN_BOTON, INPUT_PULLUP);
    pinMode(PIN_PUERTA, INPUT_PULLUP);
    pinMode(PIN_ENC_ROTOR, INPUT_PULLUP);
    pinMode(PIN_ENC_SINFIN, INPUT_PULLUP);
    attachInterrupt(PIN_ENC_ROTOR, isr_rotor, RISING);
    attachInterrupt(PIN_ENC_SINFIN, isr_sinfin, RISING);
    for (int p : {PIN_ROTOR_IN1, PIN_ROTOR_IN2, PIN_SINFIN_IN1, PIN_SINFIN_IN2}) ledcAttach(p, PWM_HZ, PWM_BITS);
    parar_todo();
    analogReadResolution(12);
    anillo.begin();
    anillo.setBrightness(80);
    prefs.begin("mate", false);
    gramos_por_vuelta = prefs.getFloat("gpv", gramos_por_vuelta);
    dosis_g           = prefs.getFloat("dosis", dosis_g);
    cambiar(REPOSO);
    leer_serie();
}

void loop() {
    leer_serie();
    actualizar_led();
    Toque b = leer_boton();
    float v = leer_vbat();

    switch (estado) {
        case REPOSO:
        case LISTO:
        case ERROR_ATASCO:
            if (b == CORTO || b == DOBLE) {
                if (v < VBAT_MIN) { avisar_naranja(2); Serial.println("Batería baja: cargá por USB-C"); break; }
                if (b == CORTO) {
                    if (!puerta_cerrada()) { avisar_naranja(3); break; }
                    if (ciclo_limpieza()) cambiar(ESPERA_VUELTA); else cambiar(REPOSO);
                } else {
                    cambiar(ciclo_carga(dosis_g) ? LISTO : (estado == ERROR_ATASCO ? ERROR_ATASCO : REPOSO));
                }
            } else if (b == MUY_LARGO) { calibrar(); cambiar(REPOSO); }
            else if (b == LARGO) dormir();
            else if (millis() - t_estado > REPOSO_A_DORMIR_MS) dormir();
            break;

        case ESPERA_VUELTA:
            if (b == CORTO) cambiar(ciclo_carga(dosis_g) ? LISTO : (estado == ERROR_ATASCO ? ERROR_ATASCO : REPOSO));
            else if (b == LARGO || millis() - t_estado > ESPERA_VUELTA_MAX_MS) cambiar(REPOSO);
            break;

        default: break;
    }
    delay(10);
}
