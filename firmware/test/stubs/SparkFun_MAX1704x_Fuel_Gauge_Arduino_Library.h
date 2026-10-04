#pragma once
#include "Wire.h"
enum { MAX1704X_MAX17048 };
class SFE_MAX1704X { public: SFE_MAX1704X(int){} bool begin(TwoWire&){ return true; } float getSOC(){ return 87.4f; } float getChangeRate(){ return 0; } };
