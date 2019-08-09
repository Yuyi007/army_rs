#ifndef LUA_NAVIGATION
#define LUA_NAVIGATION
#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"
  
extern "C"
{
  int luaopen_navigator(lua_State *L);
}

#endif