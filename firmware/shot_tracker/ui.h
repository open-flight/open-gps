#pragma once
#include <Arduino.h>
#include <Wire.h>
#include <SparkFun_Qwiic_OLED.h>
#include <res/qw_fnt_5x7.h>
#include <res/qw_fnt_8x16.h>

// Thin layer over the 1.3" 128x64 Qwiic OLED.
// Fonts: 5x7 (8 px rows, 21 chars), 8x16 (16 chars). Big numbers use bigText() below.
class Ui {
 public:
  static constexpr int W = 128, H = 64;

  bool begin(TwoWire& wire) { ok_ = oled_.begin(wire); return ok_; }
  bool present() const { return ok_; }
  void power(bool on) { if (ok_) oled_.displayPower(on); }

  void clear() { if (ok_) oled_.erase(); }
  void show() { if (ok_) oled_.display(); }

  void small() { oled_.setFont(QW_FONT_5X7); }
  void medium() { oled_.setFont(QW_FONT_8X16); }

  void text(int x, int y, const char* s, bool inverted = false) {
    if (ok_) oled_.text(x, y, s, inverted ? COLOR_BLACK : COLOR_WHITE);
  }
  int width(const char* s) { return ok_ ? (int)oled_.getStringWidth(s) : 0; }
  void center(int y, const char* s) { text((W - width(s)) / 2, y, s); }
  void right(int y, const char* s) { text(W - width(s), y, s); }
  void hline(int y) { if (ok_) oled_.line(0, y, W - 1, y); }
  void fill(int x, int y, int w, int h, bool white = true) { if (ok_) oled_.rectangleFill(x, y, w, h, white ? COLOR_WHITE : COLOR_BLACK); }
  void frame(int x, int y, int w, int h) { if (ok_) oled_.rectangle(x, y, w, h); }

  // Bold block digits for distances and hole numbers. The library's LARGENUM font is
  // 12x48 px and looks stretched, so these are drawn as filled 7-segment bars instead.
  // Handles '0'-'9' and '-'; anything else leaves a blank cell.
  static constexpr int DIG_W = 20, DIG_H = 35, DIG_T = 5, DIG_GAP = 4;
  static int bigWidth(const char* s) { int n = strlen(s); return n ? n * DIG_W + (n - 1) * DIG_GAP : 0; }
  void bigText(int x, int y, const char* s) {
    static const uint8_t SEG[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};  // bits: gfedcba
    const int w = DIG_W, h = DIG_H, t = DIG_T, mid = (h - t) / 2;
    for (; *s; s++, x += DIG_W + DIG_GAP) {
      uint8_t m = *s == '-' ? 0x40 : (*s >= '0' && *s <= '9') ? SEG[*s - '0'] : 0;
      if (m & 0x01) fill(x, y, w, t);                      // a: top
      if (m & 0x02) fill(x + w - t, y, t, mid + t);        // b: top right
      if (m & 0x04) fill(x + w - t, y + mid, t, h - mid);  // c: bottom right
      if (m & 0x08) fill(x, y + h - t, w, t);              // d: bottom
      if (m & 0x10) fill(x, y + mid, t, h - mid);          // e: bottom left
      if (m & 0x20) fill(x, y, t, mid + t);                // f: top left
      if (m & 0x40) fill(x, y + mid, w, t);                // g: middle
    }
  }

  // Pixel art: one string per row, '#' = lit pixel, anything else = unlit.
  void art(int x, int y, const char* const* rows, int h) {
    if (!ok_) return;
    for (int r = 0; r < h; r++)
      for (int c = 0; rows[r][c]; c++)
        if (rows[r][c] == '#') oled_.pixel(x + c, y + r, COLOR_WHITE);
  }

  // Battery gauge, 12x7 (10x7 body + nub). pct < 0 draws an empty outline.
  void battery(int x, int y, int pct) {
    frame(x, y, 10, 7);
    fill(x + 10, y + 2, 2, 3);
    if (pct > 0) fill(x + 2, y + 2, max(1, min(6, (pct * 6 + 50) / 100)), 3);
  }

  // Progress bar across the bottom.
  void progress(float f) {
    frame(8, 56, W - 16, 6);
    fill(9, 57, (int)((W - 18) * constrain(f, 0.0f, 1.0f)), 4);
  }

  // Scrolling list in the 5x7 font below a title. Returns nothing; caller handles input.
  // Optional titleIcon (pixel art, 8 px tall max) is drawn at the right of the title row.
  void list(const char* title, const char* const* items, int count, int sel,
            const char* const* titleIcon = nullptr, int iconW = 0, int iconH = 0) {
    small();
    text(0, 0, title);
    if (titleIcon) art(W - iconW, 0, titleIcon, iconH);
    hline(9);
    const int rows = 6, rowH = 9, top = 11;
    int first = constrain(sel - rows / 2, 0, max(0, count - rows));
    for (int i = 0; i < rows && first + i < count; i++) {
      int y = top + i * rowH;
      bool on = first + i == sel;
      if (on) fill(0, y - 1, W, rowH);
      text(3, y, items[first + i], on);
    }
    if (first > 0) text(W - 6, 11, "^");
    if (first + rows < count) text(W - 6, 56, "v");
  }

 private:
  Qwiic1in3OLED oled_;
  bool ok_ = false;
};
