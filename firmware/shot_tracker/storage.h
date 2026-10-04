#pragma once
#include <Arduino.h>
#include <FS.h>
#include <LittleFS.h>
#include "model.h"

// Layout on the internal flash (LittleFS):
//   /rounds/<id>.bin   header + shots, rewritten after every change (write .tmp, then swap)
//   /current           id of the round in progress (absent when no round is active)
//   /next_id           next round id
// A round survives resets and power loss, so an accidental RESET mid-round just resumes.

namespace storage {

inline String roundPath(uint32_t id) { return String("/rounds/") + id + ".bin"; }

inline bool begin() {
  if (!LittleFS.begin(true)) return false;  // format on first boot
  if (!LittleFS.exists("/rounds")) LittleFS.mkdir("/rounds");
  return true;
}

inline uint32_t readU32(const char* path, uint32_t fallback) {
  File f = LittleFS.open(path, "r");
  if (!f) return fallback;
  uint32_t v = f.parseInt();
  f.close();
  return v ? v : fallback;
}
inline void writeU32(const char* path, uint32_t v) {
  File f = LittleFS.open(path, "w");
  if (f) { f.print(v); f.close(); }
}

inline uint32_t allocateId() {
  uint32_t id = readU32("/next_id", 1);
  writeU32("/next_id", id + 1);
  return id;
}

inline bool save(const Round& r) {
  String path = roundPath(r.h.id), tmp = path + ".tmp";
  File f = LittleFS.open(tmp, "w");
  if (!f) return false;
  size_t want = sizeof(RoundHeader) + sizeof(Shot) * r.h.shotCount;
  size_t got = f.write((const uint8_t*)&r.h, sizeof(RoundHeader));
  got += f.write((const uint8_t*)r.shots, sizeof(Shot) * r.h.shotCount);
  f.close();
  if (got != want) return false;
  LittleFS.remove(path);
  if (!LittleFS.rename(tmp, path)) return false;
  if (r.h.finished) LittleFS.remove("/current");
  else writeU32("/current", r.h.id);
  return true;
}

inline bool load(uint32_t id, Round& r) {
  String path = roundPath(id);
  if (!LittleFS.exists(path) && LittleFS.exists(path + ".tmp")) LittleFS.rename(path + ".tmp", path);  // crash between remove/rename
  File f = LittleFS.open(path, "r");
  if (!f) return false;
  RoundHeader h;
  bool ok = f.read((uint8_t*)&h, sizeof h) == sizeof h && h.magic == ROUND_MAGIC &&
            h.version == ROUND_VERSION && h.shotCount <= MAX_SHOTS;
  if (ok) {
    r.h = h;
    ok = f.read((uint8_t*)r.shots, sizeof(Shot) * h.shotCount) == sizeof(Shot) * h.shotCount;
  }
  f.close();
  return ok;
}

inline uint32_t currentRoundId() { return readU32("/current", 0); }
inline void clearCurrent() { LittleFS.remove("/current"); }

inline bool removeRound(uint32_t id) {
  if (currentRoundId() == id) clearCurrent();
  return LittleFS.remove(roundPath(id));
}

// ---------------------------------------------------------------------------
// Export (USB serial). GeoJSON can be dropped straight onto geojson.io for a satellite view.
// ---------------------------------------------------------------------------
inline void printCoord(Stream& out, const GeoPoint& p) {
  out.printf("[%.7f,%.7f]", p.lon_e7 / 1e7, p.lat_e7 / 1e7);  // GeoJSON is [lon, lat]
}

inline void exportGeoJSON(const Round& r, Stream& out) {
  out.printf("{\"type\":\"FeatureCollection\",\"properties\":{\"round\":%lu,\"startUnix\":%lu,\"units\":\"%s\"},\"features\":[",
             (unsigned long)r.h.id, (unsigned long)r.h.startUnix, unitLabel());
  bool first = true;
  uint8_t shotOnHole[NUM_HOLES + 1] = {0};
  for (uint16_t i = 0; i < r.h.shotCount; i++) {
    const Shot& s = r.shots[i];
    uint8_t n = ++shotOnHole[s.hole <= NUM_HOLES ? s.hole : 0];
    if (!s.start.valid) continue;
    bool line = (s.flags & SHOT_HAS_END) && s.end.valid;
    if (!first) out.print(',');
    first = false;
    out.print("{\"type\":\"Feature\",\"geometry\":{\"type\":");
    if (line) { out.print("\"LineString\",\"coordinates\":["); printCoord(out, s.start); out.print(','); printCoord(out, s.end); out.print("]}"); }
    else      { out.print("\"Point\",\"coordinates\":"); printCoord(out, s.start); out.print('}'); }
    out.printf(",\"properties\":{\"hole\":%u,\"shot\":%u,\"club\":\"%s\",\"distance\":%d,\"putt\":%s,\"startAccM\":%.1f,\"endAccM\":%.1f,\"startUnix\":%lu,\"endUnix\":%lu}}",
               s.hole, n, CLUBS[s.club % NUM_CLUBS], shotDistance(s), (s.flags & SHOT_PUTT) ? "true" : "false",
               s.start.hacc_dm / 10.0, s.end.hacc_dm / 10.0, (unsigned long)s.start.unix, (unsigned long)s.end.unix);
  }
  out.println("]}");
}

inline void exportCSV(const Round& r, Stream& out) {
  out.println("hole,shot,club,putt,start_lat,start_lon,start_acc_m,end_lat,end_lon,end_acc_m,distance,start_unix,end_unix");
  uint8_t shotOnHole[NUM_HOLES + 1] = {0};
  for (uint16_t i = 0; i < r.h.shotCount; i++) {
    const Shot& s = r.shots[i];
    uint8_t n = ++shotOnHole[s.hole <= NUM_HOLES ? s.hole : 0];
    bool hasEnd = s.flags & SHOT_HAS_END;
    out.printf("%u,%u,%s,%d,", s.hole, n, CLUBS[s.club % NUM_CLUBS], (s.flags & SHOT_PUTT) ? 1 : 0);
    if (s.start.valid) out.printf("%.7f,%.7f,%.1f,", s.start.lat_e7 / 1e7, s.start.lon_e7 / 1e7, s.start.hacc_dm / 10.0);
    else out.print(",,,");
    if (hasEnd && s.end.valid) out.printf("%.7f,%.7f,%.1f,", s.end.lat_e7 / 1e7, s.end.lon_e7 / 1e7, s.end.hacc_dm / 10.0);
    else out.print(",,,");
    out.printf("%d,%lu,%lu\n", shotDistance(s), (unsigned long)s.start.unix, (unsigned long)s.end.unix);
  }
}

}  // namespace storage
