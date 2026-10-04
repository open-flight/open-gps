#pragma once
#include "Wire.h"
#define COLOR_WHITE 1
#define COLOR_BLACK 0
struct QwiicFont { int w; }; extern QwiicFont F5,F8,FL;
#define QW_FONT_5X7 F5
#define QW_FONT_8X16 F8
#define QW_FONT_LARGENUM FL
extern std::string g_screen;
class Qwiic1in3OLED { QwiicFont* f=&F5; public: bool begin(TwoWire&){ return true; } void displayPower(bool){} void erase(){ g_screen.clear(); } void display(){}
  void setFont(QwiicFont& x){ f=&x; } unsigned getStringWidth(const char* s){ return strlen(s)*(f->w+ (f->w==5?1:0)); }
  void text(uint8_t x,uint8_t y,const char* s,uint8_t c){ char b[160]; snprintf(b,sizeof b,"[%d,%d%s]%s\n",x,y,c?"":" INV",s); g_screen+=b;
    if (x + getStringWidth(s) > 128) { g_screen += "!!OVERFLOW!!\n"; } }
  void pixel(int x,int y,uint8_t){ if (x < 0 || x >= 128 || y < 0 || y >= 64) g_screen += "!!OVERFLOW!!\n"; }
  void line(uint8_t,uint8_t,uint8_t,uint8_t){} void rectangle(uint8_t,uint8_t,uint8_t,uint8_t){} void rectangleFill(uint8_t x,uint8_t y,uint8_t w,uint8_t h,uint8_t){ if (x + w > 128 || y + h > 64) g_screen += "!!OVERFLOW!!\n"; } };
