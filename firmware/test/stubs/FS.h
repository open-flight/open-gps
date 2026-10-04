#pragma once
#include "Arduino.h"
#include <memory>
#include <vector>
struct MemFS { std::map<std::string,std::string> files; };
extern MemFS g_fs;
class File { public: std::string path; std::string data; size_t pos=0; bool w=false, open_=false, isDir=false; std::vector<std::string> kids; size_t ki=0;
  operator bool() const { return open_; }
  size_t write(const uint8_t* b,size_t n){ data.append((const char*)b,n); return n; }
  size_t read(uint8_t* b,size_t n){ size_t c=std::min(n,data.size()-pos); memcpy(b,data.data()+pos,c); pos+=c; return c; }
  void print(uint32_t v){ data+=std::to_string(v); }
  long parseInt(){ return atol(data.c_str()); }
  void close(){ if(w&&open_) g_fs.files[path]=data; open_=false; }
  const char* name(){ return path.c_str(); }
  File openNextFile(){ File f; if(ki<kids.size()){ f.path=kids[ki++]; f.open_=true; } return f; } };
#include <vector>
