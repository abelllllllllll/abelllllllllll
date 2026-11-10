// Simulación de la memoria no volátil (NVS) del ESP32.
#pragma once
#include <map>
#include <string>
namespace sim { extern std::map<std::string, float> nvs; extern int escriturasNvs; }
class Preferences {
 public:
  bool begin(const char*, bool) { return true; }
  void end() {}
  size_t putFloat(const char* k, float v) { sim::nvs[k] = v; sim::escriturasNvs++; return 4; }
  size_t putBool(const char* k, bool v) { sim::nvs[k] = v; sim::escriturasNvs++; return 1; }
  float getFloat(const char* k, float d) { auto i = sim::nvs.find(k); return i == sim::nvs.end() ? d : i->second; }
  bool getBool(const char* k, bool d) { auto i = sim::nvs.find(k); return i == sim::nvs.end() ? d : i->second != 0; }
};
