#pragma once
#include "Wire.h"
const uint8_t COM_TYPE_UBX=1; enum { DYN_MODEL_PEDESTRIAN=3 };
extern double g_lat, g_lon; extern bool g_fix; extern uint32_t g_lastPvt;
const uint8_t kUBLOXGNSSDefaultAddress=0x42; const uint16_t kUBLOXGNSSDefaultMaxWait=1100; enum { COMM_TYPE_I2C };
namespace SparkFun_UBLOX_GNSS { class SfeI2C { public: virtual ~SfeI2C(){} virtual uint16_t available(){ return 0; } bool init(TwoWire&, uint8_t){ return true; } }; }
class DevUBLOXGNSS { protected: int _commType=0; void setCommunicationBus(SparkFun_UBLOX_GNSS::SfeI2C&){} bool init(uint16_t, bool){ return true; }
 public: void setI2COutput(int){} void setNavigationFrequency(int){} void setDynamicModel(int){} void setAutoPVT(bool){}
  bool getPVT(){ if(millis()-g_lastPvt>=250){ g_lastPvt=millis(); return true;} return false; }
  uint8_t getFixType(){ return g_fix?3:0; } uint8_t getSIV(){ return g_fix?14:2; } bool getGnssFixOk(){ return g_fix; }
  int32_t getLatitude(){ return (int32_t)llround(g_lat*1e7); } int32_t getLongitude(){ return (int32_t)llround(g_lon*1e7); }
  int32_t getHorizontalAccEst(){ return 1800; } bool getDateValid(){ return true; } bool getTimeValid(){ return true; } uint32_t getUnixEpoch(){ return 1790000000 + millis()/1000; } };
class SFE_UBLOX_GNSS : public DevUBLOXGNSS { public: bool begin(TwoWire&){ return true; } };
