// =====================================================================
//  Golf Shot Tracker firmware - v0.1
//  SparkFun Thing Plus ESP32-S3 + NEO-M9N GPS + Qwiic OLED 1.3" + Qwiic Twist
//
//  Dial:  turn = choose club / move in menus
//         click = select / mark position
//         hold  = open menu (hold again or pick "Back" to close)
//  Shot:  pick club -> click at the ball (start marked) -> walk to the ball ->
//         click (landing marked, distance shown). Putter = one click, no landing.
//         "Hole out" (last slot on the dial, after the putter) finishes the hole.
//  USB serial (115200): type "help" for export commands.
// =====================================================================
#include <Arduino.h>
#include <Wire.h>
#include <esp_sleep.h>
#include <driver/gpio.h>
#include <time.h>
#include <SparkFun_MAX1704x_Fuel_Gauge_Arduino_Library.h>

#include "config.h"
#include "model.h"
#include "storage.h"
#include "gps.h"
#include "input.h"
#include "ui.h"

// ---------------------------------------------------------------------------
// globals
// ---------------------------------------------------------------------------
Ui ui;
Gps gps;
Input input;
SFE_MAX1704X fuel(MAX1704X_MAX17048);
bool fuelOk = false;
int batteryPct = -1;
bool charging = false;

static Round round_;      // the round in progress (~9 KB)
static Round scratch_;    // used by serial export

enum class Scr : uint8_t { Home, Club, Mark, Flight, Result, Menu, Holes, Confirm, Score, GpsInfo };
Scr scr = Scr::Home;

enum class MarkFor : uint8_t { Start, End };
MarkFor markFor = MarkFor::Start;

enum Action : uint8_t {
  A_NONE, A_BACK, A_NEW_ROUND, A_NEXT_HOLE, A_GOTO_HOLE, A_UNDO, A_SCORECARD, A_GPS,
  A_END_ROUND, A_POWER_OFF, A_ROUNDS_INFO, A_RETRY_MARK, A_SAVE_NO_GPS, A_CANCEL_MARK,
  A_FINISH_ROUND, A_PICK_ROUND, A_DELETE_ROUND, A_HOME,
};

uint8_t dialSel = 0;         // 0..NUM_CLUBS-1 = club, NUM_CLUBS = "Hole out"
int lastResult = -1;
uint32_t resultAt = 0;
uint8_t holeSel = 1;

// generic list menu (also used for Home and the mark-failed prompt)
struct MenuItem { char label[22]; Action act; uint32_t arg; };
MenuItem menu[10];
const char* menuLabels[10];
uint8_t menuCount = 0, menuSel = 0;
char menuTitle[22] = "";
Scr menuBack = Scr::Club;    // where long-press / "Back" returns to

// yes/no confirm
Action confirmAct = A_NONE;
uint32_t confirmArg = 0;
char confirmTitle[22] = "";
char confirmLine[22] = "";
uint8_t confirmSel = 0;      // 0 = No (default), 1 = Yes
Scr confirmBack = Scr::Menu;

char toast[22] = "";
uint32_t toastUntil = 0;
bool dirty = true;

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------
uint8_t putterIndex() {
  for (uint8_t i = 0; i < NUM_CLUBS; i++) if (!strcmp(CLUBS[i], PUTTER_NAME)) return i;
  return NUM_CLUBS - 1;
}
bool isPutter(uint8_t club) { return club == putterIndex(); }

void go(Scr s) { scr = s; dirty = true; }
void showToast(const char* msg, uint32_t ms = 2000) {
  strlcpy(toast, msg, sizeof toast);
  toastUntil = millis() + ms;
  dirty = true;
}
void saveRound() {
  if (!storage::save(round_)) showToast("SAVE FAILED!", 4000);
}
Scr roundHome() { return round_.inFlight() ? Scr::Flight : Scr::Club; }

void menuReset(const char* title, Scr back) {
  strlcpy(menuTitle, title, sizeof menuTitle);
  menuCount = 0; menuSel = 0; menuBack = back;
}
void menuAdd(const char* label, Action a, uint32_t arg = 0) {
  if (menuCount >= 10) return;
  strlcpy(menu[menuCount].label, label, sizeof menu[0].label);
  menu[menuCount].act = a;
  menu[menuCount].arg = arg;
  menuLabels[menuCount] = menu[menuCount].label;
  menuCount++;
}
void confirm(const char* title, const char* line, Action a, Scr back, uint32_t arg = 0) {
  strlcpy(confirmTitle, title, sizeof confirmTitle);
  strlcpy(confirmLine, line, sizeof confirmLine);
  confirmAct = a; confirmArg = arg; confirmSel = 0; confirmBack = back;
  go(Scr::Confirm);
}

// Home and the rounds list share the menu buffer, so going "back" to Home rebuilds it.
void openHome();
void menuGoBack() { if (menuBack == Scr::Home) openHome(); else go(menuBack); }

// ---------------------------------------------------------------------------
// menus
// ---------------------------------------------------------------------------
// Fills ids[] with saved round ids, newest first. Returns how many were found (may exceed max).
int listRoundIds(uint32_t* ids, int max) {
  int n = 0;
  File dir = LittleFS.open("/rounds");
  for (File f = dir.openNextFile(); f; f = dir.openNextFile()) {
    String name = f.name();
    int slash = name.lastIndexOf('/');
    if (slash >= 0) name = name.substring(slash + 1);
    if (!name.endsWith(".bin")) continue;
    uint32_t id = name.toInt();
    // insertion sort, keeping the newest `max`
    int i = min(n, max);
    while (i > 0 && ids[i - 1] < id) { if (i < max) ids[i] = ids[i - 1]; i--; }
    if (i < max) ids[i] = id;
    n++;
  }
  return n;
}
int countRounds() { uint32_t none[1]; return listRoundIds(none, 0); }

// "Oct 2" from the round's start time, or "" when GPS time wasn't known.
void roundDate(const Round& r, char* buf, size_t n) {
  buf[0] = 0;
  if (!r.h.startUnix) return;
  static const char* const MON[] = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
  time_t t = r.h.startUnix;
  struct tm tm;
  gmtime_r(&t, &tm);
  snprintf(buf, n, "%s %d", MON[tm.tm_mon % 12], tm.tm_mday);
}

void openRounds() {
  uint32_t ids[9];
  int total = listRoundIds(ids, 9);
  menuReset(total > 9 ? "ROUNDS (newest 9)" : "ROUNDS", Scr::Home);
  menuAdd("Back", A_HOME);
  for (int i = 0; i < min(total, 9); i++) {
    char date[8], buf[22];
    if (!storage::load(ids[i], scratch_)) {
      snprintf(buf, sizeof buf, "#%lu (unreadable)", (unsigned long)ids[i]);
    } else {
      roundDate(scratch_, date, sizeof date);
      snprintf(buf, sizeof buf, "#%lu %s %u sh%s", (unsigned long)ids[i], date, scratch_.totalStrokes(),
               scratch_.h.finished ? "" : "*");
    }
    menuAdd(buf, A_PICK_ROUND, ids[i]);
  }
  go(Scr::Menu);
}

void openHome() {
  menuReset("SHOT TRACKER", Scr::Home);
  menuAdd("New round", A_NEW_ROUND);
  char buf[22];
  snprintf(buf, sizeof buf, "Saved rounds (%d)", countRounds());
  menuAdd(buf, A_ROUNDS_INFO);
  menuAdd("GPS status", A_GPS);
  menuAdd("Power off", A_POWER_OFF);
  go(Scr::Home);
}

void openRoundMenu() {
  menuReset("MENU", roundHome());
  menuAdd("Back", A_BACK);
  menuAdd("Next hole", A_NEXT_HOLE);
  menuAdd("Go to hole...", A_GOTO_HOLE);
  if (round_.h.shotCount) menuAdd(round_.inFlight() ? "Cancel this shot" : "Undo last shot", A_UNDO);
  menuAdd("Scorecard", A_SCORECARD);
  menuAdd("GPS status", A_GPS);
  menuAdd("End round", A_END_ROUND);
  menuAdd("Power off", A_POWER_OFF);
  go(Scr::Menu);
}

void openMarkFailed() {
  menuReset("NO GPS FIX", roundHome());
  menuAdd("Try again", A_RETRY_MARK);
  menuAdd("Save without GPS", A_SAVE_NO_GPS);
  menuAdd("Cancel", A_CANCEL_MARK);
  go(Scr::Menu);
}

// ---------------------------------------------------------------------------
// round logic
// ---------------------------------------------------------------------------
void newRound() {
  round_.reset();
  round_.h.id = storage::allocateId();
  round_.h.startUnix = gps.fix().unix;
  round_.h.currentHole = 1;
  saveRound();
  dialSel = 0;
  lastResult = -1;
  go(Scr::Club);
}

void finishRound() {
  round_.h.finished = 1;
  saveRound();
  char buf[22];
  snprintf(buf, sizeof buf, "Round %lu: %u shots", (unsigned long)round_.h.id, round_.totalStrokes());
  round_.reset();
  openHome();
  showToast(buf, 4000);
}

void gotoHole(uint8_t hole) {
  round_.h.currentHole = hole;
  saveRound();
  dialSel = round_.strokesOnHole(hole) ? dialSel : 0;
  go(Scr::Club);
}

void holeOut() {
  uint8_t h = round_.h.currentHole;
  char buf[22];
  uint8_t n = round_.strokesOnHole(h);
  snprintf(buf, sizeof buf, "Hole %u: %u stroke%s", h, n, n == 1 ? "" : "s");
  if (h >= NUM_HOLES) {
    confirm("ROUND COMPLETE?", buf, A_FINISH_ROUND, Scr::Club);
    return;
  }
  gotoHole(h + 1);
  showToast(buf, 3000);
}

void beginMark(MarkFor f) {
  markFor = f;
  gps.startMark();
  go(Scr::Mark);
}

void applyMark(const GeoPoint& p) {
  if (markFor == MarkFor::Start) {
    if (round_.h.shotCount >= MAX_SHOTS) { showToast("Shot limit reached"); go(Scr::Club); return; }
    Shot& s = round_.shots[round_.h.shotCount++];
    s = Shot();
    s.hole = round_.h.currentHole;
    s.club = dialSel;
    s.start = p;
    if (isPutter(dialSel)) s.flags |= SHOT_PUTT;
    saveRound();
    if (s.flags & SHOT_PUTT) {
      char buf[32];
      snprintf(buf, sizeof buf, "Putt #%u saved", round_.strokesOnHole(s.hole));
      showToast(buf);
      go(Scr::Club);
    } else {
      go(Scr::Flight);
    }
  } else {
    Shot* s = round_.last();
    if (!s) { go(Scr::Club); return; }
    s->end = p;
    s->flags |= SHOT_HAS_END;
    saveRound();
    lastResult = shotDistance(*s);
    resultAt = millis();
    go(Scr::Result);
  }
}

void undoLast() {
  Shot* s = round_.last();
  if (!s) return;
  bool wasFlight = round_.inFlight();
  dialSel = s->club;
  round_.h.currentHole = s->hole;
  round_.h.shotCount--;
  saveRound();
  showToast(wasFlight ? "Shot cancelled" : "Last shot deleted");
  go(Scr::Club);
}

[[noreturn]] void powerOff() {
  if (round_.active()) saveRound();
  ui.clear(); ui.medium();
  ui.center(10, "Power off");
  ui.small();
  ui.center(34, round_.active() ? "Round saved." : "");
  ui.center(46, "Press RESET to wake");
  ui.show();
  delay(1500);
  input.setColor(0, 0, 0);
  ui.power(false);
  // Cut the Qwiic rail (GPS, OLED, Twist) and hold it low through deep sleep.
  // Tip: cut jumper JP2 on the Thing Plus so the rail defaults OFF and this
  // pin isn't fighting its 10k pull-up (~330 uA) all night.
  digitalWrite(PIN_QWIIC_EN, LOW);
  // The gauge runs off the cell, so put back its default hibernate thresholds
  // (sample every 45 s instead of 250 ms) while we're off.
  if (fuelOk) { fuel.setHIBRTHibThr((uint8_t)0x80); fuel.setHIBRTActThr((uint8_t)0x30); }
  gpio_hold_en((gpio_num_t)PIN_QWIIC_EN);
  gpio_deep_sleep_hold_en();
  esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);  // only RESET (or the EN switch) wakes us
  esp_deep_sleep_start();
  while (true) {}
}

void doAction(Action a) {
  switch (a) {
    case A_BACK: menuGoBack(); break;
    case A_HOME: openHome(); break;
    case A_NEW_ROUND: newRound(); break;
    case A_NEXT_HOLE:
      if (round_.h.currentHole >= NUM_HOLES) holeOut(); else gotoHole(round_.h.currentHole + 1);
      break;
    case A_GOTO_HOLE: holeSel = round_.h.currentHole; go(Scr::Holes); break;
    case A_UNDO:
      confirm(round_.inFlight() ? "CANCEL SHOT?" : "DELETE LAST SHOT?",
              CLUBS[round_.last()->club % NUM_CLUBS], A_UNDO, Scr::Menu);
      break;
    case A_SCORECARD: go(Scr::Score); break;
    case A_GPS: go(Scr::GpsInfo); break;
    case A_END_ROUND: confirm("END ROUND?", "Round will be saved", A_END_ROUND, Scr::Menu); break;
    case A_POWER_OFF: powerOff(); break;
    case A_ROUNDS_INFO:
      if (countRounds()) openRounds(); else showToast("No saved rounds");
      break;
    case A_PICK_ROUND: {
      uint32_t id = menu[menuSel].arg;
      char title[22], line[22], date[8] = "";
      snprintf(title, sizeof title, "DELETE ROUND #%lu?", (unsigned long)id);
      if (storage::load(id, scratch_)) {
        roundDate(scratch_, date, sizeof date);
        snprintf(line, sizeof line, "%s%s%u shots", date, date[0] ? ", " : "", scratch_.totalStrokes());
      } else {
        strlcpy(line, "unreadable round", sizeof line);
      }
      confirm(title, line, A_DELETE_ROUND, Scr::Menu, id);
      break;
    }
    case A_RETRY_MARK: beginMark(markFor); break;
    case A_SAVE_NO_GPS: applyMark(GeoPoint()); break;
    case A_CANCEL_MARK: go(roundHome()); break;
    default: break;
  }
}

void doConfirmed(Action a) {
  switch (a) {
    case A_UNDO: undoLast(); break;
    case A_END_ROUND: finishRound(); break;
    case A_FINISH_ROUND: finishRound(); break;
    case A_DELETE_ROUND: {
      char buf[22];
      bool ok = storage::removeRound(confirmArg);
      snprintf(buf, sizeof buf, ok ? "Round #%lu deleted" : "Delete failed", (unsigned long)confirmArg);
      if (countRounds()) openRounds(); else openHome();
      showToast(buf);
      break;
    }
    default: break;
  }
}

// ---------------------------------------------------------------------------
// input handling per screen
// ---------------------------------------------------------------------------
void handle(const InputEvents& e) {
  if (!e.any()) return;
  dirty = true;
  switch (scr) {
    case Scr::Home:
    case Scr::Menu:
      if (e.turn) menuSel = (uint8_t)constrain((int)menuSel + e.turn, 0, menuCount - 1);
      if (e.click) doAction(menu[menuSel].act);
      else if (e.longPress && scr == Scr::Menu) menuGoBack();
      break;

    case Scr::Club:
      if (e.turn) dialSel = (uint8_t)(((int)dialSel + e.turn % (NUM_CLUBS + 1) + NUM_CLUBS + 1) % (NUM_CLUBS + 1));
      if (e.click) { if (dialSel == DIAL_HOLE_OUT) holeOut(); else beginMark(MarkFor::Start); }
      if (e.longPress) openRoundMenu();
      break;

    case Scr::Mark:
      if (e.longPress) { gps.cancelMark(); go(roundHome()); showToast("Cancelled"); }
      break;

    case Scr::Flight:
      if (e.click) beginMark(MarkFor::End);
      if (e.longPress) openRoundMenu();
      break;

    case Scr::Result:
      if (e.longPress) openRoundMenu(); else go(Scr::Club);
      break;

    case Scr::Holes:
      if (e.turn) holeSel = (uint8_t)(((int)holeSel - 1 + e.turn % NUM_HOLES + NUM_HOLES) % NUM_HOLES + 1);
      if (e.click) gotoHole(holeSel);
      if (e.longPress) go(Scr::Menu);
      break;

    case Scr::Confirm:
      if (e.turn) confirmSel = e.turn > 0 ? 1 : 0;
      if (e.click) { if (confirmSel) doConfirmed(confirmAct); else go(confirmBack); }
      if (e.longPress) go(confirmBack);
      break;

    case Scr::Score:
    case Scr::GpsInfo:
      if (e.click || e.longPress) go(round_.active() ? Scr::Menu : Scr::Home);
      break;
  }
}

// ---------------------------------------------------------------------------
// drawing
// ---------------------------------------------------------------------------
// ---- icons (pixel art, '#' = lit) ----
static const char* const ICON_PIN[] = {   // GPS, 5x7
  ".###.",
  "#...#",
  "#.#.#",
  "#...#",
  ".#.#.",
  "..#..",
  "..#..",
};
static const char* const ICON_BOLT[] = {  // charging, 4x7
  "..##",
  ".##.",
  ".#..",
  "####",
  "..#.",
  ".##.",
  "##..",
};
static const char* const ICON_FLAG_SMALL[] = {  // home title, 7x8
  ".##....",
  ".####..",
  ".######",
  ".####..",
  ".##....",
  ".#.....",
  ".#.....",
  "###....",
};
static const char* const ICON_FLAG[] = {  // "Hole out" on the dial, 11x16
  ".##........",
  ".####......",
  ".######....",
  ".########..",
  ".##########",
  ".########..",
  ".######....",
  ".####......",
  ".##........",
  ".#.........",
  ".#.........",
  ".#.........",
  ".#.........",
  ".#.........",
  "####.......",
  "#####......",
};

// Header: title on the left; GPS pin + satellite count and a battery gauge on the right.
void drawHeader(const char* left) {
  ui.small();
  ui.text(0, 0, left);
  int x = Ui::W;
  if (batteryPct >= 0) {
    x -= 12;
    ui.battery(x, 1, batteryPct);
    if (charging) { x -= 6; ui.art(x, 1, ICON_BOLT, 7); }
    x -= 4;
  }
  char r[8];
  const Gps::Fix& f = gps.fix();
  bool blinkOn = (millis() / 500) % 2;
  if (!gps.present()) strcpy(r, "x");
  else if (gps.hasFix()) snprintf(r, sizeof r, "%u", f.siv);
  else strcpy(r, "?");
  x -= ui.width(r);
  ui.text(x, 0, r);
  x -= 7;
  if (gps.hasFix() || blinkOn) ui.art(x, 0, ICON_PIN, 7);   // pin blinks while searching
  ui.hline(9);
}

void drawFooter(const char* s) {
  ui.small();
  if (millis() < toastUntil) { ui.fill(0, 54, Ui::W, 10); ui.text((Ui::W - ui.width(toast)) / 2, 55, toast, true); }
  else ui.center(56, s);
}

void roundLabel(char* buf, size_t n) {
  uint8_t h = round_.h.currentHole;
  snprintf(buf, n, "H%u Shot %u", h, round_.strokesOnHole(h) + (round_.inFlight() ? 0 : 1));
}

void drawBigDistance(int d, int y) {
  char num[16];
  if (d < 0) strcpy(num, "--"); else snprintf(num, sizeof num, "%d", d);
  int w = Ui::bigWidth(num);
  ui.small();
  int x = (Ui::W - w - 3 - ui.width(unitLabel())) / 2;
  ui.bigText(x, y, num);
  ui.text(x + w + 3, y + Ui::DIG_H - 7, unitLabel());
}

void render() {
  char buf[32];
  ui.clear();
  switch (scr) {
    case Scr::Home:
    case Scr::Menu:
      if (scr == Scr::Home) ui.list(menuTitle, menuLabels, menuCount, menuSel, ICON_FLAG_SMALL, 7, 8);
      else ui.list(menuTitle, menuLabels, menuCount, menuSel);
      if (millis() < toastUntil) drawFooter("");
      break;

    case Scr::Club: {
      roundLabel(buf, sizeof buf);
      drawHeader(buf);
      ui.medium();
      const char* name = dialSel == DIAL_HOLE_OUT ? "Hole out" : CLUBS[dialSel];
      ui.center(20, name);
      if (dialSel == DIAL_HOLE_OUT) ui.art((Ui::W - ui.width(name)) / 2 - 15, 20, ICON_FLAG, 16);
      ui.text(0, 20, "<");
      ui.right(20, ">");
      const Shot* s = round_.last();
      if (dialSel == DIAL_HOLE_OUT) snprintf(buf, sizeof buf, "click: finish hole %u", round_.h.currentHole);
      else if (s && lastResult >= 0 && !(s->flags & SHOT_PUTT)) snprintf(buf, sizeof buf, "last: %s %d%s", CLUBS[s->club % NUM_CLUBS], lastResult, USE_YARDS ? "y" : "m");
      else snprintf(buf, sizeof buf, "click at the ball");
      ui.small();
      ui.center(42, buf);
      snprintf(buf, sizeof buf, "total %u   hold=menu", round_.totalStrokes());
      drawFooter(buf);
      break;
    }

    case Scr::Mark:
      drawHeader(markFor == MarkFor::Start ? "Marking shot" : "Marking ball");
      ui.medium();
      ui.center(18, "Hold still");
      ui.small();
      snprintf(buf, sizeof buf, gps.hasFix() ? "%u sats  +/-%.1fm" : "waiting for fix...", gps.fix().siv, gps.fix().hacc_mm / 1000.0f);
      ui.center(40, buf);
      ui.progress(gps.markProgress());
      break;

    case Scr::Flight: {
      const Shot* s = round_.last();
      snprintf(buf, sizeof buf, "H%u %s", round_.h.currentHole, s ? CLUBS[s->club % NUM_CLUBS] : "");
      drawHeader(buf);
      int d = -1;
      if (s && s->start.valid && gps.hasFix())
        d = (int)lround(toDisplayUnits(distanceMeters(s->start.lat_e7, s->start.lon_e7, gps.fix().lat_e7, gps.fix().lon_e7)));
      drawBigDistance(d, 14);
      drawFooter("click at your ball");
      break;
    }

    case Scr::Result: {
      const Shot* s = round_.last();
      drawHeader(s ? CLUBS[s->club % NUM_CLUBS] : "");
      drawBigDistance(lastResult, 14);
      drawFooter(lastResult < 0 ? "saved (no GPS)" : "shot saved");
      break;
    }

    case Scr::Holes:
      drawHeader("Go to hole");
      snprintf(buf, sizeof buf, "%u", holeSel);
      ui.bigText((Ui::W - Ui::bigWidth(buf)) / 2, 14, buf);
      snprintf(buf, sizeof buf, "%u strokes so far", round_.strokesOnHole(holeSel));
      drawFooter(buf);
      break;

    case Scr::Confirm:
      ui.small();
      ui.center(0, confirmTitle);
      ui.hline(9);
      ui.small();
      ui.center(16, confirmLine);
      ui.medium();
      if (confirmSel == 0) { ui.fill(10, 34, 48, 18); ui.text(18, 35, "No", true); ui.text(80, 35, "Yes"); }
      else { ui.fill(70, 34, 48, 18); ui.text(18, 35, "No"); ui.text(80, 35, "Yes", true); }
      break;

    case Scr::Score: {
      drawHeader("Scorecard");
      ui.small();
      unsigned out = 0, in = 0;
      for (uint8_t h = 1; h <= NUM_HOLES; h++) {
        uint8_t n = round_.strokesOnHole(h);
        (h <= 9 ? out : in) += n;
        int col = (h - 1) % 9, x = 2 + col * 14;
        int y = h <= 9 ? 12 : 32;
        snprintf(buf, sizeof buf, "%u", h);
        ui.text(x, y, buf);
        if (n) snprintf(buf, sizeof buf, "%u", n); else strcpy(buf, "-");
        if (h == round_.h.currentHole) ui.fill(x - 1, y + 8, 12, 9);
        ui.text(x, y + 9, buf, h == round_.h.currentHole);
      }
      snprintf(buf, sizeof buf, "Out %u  In %u  Tot %u", out, in, out + in);
      ui.center(55, buf);
      break;
    }

    case Scr::GpsInfo: {
      drawHeader("GPS status");
      const Gps::Fix& f = gps.fix();
      ui.small();
      if (!gps.present()) { ui.center(24, "GPS not detected"); ui.center(34, "check Qwiic cable"); break; }
      snprintf(buf, sizeof buf, "fix %u  sats %u  %s", f.fixType, f.siv, gps.hasFix() ? "OK" : "--");
      ui.text(0, 13, buf);
      snprintf(buf, sizeof buf, "acc +/- %.1f m", f.hacc_mm / 1000.0f);
      ui.text(0, 23, buf);
      snprintf(buf, sizeof buf, "lat %.6f", f.lat_e7 / 1e7);
      ui.text(0, 33, buf);
      snprintf(buf, sizeof buf, "lon %.6f", f.lon_e7 / 1e7);
      ui.text(0, 43, buf);
      ui.center(56, "click to close");
      break;
    }
  }
  ui.show();
}

void updateLed() {
  switch (scr) {
    case Scr::Club:   gps.hasFix() ? input.setColor(0, 40, 0) : input.setColor(60, 25, 0); break;
    case Scr::Flight: gps.hasFix() ? input.setColor(0, 0, 60) : input.setColor(60, 25, 0); break;
    case Scr::Mark:   input.setColor(40, 40, 40); break;
    case Scr::Result: input.setColor(0, 90, 0); break;
    case Scr::Home:   input.setColor(5, 5, 5); break;
    default:          input.setColor(25, 0, 30); break;
  }
}

// ---------------------------------------------------------------------------
// USB serial commands
// ---------------------------------------------------------------------------
void listRounds() {
  File dir = LittleFS.open("/rounds");
  Serial.println("id\tshots\tstatus\tstart_unix");
  for (File f = dir.openNextFile(); f; f = dir.openNextFile()) {
    String n = f.name();
    int slash = n.lastIndexOf('/');
    if (slash >= 0) n = n.substring(slash + 1);
    if (!n.endsWith(".bin")) continue;
    uint32_t id = n.toInt();
    if (storage::load(id, scratch_))
      Serial.printf("%lu\t%u\t%s\t%lu\n", (unsigned long)id, scratch_.h.shotCount,
                    scratch_.h.finished ? "done" : "active", (unsigned long)scratch_.h.startUnix);
  }
}

void serialPoll() {
  static String line;
  while (Serial.available()) {
    char c = Serial.read();
    if (c != '\n' && c != '\r') { if (line.length() < 64) line += c; continue; }
    line.trim();
    if (!line.length()) continue;
    String cmd = line, arg;
    int sp = line.indexOf(' ');
    if (sp > 0) { cmd = line.substring(0, sp); arg = line.substring(sp + 1); arg.trim(); }
    uint32_t id = arg.toInt();
    if (cmd == "help") {
      Serial.println("ls            list rounds");
      Serial.println("geojson <id>  export round as GeoJSON (paste into geojson.io)");
      Serial.println("csv <id>      export round as CSV");
      Serial.println("rm <id>       delete a round");
      Serial.println("gps           current fix");
    } else if (cmd == "ls") {
      listRounds();
    } else if ((cmd == "geojson" || cmd == "csv" || cmd == "rm") && id == 0) {
      Serial.println("usage: <cmd> <id>   (see ls)");
    } else if (cmd == "geojson" || cmd == "csv") {
      const Round* r = (round_.h.id == id) ? &round_ : (storage::load(id, scratch_) ? &scratch_ : nullptr);
      if (!r) Serial.println("no such round");
      else if (cmd == "geojson") storage::exportGeoJSON(*r, Serial);
      else storage::exportCSV(*r, Serial);
    } else if (cmd == "rm") {
      if (round_.h.id == id && round_.active()) Serial.println("that round is in progress; end it first");
      else Serial.println(storage::removeRound(id) ? "deleted" : "no such round");
    } else if (cmd == "gps") {
      const Gps::Fix& f = gps.fix();
      Serial.printf("present=%d fix=%u ok=%d siv=%u lat=%.7f lon=%.7f acc=%.2fm unix=%lu\n", gps.present(), f.fixType,
                    gps.hasFix(), f.siv, f.lat_e7 / 1e7, f.lon_e7 / 1e7, f.hacc_mm / 1000.0f, (unsigned long)f.unix);
    } else {
      Serial.println("unknown command, try help");
    }
    line = "";
  }
}

// ---------------------------------------------------------------------------
// setup / loop
// ---------------------------------------------------------------------------
void setup() {
  // Power the Qwiic rail (it may still be held low from the last power-off).
  gpio_hold_dis((gpio_num_t)PIN_QWIIC_EN);
  gpio_deep_sleep_hold_dis();
  pinMode(PIN_QWIIC_EN, OUTPUT);
  digitalWrite(PIN_QWIIC_EN, HIGH);
  delay(150);

  Serial.begin(115200);
  Wire.begin(PIN_SDA, PIN_SCL);
  Wire.setClock(I2C_HZ);

  ui.begin(Wire);
  ui.clear(); ui.medium(); ui.center(24, "Shot Tracker"); ui.show();

  input.begin(Wire);
  fuelOk = fuel.begin(Wire);
  // By default the gauge hibernates whenever |charge rate| < ~27 %/hr, which is
  // nearly always on this load, and then only samples every 45 s.
  if (fuelOk) fuel.disableHibernate();
  bool fsOk = storage::begin();
  bool gpsOk = gps.begin(Wire);

  Serial.printf("oled=%d twist=%d gps=%d fuel=%d fs=%d\n", ui.present(), input.present(), gpsOk, fuelOk, fsOk);

  uint32_t cur = storage::currentRoundId();
  if (cur && storage::load(cur, round_) && round_.active()) {
    const Shot* s = round_.last();
    dialSel = s ? (s->flags & SHOT_PUTT ? putterIndex() : s->club) : 0;
    go(roundHome());
    showToast("Round resumed", 2500);
  } else {
    round_.reset();
    openHome();
  }
  if (!input.present()) showToast("Twist not found!", 5000);
  else if (!gpsOk) showToast("GPS not found!", 5000);
}

// The gauge's charge rate alone lags plug/unplug by minutes and reads ~0 when
// plugged in near full, so watch the cell voltage for the step that USB power
// causes, and only use the rate once it has had time to settle.
void updateCharging(uint32_t now, float volts, float rate) {
  static float baseline = 0;
  static uint32_t lastStep = 0;
  static bool stepSeen = false;
  if (baseline == 0) baseline = volts;
  float dv = volts - baseline;
  if (dv > CHG_STEP_V || dv < -CHG_STEP_V) {
    charging = dv > 0;
    lastStep = now;
    stepSeen = true;
    baseline = volts;
  } else {
    baseline += (volts - baseline) * 0.1f;  // follow slow drift (charging, discharge)
    if (!stepSeen || now - lastStep > CHG_SETTLE_MS) {
      if (rate > CHG_RATE_ON) charging = true;
      else if (rate < CHG_RATE_OFF) charging = false;
    }
  }
}

void loop() {
  static uint32_t lastRender = 0, lastFuel = 0;
  uint32_t now = millis();

  gps.poll();
  handle(input.poll());
  serialPoll();

  if (scr == Scr::Mark && gps.markDone()) {
    GeoPoint p;
    if (gps.finishMark(p)) applyMark(p);
    else openMarkFailed();
  }
  if (scr == Scr::Result && now - resultAt > RESULT_SHOW_MS) go(Scr::Club);

  if (fuelOk && (now - lastFuel >= FUEL_POLL_MS || lastFuel == 0)) {
    lastFuel = now;
    batteryPct = constrain((int)lround(fuel.getSOC()), 0, 100);
    updateCharging(now, fuel.getVoltage(), fuel.getChangeRate());
  }

  if (dirty || now - lastRender >= UI_REFRESH_MS) {
    render();
    updateLed();
    dirty = false;
    lastRender = now;
  }
}
