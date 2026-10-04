#pragma once
#include <Arduino.h>
#include <Wire.h>
#include <SparkFun_u-blox_GNSS_v3.h>
#include "config.h"
#include "model.h"

// Wraps the NEO-M9N. Call poll() every loop. Marking a point averages every good
// fix over GPS_MARK_WINDOW_MS, which noticeably tightens the position vs one fix.
class Gps {
 public:
  struct Fix {
    bool ok = false;         // usable 2D/3D fix with gnssFixOk
    uint8_t fixType = 0;
    uint8_t siv = 0;
    int32_t lat_e7 = 0, lon_e7 = 0;
    uint32_t hacc_mm = 0;
    uint32_t unix = 0;
    uint32_t atMs = 0;       // millis() when received
  };

  bool begin(TwoWire& wire) {
    for (int i = 0; i < 5 && !present_; i++) {
      present_ = gnss_.begin(wire);
      if (!present_) delay(200);
    }
    if (!present_) return false;
    gnss_.setI2COutput(COM_TYPE_UBX);
    gnss_.setNavigationFrequency(GPS_NAV_HZ);
    gnss_.setDynamicModel(DYN_MODEL_PEDESTRIAN);
    gnss_.setAutoPVT(true);
    return true;
  }

  bool present() const { return present_; }

  void poll() {
    if (!present_ || !gnss_.getPVT()) return;  // non-blocking with autoPVT
    Fix f;
    f.fixType = gnss_.getFixType();
    f.siv = gnss_.getSIV();
    f.ok = gnss_.getGnssFixOk() && (f.fixType == 2 || f.fixType == 3 || f.fixType == 4);
    f.lat_e7 = gnss_.getLatitude();
    f.lon_e7 = gnss_.getLongitude();
    int32_t acc = gnss_.getHorizontalAccEst();
    f.hacc_mm = acc < 0 ? 0 : (uint32_t)acc;
    f.unix = (gnss_.getDateValid() && gnss_.getTimeValid()) ? gnss_.getUnixEpoch() : 0;
    f.atMs = millis();
    last_ = f;
    if (marking_ && f.ok && f.hacc_mm <= GPS_MAX_GOOD_HACC_MM) {
      sumLat_ += f.lat_e7;
      sumLon_ += f.lon_e7;
      n_++;
      if (f.hacc_mm < bestAcc_) bestAcc_ = f.hacc_mm;
      if (f.siv > bestSiv_) bestSiv_ = f.siv;
      if (f.unix) lastUnix_ = f.unix;
    }
  }

  // Latest fix, treated as stale after 3 s.
  const Fix& fix() const { return last_; }
  bool hasFix() const { return last_.ok && millis() - last_.atMs < 3000; }

  // --- averaged marking ---
  void startMark() {
    marking_ = true; markStart_ = millis();
    sumLat_ = sumLon_ = 0; n_ = 0; bestAcc_ = UINT32_MAX; bestSiv_ = 0; lastUnix_ = 0;
  }
  bool marking() const { return marking_; }
  float markProgress() const { return min(1.0f, (millis() - markStart_) / (float)GPS_MARK_WINDOW_MS); }
  bool markDone() const { return marking_ && millis() - markStart_ >= GPS_MARK_WINDOW_MS; }
  // Ends the window. Returns true (and fills p) if enough good samples arrived.
  bool finishMark(GeoPoint& p) {
    marking_ = false;
    p = GeoPoint();
    if (n_ < GPS_MARK_MIN_SAMPLES) return false;
    p.lat_e7 = (int32_t)(sumLat_ / n_);
    p.lon_e7 = (int32_t)(sumLon_ / n_);
    p.hacc_dm = (uint16_t)min<uint32_t>(bestAcc_ / 100, 65535);
    p.siv = bestSiv_;
    p.valid = 1;
    p.unix = lastUnix_;
    return true;
  }
  void cancelMark() { marking_ = false; }

 private:
  SFE_UBLOX_GNSS gnss_;
  bool present_ = false;
  Fix last_;
  bool marking_ = false;
  uint32_t markStart_ = 0;
  int64_t sumLat_ = 0, sumLon_ = 0;
  uint16_t n_ = 0;
  uint32_t bestAcc_ = UINT32_MAX;
  uint8_t bestSiv_ = 0;
  uint32_t lastUnix_ = 0;
};
