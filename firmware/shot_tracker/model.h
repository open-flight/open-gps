#pragma once
#include <Arduino.h>
#include <math.h>
#include "config.h"

// One marked position. lat/lon are degrees * 1e7 (u-blox native units).
struct GeoPoint {
  int32_t lat_e7 = 0;
  int32_t lon_e7 = 0;
  uint16_t hacc_dm = 0;  // horizontal accuracy estimate, decimetres (best fix in the averaging window)
  uint8_t siv = 0;       // satellites in view
  uint8_t valid = 0;     // 1 = real fix, 0 = saved without GPS
  uint32_t unix = 0;     // UTC seconds, 0 if unknown
};

enum ShotFlags : uint8_t {
  SHOT_HAS_END = 1 << 0,  // landing point recorded
  SHOT_PUTT = 1 << 1,     // single-point shot
};

struct Shot {
  uint8_t hole = 0;  // 1..NUM_HOLES
  uint8_t club = 0;  // index into CLUBS
  uint8_t flags = 0;
  uint8_t reserved = 0;
  GeoPoint start;
  GeoPoint end;
};

// On-disk header. Bump ROUND_VERSION if Shot/RoundHeader layout changes.
constexpr uint32_t ROUND_MAGIC = 0x474F4C46;  // "GOLF"
constexpr uint16_t ROUND_VERSION = 1;

struct RoundHeader {
  uint32_t magic = ROUND_MAGIC;
  uint16_t version = ROUND_VERSION;
  uint16_t shotCount = 0;
  uint32_t id = 0;
  uint32_t startUnix = 0;
  uint8_t currentHole = 1;
  uint8_t finished = 0;
  uint8_t reserved[2] = {0, 0};
};

struct Round {
  RoundHeader h;
  Shot shots[MAX_SHOTS];

  // Reset in place. Never write `round = Round()`: that builds a ~9 KB temporary
  // on the stack, which overflows Arduino's 8 KB loop task.
  void reset() { h = RoundHeader(); memset(shots, 0, sizeof shots); }
  bool active() const { return h.id != 0 && !h.finished; }
  Shot* last() { return h.shotCount ? &shots[h.shotCount - 1] : nullptr; }
  // A non-putt shot without a landing point = ball in the air / walking to it.
  bool inFlight() const {
    if (!h.shotCount) return false;
    const Shot& s = shots[h.shotCount - 1];
    return !(s.flags & SHOT_PUTT) && !(s.flags & SHOT_HAS_END);
  }
  uint8_t strokesOnHole(uint8_t hole) const {
    uint8_t n = 0;
    for (uint16_t i = 0; i < h.shotCount; i++) n += (shots[i].hole == hole);
    return n;
  }
  uint16_t totalStrokes() const { return h.shotCount; }
};

// ---------------------------------------------------------------------------
// Geo math
// ---------------------------------------------------------------------------
inline double distanceMeters(int32_t lat1e7, int32_t lon1e7, int32_t lat2e7, int32_t lon2e7) {
  const double R = 6371008.8;  // mean Earth radius
  const double k = M_PI / 180.0 / 1e7;
  double p1 = lat1e7 * k, p2 = lat2e7 * k;
  double dp = (lat2e7 - lat1e7) * k, dl = (lon2e7 - lon1e7) * k;
  double a = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
  return 2 * R * atan2(sqrt(a), sqrt(1 - a));
}
inline double distanceMeters(const GeoPoint& a, const GeoPoint& b) {
  return distanceMeters(a.lat_e7, a.lon_e7, b.lat_e7, b.lon_e7);
}
inline double toDisplayUnits(double meters) { return USE_YARDS ? meters * 1.0936133 : meters; }
inline const char* unitLabel() { return USE_YARDS ? "yds" : "m"; }

// Shot distance in display units, or -1 if unknown.
inline int shotDistance(const Shot& s) {
  if (!(s.flags & SHOT_HAS_END) || !s.start.valid || !s.end.valid) return -1;
  return (int)lround(toDisplayUnits(distanceMeters(s.start, s.end)));
}
