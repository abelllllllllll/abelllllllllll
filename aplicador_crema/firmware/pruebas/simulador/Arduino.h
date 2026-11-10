// Simulador mínimo de la API de Arduino/ESP32 para probar el firmware en el PC.
#pragma once
#include <cstdint>
#include <cstdio>
#include <cstdarg>
#include <cstring>
#include <cmath>
#include <algorithm>
using std::min; using std::max; using std::fabs;
#define HIGH 1
#define LOW 0
#define INPUT 0
#define OUTPUT 1
#define INPUT_PULLUP 2
#define ADC_11db 3
namespace sim {
  extern unsigned long tiempo;
  extern int salidas[32];
  extern int entradas[32];
  extern int pwm[32];
  extern int adcMv[32];
  void avanzar(unsigned long ms);
}
inline unsigned long millis() { return sim::tiempo; }
inline void delay(unsigned long ms) { sim::avanzar(ms); }
inline void pinMode(uint8_t, uint8_t) {}
inline void digitalWrite(uint8_t p, int v) { sim::salidas[p] = v; }
inline int digitalRead(uint8_t p) { return sim::entradas[p]; }
inline bool ledcAttach(uint8_t, uint32_t, uint8_t) { return true; }
inline bool ledcWrite(uint8_t p, uint32_t d) { sim::pwm[p] = d; return true; }
inline uint32_t analogReadMilliVolts(uint8_t p) { return sim::adcMv[p]; }
inline void analogSetPinAttenuation(uint8_t, int) {}
struct SerialSim {
  bool silencio = true;
  void begin(long) {}
  void println(const char* s) { if (!silencio) std::printf("    [serie] %s\n", s); }
  void printf(const char* f, ...) {
    if (silencio) return;
    va_list a; va_start(a, f); std::printf("    [serie] "); std::vprintf(f, a); va_end(a);
  }
};
extern SerialSim Serial;
