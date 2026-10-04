#pragma once
#define ESP_SLEEP_WAKEUP_ALL 0
extern bool g_slept;
inline void esp_sleep_disable_wakeup_source(int){} inline void esp_deep_sleep_start(){ g_slept=true; throw 42; }
