#include "Arduino.h"
#include "Wire.h"
#include "LittleFS.h"
#include "SparkFun_Qwiic_OLED.h"
uint32_t g_millis = 1000; Stream Serial; TwoWire Wire; MemFS g_fs; LittleFSC LittleFS; bool g_slept=false;
int16_t g_twistDiff=0; bool g_twistDown=false; double g_lat=47.600000, g_lon=-122.300000; bool g_fix=true; uint32_t g_lastPvt=0;
QwiicFont F5{5},F8{8},FL{12}; std::string g_screen;
#include "../shot_tracker/app.cpp"

static const char* scrName(){ const char* n[]={"Home","Club","Mark","Flight","Result","Menu","Holes","Confirm","Score","GpsInfo"}; return n[(int)scr]; }
void step(uint32_t ms){ for(uint32_t t=0;t<ms;t+=5){ g_millis+=5; loop(); } }
void turn(int n){ g_twistDiff+=n; step(40); }
void click(){ g_twistDown=true; step(120); g_twistDown=false; step(60); }
void hold(){ g_twistDown=true; step(900); g_twistDown=false; step(60); }
void walkYards(double yd){ g_lat += yd*0.9144/111194.9; step(100); }
int fails=0;
void expect(bool c,const char* what){ printf("  %s %s\n", c?"ok  ":"FAIL", what); if(!c) fails++; }
void screen(){ step(300); printf("---- %s ----\n%s", scrName(), g_screen.c_str()); }
int menuIndex(const char* label){ for(int i=0;i<menuCount;i++) if(!strcmp(menu[i].label,label)) return i; return -1; }
void pick(const char* label){ int i=menuIndex(label); if(i<0){ printf("  FAIL no menu item %s\n",label); fails++; return;} turn(i-menuSel); click(); }

int main(){
  setup(); step(200);
  expect(scr==Scr::Home,"boots to home");
  pick("New round");
  expect(scr==Scr::Club && round_.h.currentHole==1,"new round, hole 1, club select");
  screen();
  // Drive: 250 yds
  click(); expect(scr==Scr::Mark,"marking start");
  step(2600); expect(scr==Scr::Flight,"in flight after mark");
  walkYards(125); screen();
  walkYards(125); click(); step(2600);
  expect(scr==Scr::Result,"result shown"); printf("  drive = %d yds\n", lastResult);
  expect(abs(lastResult-250)<=1,"drive measured ~250");
  screen();
  step(4500); expect(scr==Scr::Club,"back to club select after result");
  // 7 iron 150
  turn(7); expect(dialSel==7,"dial to 7 Iron");
  click(); step(2600); walkYards(150); click(); step(2600);
  expect(abs(lastResult-150)<=1,"7i measured ~150");
  click(); // dismiss result
  // two putts
  turn(putterIndex()-dialSel); expect(isPutter(dialSel),"dial to putter");
  click(); step(2600); expect(scr==Scr::Club && round_.h.shotCount==3,"putt recorded as single point");
  click(); step(2600); expect(round_.h.shotCount==4 && dialSel==putterIndex(),"second putt, dial stays on putter");
  turn(1); expect(dialSel==DIAL_HOLE_OUT,"one click past putter = Hole out");
  screen();
  click(); expect(round_.h.currentHole==2 && round_.strokesOnHole(1)==4,"holed out: H1 = 4 strokes, now H2");
  // Hole 2: start a drive then cancel it from the menu
  turn(-(int)dialSel); click(); step(2600); expect(round_.inFlight(),"H2 drive in flight");
  hold(); expect(scr==Scr::Menu,"long press opens menu");
  screen();
  pick("Cancel this shot"); expect(scr==Scr::Confirm && confirmSel==0,"confirm defaults to No");
  turn(1); click(); expect(round_.h.shotCount==4 && !round_.inFlight() && scr==Scr::Club,"shot cancelled");
  // Reset mid-flight -> resume
  click(); step(2600); walkYards(60);
  expect(scr==Scr::Flight,"in flight before reset");
  round_.reset(); scr=Scr::Home; setup(); step(300);
  expect(scr==Scr::Flight && round_.h.shotCount==5 && round_.h.currentHole==2,"RESET mid-shot resumes in flight");
  walkYards(40); click(); step(2600); expect(abs(lastResult-100)<=1,"landing after resume measures from original start (~100)");
  click();
  // No GPS fix -> prompt -> save without GPS
  g_fix=false; step(3100);
  click(); step(2600); expect(scr==Scr::Menu && !strcmp(menuTitle,"NO GPS FIX"),"no-fix prompt");
  screen();
  pick("Save without GPS"); expect(scr==Scr::Flight && !round_.last()->start.valid,"shot saved without GPS, in flight");
  g_fix=true; step(1000); click(); step(2600); expect(scr==Scr::Result && lastResult<0,"distance unknown when start had no fix");
  click();
  // Undo last shot
  uint16_t before=round_.h.shotCount;
  hold(); pick("Undo last shot"); turn(1); click(); expect(round_.h.shotCount==before-1,"undo last shot");
  // Go to hole 18, putt, hole out, finish
  hold(); pick("Go to hole..."); expect(scr==Scr::Holes,"hole picker");
  turn(16); screen(); click(); expect(round_.h.currentHole==18,"jumped to hole 18");
  turn(putterIndex()-dialSel); click(); step(2600); turn(1); click();
  expect(scr==Scr::Confirm,"hole 18 hole-out asks to finish");
  screen();
  turn(1); click(); expect(scr==Scr::Home && !round_.active(),"round finished, back home");
  expect(storage::currentRoundId()==0,"no current round pointer after finish");
  screen();
  pick("New round"); click(); step(2600); walkYards(222); screen(); hold(); pick("Scorecard"); screen(); click(); pick("GPS status"); screen(); click();
  pick("End round"); screen(); turn(1); click(); expect(scr==Scr::Home,"second round ended");
  // delete a saved round from the device
  expect(countRounds()==2,"two saved rounds");
  pick("Saved rounds (2)"); screen(); expect(scr==Scr::Menu && menu[1].arg==2,"rounds list, newest first");
  turn(1); click(); expect(scr==Scr::Confirm && confirmSel==0,"delete asks to confirm, defaults to No");
  screen(); click(); expect(scr==Scr::Menu && countRounds()==2,"No keeps the round");
  click(); turn(1); click(); expect(countRounds()==1 && !LittleFS.exists("/rounds/2.bin"),"round 2 deleted");
  expect(scr==Scr::Menu && menuCount==2 && menu[1].arg==1,"list refreshed after delete");
  hold(); expect(scr==Scr::Home && !strcmp(menu[0].label,"New round"),"long press back to a rebuilt home menu");
  // Scorecard of a new round, then export the first round
  Serial.in="ls\ngeojson 1\n"; step(50);
  printf("---- serial ----\n%s", Serial.out.c_str());
  size_t p=Serial.out.find("{\"type\""); std::string js=Serial.out.substr(p); js=js.substr(0,js.find('\n'));
  FILE* f=fopen("round1.geojson","w"); fputs(js.c_str(),f); fclose(f);
  Serial.out.clear(); Serial.in="csv 1\n"; step(50); printf("%s",Serial.out.c_str());
  // power off
  try { pick("Power off"); } catch(int) { expect(g_slept,"power off enters deep sleep"); }
  printf("\n%d failures\n", fails);
  return fails;
}
