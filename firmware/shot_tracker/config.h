#pragma once
#include <Arduino.h>

// ---------------------------------------------------------------------------
// Hardware (SparkFun Thing Plus ESP32-S3, from SparkFun's KiCad netlist)
// ---------------------------------------------------------------------------
constexpr int PIN_QWIIC_EN = 45;  // drives the RT9080 that powers the Qwiic rail (GPS, OLED, Twist)
constexpr int PIN_SDA = 8;
constexpr int PIN_SCL = 9;
constexpr uint32_t I2C_HZ = 400000;

// ---------------------------------------------------------------------------
// Round
// ---------------------------------------------------------------------------
constexpr uint8_t NUM_HOLES = 18;
constexpr uint16_t MAX_SHOTS = 250;  // per round; ~36 bytes each

// Club list shown on the dial. Order = dial order. Keep names <= 14 chars.
// The putter must be named exactly PUTTER_NAME (putts record one point, no landing).
#define PUTTER_NAME "Putter"
static const char* const CLUBS[] = {
    "Driver", "3 Wood", "5 Wood", "Hybrid", "4 Iron", "5 Iron", "6 Iron",
    "7 Iron", "8 Iron", "9 Iron", "PW",     "GW",     "SW",     "LW",
    PUTTER_NAME,
};
constexpr uint8_t NUM_CLUBS = sizeof(CLUBS) / sizeof(CLUBS[0]);
// The dial has one extra slot after the clubs: "Hole out" (finishes the hole).
constexpr uint8_t DIAL_HOLE_OUT = NUM_CLUBS;

// ---------------------------------------------------------------------------
// GPS
// ---------------------------------------------------------------------------
constexpr uint8_t GPS_NAV_HZ = 4;                 // solutions per second
constexpr uint32_t GPS_MARK_WINDOW_MS = 2500;     // average fixes for this long when marking a point
constexpr uint8_t GPS_MARK_MIN_SAMPLES = 3;       // below this the mark counts as failed
constexpr uint32_t GPS_MAX_GOOD_HACC_MM = 8000;   // fixes worse than this are ignored while marking

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------
constexpr bool USE_YARDS = true;             // false = metres
constexpr uint32_t LONG_PRESS_MS = 700;      // hold the dial this long to open the menu
constexpr uint32_t RESULT_SHOW_MS = 4000;    // how long the "152 yds" result stays up
constexpr uint32_t UI_REFRESH_MS = 250;
