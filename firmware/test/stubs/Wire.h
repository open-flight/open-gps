#pragma once
#include "Arduino.h"
class TwoWire { public: void begin(int,int){} void setClock(uint32_t){} };
extern TwoWire Wire;
