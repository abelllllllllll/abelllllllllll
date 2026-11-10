#pragma once
#include <cstdint>
typedef enum { ESP_SLEEP_WAKEUP_UNDEFINED = 0, ESP_SLEEP_WAKEUP_GPIO = 7 } esp_sleep_source_t;
typedef enum { ESP_GPIO_WAKEUP_GPIO_LOW = 0, ESP_GPIO_WAKEUP_GPIO_HIGH = 1 } esp_deepsleep_gpio_wake_up_mode_t;
namespace sim { extern esp_sleep_source_t causaDespertar; extern uint64_t mascaraDespertar; }
struct Dormido {};
inline int esp_deep_sleep_enable_gpio_wakeup(uint64_t m, esp_deepsleep_gpio_wake_up_mode_t) { sim::mascaraDespertar = m; return 0; }
[[noreturn]] inline void esp_deep_sleep_start() { throw Dormido{}; }
inline esp_sleep_source_t esp_sleep_get_wakeup_cause() { return sim::causaDespertar; }
