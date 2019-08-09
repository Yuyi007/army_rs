#include <syslog.h>
#include <lua.h>
#include <lauxlib.h>

static int lua_syslog(lua_State *L) 
{
  size_t sz = 0;
  const char * msg = (const char *)luaL_checklstring(L,1, &sz);
  int t = (int) luaL_checkinteger(L, 2);
  syslog (t, msg);
  return 0;
}


//log to local5 by default
static int lua_openlog(lua_State *L)
{
	size_t sz = 0;
	const char * pszAppName = (const char *)luaL_checklstring(L,1, &sz);
	int option = LOG_PID | LOG_CONS;
	openlog(pszAppName, option, LOG_LOCAL5);
}

static int lua_closelog()
{
	closelog ();
}
 
int
luaopen_syslog(lua_State *L) {
  luaL_checkversion(L);
  luaL_Reg l[] = {
  				{ "syslog", lua_syslog },
          { "openlog", lua_openlog },
          { "closelog", lua_closelog },
          { NULL, NULL}
  };
  luaL_newlib(L,l);
  return 1;
}