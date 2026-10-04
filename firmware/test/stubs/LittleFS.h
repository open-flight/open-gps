#pragma once
#include "FS.h"
class LittleFSC { public:
  bool begin(bool){ return true; }
  bool exists(const String& p){ if(g_fs.files.count(p.s)) return true; for(auto&kv:g_fs.files) if(kv.first.rfind(p.s+"/",0)==0) return true; return p.s=="/rounds"; }
  bool mkdir(const char*){ return true; }
  File open(const String& p,const char* m="r"){ File f; f.path=p.s; f.w=m[0]=='w';
    if(f.w){ f.open_=true; return f; }
    if(g_fs.files.count(p.s)){ f.data=g_fs.files[p.s]; f.open_=true; return f; }
    if(p.s=="/rounds"){ f.open_=true; f.isDir=true; for(auto&kv:g_fs.files) if(kv.first.rfind("/rounds/",0)==0) f.kids.push_back(kv.first.substr(8)); }
    return f; }
  bool remove(const String& p){ return g_fs.files.erase(p.s)>0; }
  bool rename(const String& a,const String& b){ if(!g_fs.files.count(a.s)) return false; g_fs.files[b.s]=g_fs.files[a.s]; g_fs.files.erase(a.s); return true; } };
extern LittleFSC LittleFS;
