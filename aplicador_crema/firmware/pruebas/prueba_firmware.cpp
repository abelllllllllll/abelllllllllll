// ============================================================================
//  Banco de pruebas del firmware en el PC (sin hardware).
//
//  Simula: tiempo, botones (con rebotes), motor N20 + varilla M5 (más rápido
//  con la batería llena), jeringa con tope físico, final de carrera trasero,
//  batería, memoria no volátil y sueño profundo. Ejecuta el .ino real.
//
//  Compilar y ejecutar (Linux / macOS / WSL):
//      g++ -std=c++17 -I simulador prueba_firmware.cpp -o prueba && ./prueba
// ============================================================================
#include <functional>
#include <map>
#include <string>
#include <sys/wait.h>
#include <unistd.h>
#include "Arduino.h"
#include "Preferences.h"
#include "esp_sleep.h"

namespace sim {
unsigned long tiempo = 0;
int salidas[32] = {0};
int entradas[32] = {0};
int pwm[32] = {0};
int adcMv[32] = {0};
esp_sleep_source_t causaDespertar = ESP_SLEEP_WAKEUP_UNDEFINED;
uint64_t mascaraDespertar = 0;
std::map<std::string, float> nvs;
int escriturasNvs = 0;
}
SerialSim Serial;

#include "../aplicador_crema/aplicador_crema.ino"

// ---------------------------------------------------------------- física
double tensionReal = 3.8;           // tensión real de la batería
double factorVelocidadReal = 1.0;   // <1 = la crema frena el motor más de lo calibrado
const double TOPE_FISICO_MM = RECORRIDO_MAX_MM + 4;  // émbolo al fondo de la jeringa
double carroMm = 10.0;              // posición REAL del carro
double maxCarroMm = -1;             // la crema solo sale al empujar más allá de lo ya empujado
double avanceMsTotal = 0, retrocesoMsTotal = 0, mlSoltados = 0, msBloqueado = 0;

int sentidoMotor() {
  if (!sim::salidas[PIN_STBY] || sim::pwm[PIN_PWMA] == 0) return 0;
  int a = sim::salidas[PIN_AIN1], b = sim::salidas[PIN_AIN2];
  if (a && !b) return +1;
  if (!a && b) return -1;
  return 0;
}

void fisica() {
  int s = sentidoMotor();
  double paso = MM_POR_SEGUNDO / 1000.0 * (tensionReal / V_CALIBRACION) *
                (sim::pwm[PIN_PWMA] / 255.0) * factorVelocidadReal;
  if (s > 0) {
    avanceMsTotal++;
    if (carroMm + paso <= TOPE_FISICO_MM) {
      carroMm += paso;
      if (maxCarroMm < 0) maxCarroMm = carroMm - paso;
      if (carroMm > maxCarroMm) { mlSoltados += (carroMm - maxCarroMm) * ML_POR_MM; maxCarroMm = carroMm; }
    }
    else msBloqueado++;
  }
  if (s < 0) { retrocesoMsTotal++; carroMm = std::max(0.0, carroMm - paso); }
  if (carroMm <= 0) maxCarroMm = 1e9;   // jeringa nueva: no sale nada hasta tocar el émbolo
  sim::entradas[PIN_FC_ATRAS] = carroMm <= 0.0 ? LOW : HIGH;
}

void sim::avanzar(unsigned long ms) { for (unsigned long i = 0; i < ms; i++) { tiempo++; fisica(); } }
void correr(unsigned long ms) { for (unsigned long i = 0; i < ms; i++) { loop(); sim::avanzar(1); } }

void pulsar(uint8_t pin, bool conRebotes = true) {
  if (conRebotes) for (int i = 0; i < 4; i++) { sim::entradas[pin] = LOW; correr(2); sim::entradas[pin] = HIGH; correr(1); }
  sim::entradas[pin] = LOW;
}
void soltar(uint8_t pin) { sim::entradas[pin] = HIGH; }
void clic(uint8_t pin) { pulsar(pin); correr(120); soltar(pin); }
void bateria(double v) { tensionReal = v; sim::adcMv[PIN_BATERIA] = (int)(v / DIVISOR_BATERIA * 1000); }

// Arranca con la posición ya guardada en memoria (caso normal de uso).
void arrancar(double v = 3.8, bool porBoton = false, bool memoriaConPosicion = true) {
  for (int p = 0; p < 32; p++) sim::entradas[p] = HIGH;
  sim::entradas[PIN_CONTACTO] = LOW;       // por defecto, paleta apoyada en la piel
  bateria(v);
  if (memoriaConPosicion) { sim::nvs["pos"] = carroMm; sim::nvs["conocida"] = 1; }
  sim::causaDespertar = porBoton ? ESP_SLEEP_WAKEUP_GPIO : ESP_SLEEP_WAKEUP_UNDEFINED;
  fisica();
  setup();
}

// ---------------------------------------------------------------- utilidades
int fallos = 0;
#define COMPROBAR(cond, msg) do { if (!(cond)) { std::printf("    FALLO: %s  (línea %d)\n", msg, __LINE__); fallos++; } } while (0)
bool cerca(double a, double b, double tol) { return std::fabs(a - b) <= tol; }

// ---------------------------------------------------------------- pruebas
void pruebaPulsacionCorta() {
  arrancar();
  clic(PIN_BOTON_DOSIS);
  correr(6000);
  std::printf("    avance %.0f ms, retroceso %.0f ms, %.2f ml\n", avanceMsTotal, retrocesoMsTotal, mlSoltados);
  COMPROBAR(cerca(mlSoltados, DOSIS_ML, 0.05), "suelta DOSIS_ML");
  COMPROBAR(cerca(retrocesoMsTotal, ANTIGOTEO_MS, 5), "hace antigoteo");
  COMPROBAR(estado == REPOSO && sentidoMotor() == 0, "vuelve a reposo con motor parado");
  COMPROBAR(cerca(sim::nvs["pos"], frenteMm, 0.06), "guarda la posición en memoria");
}

void pruebaDosisSeguidas() {
  arrancar();
  for (int i = 0; i < 5; i++) { clic(PIN_BOTON_DOSIS); correr(5000); }
  double desplazadoReal = carroMm - 10.0;
  std::printf("    5 dosis: carro avanzó %.2f mm netos (%.2f ml netos), estimado %.2f mm\n",
              desplazadoReal, desplazadoReal * ML_POR_MM, posicionMm - 10.0);
  COMPROBAR(cerca(desplazadoReal * ML_POR_MM, 5 * DOSIS_ML, 0.4), "5 dosis ≈ 5 x DOSIS_ML (el antigoteo se recupera)");
  COMPROBAR(cerca(posicionMm, carroMm, 0.2), "la posición estimada coincide con la real");
}

void pruebaCompensacionTension() {
  arrancar(4.15);
  clic(PIN_BOTON_DOSIS); correr(5000);
  double llena = mlSoltados;
  mlSoltados = 0;
  bateria(3.55); correr(6000);   // se mide en reposo
  clic(PIN_BOTON_DOSIS); correr(6000);
  std::printf("    batería 4,15 V: %.2f ml | batería 3,55 V: %.2f ml\n", llena, mlSoltados);
  COMPROBAR(cerca(llena, DOSIS_ML, 0.08) && cerca(mlSoltados, DOSIS_ML, 0.08), "misma dosis con batería llena o baja");
}

void pruebaMantener() {
  arrancar();
  pulsar(PIN_BOTON_DOSIS); correr(6000); soltar(PIN_BOTON_DOSIS);
  correr(1000);
  std::printf("    avance %.0f ms, %.2f ml\n", avanceMsTotal, mlSoltados);
  COMPROBAR(cerca(avanceMsTotal, 6000, 60), "mientras se mantiene, avanza");
  COMPROBAR(retrocesoMsTotal > 0, "antigoteo al soltar");
  COMPROBAR(estado == REPOSO, "reposo al final");
}

void pruebaCancelar() {
  arrancar();
  clic(PIN_BOTON_DOSIS);
  correr(800);
  clic(PIN_BOTON_DOSIS);
  correr(2000);
  std::printf("    %.2f ml (sin cancelar serían %.1f)\n", mlSoltados, DOSIS_ML);
  COMPROBAR(mlSoltados < 0.9, "pulsar durante la dosis la cancela");
  COMPROBAR(estado == REPOSO, "reposo tras cancelar");
}

void pruebaLimiteContinuo() {
  arrancar();
  pulsar(PIN_BOTON_DOSIS); correr(30000);
  std::printf("    avance %.0f ms con el botón 30 s pulsado\n", avanceMsTotal);
  COMPROBAR(cerca(avanceMsTotal, CONTINUO_MAX_MS, 60), "se corta en CONTINUO_MAX_MS");
  COMPROBAR(sentidoMotor() == 0, "motor parado aunque siga pulsado");
  soltar(PIN_BOTON_DOSIS); correr(200);
  COMPROBAR(estado == REPOSO, "al soltar vuelve a reposo");
}

void pruebaApagado() {
  arrancar();
  bool durmio = false; unsigned long t0 = sim::tiempo;
  try { correr(TIEMPO_APAGADO_MS + 1000); } catch (Dormido &) { durmio = true; }
  std::printf("    se durmió a los %.1f s\n", (sim::tiempo - t0) / 1000.0);
  COMPROBAR(durmio, "se duerme por inactividad");
  COMPROBAR(cerca(sim::tiempo - t0, TIEMPO_APAGADO_MS, 50), "a los 2 minutos (+20 ms de espera)");
  COMPROBAR(sim::salidas[PIN_STBY] == LOW, "driver en reposo antes de dormir");
  COMPROBAR(sim::mascaraDespertar == ((1ULL << PIN_BOTON_DOSIS) | (1ULL << PIN_BOTON_RETRAER)), "despierta con los dos botones");
}

void pruebaUsoReiniciaApagado() {
  arrancar();
  bool durmio = false;
  try { correr(100000); clic(PIN_BOTON_DOSIS); correr(100000); } catch (Dormido &) { durmio = true; }
  COMPROBAR(!durmio, "usarlo reinicia la cuenta de 2 minutos");
}

void pruebaDespertarNoDosifica() {
  arrancar(3.8, true);
  sim::entradas[PIN_BOTON_DOSIS] = LOW;   // el dedo sigue en el botón al despertar
  correr(1500); soltar(PIN_BOTON_DOSIS); correr(500);
  COMPROBAR(avanceMsTotal == 0, "la pulsación que despierta no suelta crema");
  clic(PIN_BOTON_DOSIS); correr(5000);
  COMPROBAR(cerca(mlSoltados, DOSIS_ML, 0.05), "la siguiente pulsación sí dosifica");
}

void pruebaPrimerArranque() {
  carroMm = 40;
  arrancar(3.8, false, false);   // memoria vacía
  clic(PIN_BOTON_DOSIS); correr(3000);
  COMPROBAR(avanceMsTotal == 0, "sin posición conocida no dosifica");
  clic(PIN_BOTON_RETRAER); correr(60000);
  COMPROBAR(carroMm <= 0 && posicionConocida && posicionMm == 0, "RETRAER busca el final de carrera y fija el 0");
  COMPROBAR(sim::nvs["conocida"] == 1, "y lo recuerda");
}

void pruebaJeringaVacia() {
  carroMm = RECORRIDO_MAX_MM - 2;
  arrancar();
  clic(PIN_BOTON_DOSIS); correr(5000);
  std::printf("    se paró en %.1f mm (límite %.0f, tope físico %.0f), %.0f ms contra el tope\n",
              carroMm, RECORRIDO_MAX_MM, TOPE_FISICO_MM, msBloqueado);
  COMPROBAR(msBloqueado == 0, "para antes de chocar con el fondo de la jeringa");
  COMPROBAR(jeringaVacia(), "detecta jeringa vacía");
  double antes = avanceMsTotal;
  clic(PIN_BOTON_DOSIS); correr(3000);
  COMPROBAR(avanceMsTotal == antes, "con jeringa vacía no avanza más");
  clic(PIN_BOTON_RETRAER);
  correr(100000);
  std::printf("    retroceso completo en %.1f s\n", retrocesoMsTotal / 1000.0);
  COMPROBAR(carroMm <= 0.0 && estado == REPOSO, "retrae hasta el final trasero y para");
  COMPROBAR(!jeringaVacia(), "tras retraer se puede volver a usar");
}

void pruebaCremaMasDura() {
  // La crema frena el motor un 25 % más de lo calibrado: la estimación va por
  // delante de la realidad, así que el límite salta antes (lado seguro).
  factorVelocidadReal = 0.75;
  carroMm = RECORRIDO_MAX_MM - 10;
  arrancar();
  pulsar(PIN_BOTON_DOSIS); correr(15000); soltar(PIN_BOTON_DOSIS); correr(1000);
  std::printf("    real %.1f mm, estimado %.1f mm, %.0f ms contra el tope\n", carroMm, posicionMm, msBloqueado);
  COMPROBAR(msBloqueado == 0, "nunca empuja contra el fondo");
}

void pruebaRetraerSeDetiene() {
  carroMm = 60;
  arrancar();
  clic(PIN_BOTON_RETRAER); correr(3000);
  clic(PIN_BOTON_RETRAER); correr(2000);
  double pos = carroMm;
  correr(2000);
  COMPROBAR(carroMm == pos && carroMm > 50, "una segunda pulsación detiene el retroceso");
  COMPROBAR(estado == REPOSO, "reposo");
  COMPROBAR(cerca(posicionMm, carroMm, 0.2), "sigue sabiendo dónde está");
}

void pruebaBateriaVacia() {
  arrancar(3.2);
  bool durmio = false;
  try { pulsar(PIN_BOTON_DOSIS); correr(6000); } catch (Dormido &) { durmio = true; }
  COMPROBAR(avanceMsTotal == 0, "con batería agotada no mueve el motor");
  COMPROBAR(durmio, "y se duerme");
}

void pruebaBateriaSeAgota() {
  arrancar(3.6);
  bateria(3.25);
  bool durmio = false;
  try { correr(12000); } catch (Dormido &) { durmio = true; }
  COMPROBAR(durmio, "si la batería cae en uso, avisa y se duerme");
}

void pruebaDesgasteMemoria() {
  arrancar();
  sim::escriturasNvs = 0;
  for (int i = 0; i < 10; i++) { clic(PIN_BOTON_DOSIS); correr(5000); }
  correr(60000);
  std::printf("    %d escrituras en memoria para 10 dosis\n", sim::escriturasNvs);
  COMPROBAR(sim::escriturasNvs <= 10 * 3 * 2, "pocas escrituras por dosis (no gasta la flash)");
}

void apoyar()   { sim::entradas[PIN_CONTACTO] = LOW; }
void levantar() { sim::entradas[PIN_CONTACTO] = HIGH; }

void pruebaSinContactoNoSale() {
  arrancar(); levantar();
  clic(PIN_BOTON_DOSIS); correr(ESPERA_CONTACTO_MS + 1000);
  pulsar(PIN_BOTON_DOSIS); correr(3000); soltar(PIN_BOTON_DOSIS); correr(1000);
  std::printf("    %.2f ml con la paleta en el aire\n", mlSoltados);
  COMPROBAR(avanceMsTotal == 0, "sin contacto no sale nada (ni dosis ni continuo)");
  COMPROBAR(estado == REPOSO, "la dosis sin contacto se cancela sola");
}

void pruebaPulsarYLuegoApoyar() {
  arrancar(); levantar();
  clic(PIN_BOTON_DOSIS); correr(2000);
  COMPROBAR(avanceMsTotal == 0, "espera al contacto");
  apoyar(); correr(5000);
  std::printf("    %.2f ml tras apoyar 2 s después de pulsar\n", mlSoltados);
  COMPROBAR(cerca(mlSoltados, DOSIS_ML, 0.05), "al apoyar suelta la dosis completa");
}

void pruebaLevantarAMitad() {
  arrancar();
  clic(PIN_BOTON_DOSIS); correr(1000);
  double aMitad = mlSoltados;
  levantar(); correr(2000);
  double enElAire = mlSoltados - aMitad;
  COMPROBAR(enElAire < 0.03, "al levantar la paleta deja de salir crema (< 0,03 ml: lo que tarda el antirrebote)");
  COMPROBAR(retrocesoMsTotal > 0, "y hace antigoteo para que no gotee");
  apoyar(); correr(5000);
  std::printf("    %.2f ml antes de levantar, %.2f en el aire, %.2f en total\n", aMitad, enElAire, mlSoltados);
  COMPROBAR(cerca(mlSoltados, DOSIS_ML, 0.05), "al volver a apoyar completa la dosis exacta");
}

void pruebaContinuoIntermitente() {
  arrancar();
  pulsar(PIN_BOTON_DOSIS);
  for (int i = 0; i < 3; i++) { apoyar(); correr(2000); levantar(); correr(1000); }
  soltar(PIN_BOTON_DOSIS); correr(1000);
  // Cada vez que se vuelve a apoyar, primero recupera el hueco del antigoteo (no es crema).
  double hueco = ANTIGOTEO_MS / 1000.0 * MM_POR_SEGUNDO * ML_POR_MM;
  double esperado = 3 * 2.0 * MM_POR_SEGUNDO * ML_POR_MM - 2 * hueco;
  std::printf("    %.2f ml (esperado ~%.2f: solo los 6 s con contacto)\n", mlSoltados, esperado);
  COMPROBAR(cerca(mlSoltados, esperado, 0.1), "en continuo solo sale crema mientras hay contacto");
}

void pruebaRebotesContacto() {
  arrancar(); levantar();
  clic(PIN_BOTON_DOSIS);
  for (int i = 0; i < 20; i++) { apoyar(); correr(3); levantar(); correr(3); }   // roce
  correr(500);
  COMPROBAR(mlSoltados < 0.02, "un roce de pocos ms no suelta crema");
}

// ---------------------------------------------------------------- main
int main() {
  struct { const char *nombre; std::function<void()> f; } pruebas[] = {
    {"Pulsación corta = dosis fija + antigoteo", pruebaPulsacionCorta},
    {"Varias dosis seguidas suman bien", pruebaDosisSeguidas},
    {"Misma dosis con batería llena o baja", pruebaCompensacionTension},
    {"Mantener = dosis continua", pruebaMantener},
    {"Pulsar durante la dosis la cancela", pruebaCancelar},
    {"Límite de seguridad del modo continuo", pruebaLimiteContinuo},
    {"Apagado automático a los 2 min", pruebaApagado},
    {"El uso reinicia la cuenta de apagado", pruebaUsoReiniciaApagado},
    {"Despertar no suelta crema", pruebaDespertarNoDosifica},
    {"Primer arranque: pide retraer", pruebaPrimerArranque},
    {"Jeringa vacía + retraer", pruebaJeringaVacia},
    {"Crema más dura de lo calibrado", pruebaCremaMasDura},
    {"Retraer se puede detener", pruebaRetraerSeDetiene},
    {"Batería agotada al arrancar", pruebaBateriaVacia},
    {"Batería que se agota en uso", pruebaBateriaSeAgota},
    {"Escrituras en memoria", pruebaDesgasteMemoria},
    {"CONTACTO: paleta en el aire no suelta crema", pruebaSinContactoNoSale},
    {"CONTACTO: pulsar y luego apoyar", pruebaPulsarYLuegoApoyar},
    {"CONTACTO: levantar a mitad de dosis", pruebaLevantarAMitad},
    {"CONTACTO: continuo con contacto intermitente", pruebaContinuoIntermitente},
    {"CONTACTO: roces cortos se ignoran", pruebaRebotesContacto},
  };
  int ok = 0, total = 0;
  for (auto &p : pruebas) {
    total++;
    std::printf("[%2d] %s\n", total, p.nombre);
    std::fflush(stdout);
    pid_t pid = fork();          // cada prueba en un proceso limpio
    if (pid == 0) {
      try { p.f(); } catch (Dormido &) { std::printf("    FALLO: se durmió inesperadamente\n"); fallos++; }
      std::fflush(stdout);
      _exit(fallos ? 1 : 0);
    }
    int st; waitpid(pid, &st, 0);
    bool bien = WIFEXITED(st) && WEXITSTATUS(st) == 0;
    std::printf("    %s\n", bien ? "OK" : "FALLA");
    ok += bien;
  }
  std::printf("\nResultado: %d/%d pruebas superadas\n", ok, total);
  return ok == total ? 0 : 1;
}
