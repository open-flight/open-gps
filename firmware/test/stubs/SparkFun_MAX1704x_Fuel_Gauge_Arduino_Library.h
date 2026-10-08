#pragma once
#include "Wire.h"
enum { MAX1704X_MAX17048 };
extern float g_vcell, g_crate;
class SFE_MAX1704X { public: SFE_MAX1704X(int){} bool begin(TwoWire&){ return true; } float getSOC(){ return 87.4f; }
  float getVoltage(){ return g_vcell; } float getChangeRate(){ return g_crate; }
  uint8_t disableHibernate(){ return 0; } uint8_t setHIBRTHibThr(uint8_t){ return 0; } uint8_t setHIBRTActThr(uint8_t){ return 0; } };
