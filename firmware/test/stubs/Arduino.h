#pragma once
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <cstdarg>
#include <cmath>
#include <string>
#include <map>
#include <algorithm>
#include <cctype>
using std::min; using std::max;
typedef bool boolean;
extern uint32_t g_millis;
inline uint32_t millis(){ return g_millis; }
inline void delay(uint32_t ms){ g_millis += ms; }
#define constrain(x,a,b) ((x)<(a)?(a):((x)>(b)?(b):(x)))
#define OUTPUT 1
#define HIGH 1
#define LOW 0
inline void pinMode(int,int){} inline void digitalWrite(int,int){}
inline size_t strlcpy(char* d,const char* s,size_t n){ size_t l=strlen(s); if(n){ size_t c=l<n-1?l:n-1; memcpy(d,s,c); d[c]=0;} return l; }
inline size_t strlcat(char* d,const char* s,size_t n){ size_t l=strlen(d); return l+strlcpy(d+l,s,n>l?n-l:0); }
class String { public: std::string s; String(){} String(const char* c):s(c){} String(const std::string& x):s(x){}
  String(uint32_t v):s(std::to_string(v)){} String(int v):s(std::to_string(v)){}
  const char* c_str() const { return s.c_str(); } size_t length() const { return s.size(); }
  bool endsWith(const char* e) const { size_t l=strlen(e); return s.size()>=l && s.compare(s.size()-l,l,e)==0; }
  int lastIndexOf(char c) const { auto p=s.rfind(c); return p==std::string::npos?-1:(int)p; }
  int indexOf(char c) const { auto p=s.find(c); return p==std::string::npos?-1:(int)p; }
  String substring(int a,int b=-1) const { return String(b<0?s.substr(a):s.substr(a,b-a)); }
  long toInt() const { return atol(s.c_str()); }
  void trim(){ while(!s.empty()&&isspace(s.back())) s.pop_back(); size_t i=0; while(i<s.size()&&isspace(s[i])) i++; s=s.substr(i); }
  String& operator+=(char c){ s+=c; return *this; }
  String operator+(const String& o) const { return String(s+o.s); }
  String operator+(const char* o) const { return String(s+o); }
  String operator+(uint32_t v) const { return String(s+std::to_string(v)); }
  bool operator==(const char* o) const { return s==o; }
  operator const char*() const { return s.c_str(); } };
inline String operator+(const char* a, const String& b){ return String(std::string(a)+b.s); }
class Print { public: std::string out;
  size_t printf(const char* f, ...) { char b[1024]; va_list a; va_start(a,f); int n=vsnprintf(b,sizeof b,f,a); va_end(a); out+=b; return n; }
  void print(const char* s){ out+=s; } void print(char c){ out+=c; } void print(uint32_t v){ out+=std::to_string(v); }
  void println(const char* s=""){ out+=s; out+="\n"; } };
class Stream : public Print { public: std::string in; int available(){ return (int)in.size(); } int read(){ int c=in[0]; in.erase(0,1); return c; }
  void begin(int){} };
extern Stream Serial;
