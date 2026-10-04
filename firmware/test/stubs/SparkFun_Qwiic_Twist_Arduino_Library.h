#pragma once
#include "Wire.h"
extern int16_t g_twistDiff; extern bool g_twistDown;
class TWIST { public: bool begin(TwoWire&){ return true; } int16_t getDiff(bool){ int16_t d=g_twistDiff; g_twistDiff=0; return d; }
  bool isPressed(){ return g_twistDown; } void clearInterrupts(){} bool setColor(uint8_t,uint8_t,uint8_t){ return true; } };
