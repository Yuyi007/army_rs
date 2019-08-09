
//#include <stdlib.h>
//#include <string.h> /* memset */
//#include <unistd.h> /* close */
//#include <time.h>

//#include "lua.h"
//#include "lauxlib.h"
//#include "skynet.h"
//#include "skynet_env.h"

#include "skynet_env.h"
#include "skynet_log.h"
#include "skynet_timer.h"
#include "skynet.h"
#include "skynet_socket.h"

#include <lua.h>
#include <lauxlib.h>

#include <stdio.h>
#include <stdint.h>

#include <string.h>
#include <time.h>

static FILE* f;

const static char debug_name[] = "[debug]";
const static char info_name[] = "[info]";
const static char error_name[] = "[error]";
const static char fatal_name[] = "[fatal]";

const char* _get_level_name(level)
{
  if (level == 0)
    return debug_name;
  else if (level == 1)
    return info_name;
  else if (level == 2)
    return error_name;
  else
    return fatal_name;
}

int
_skynet_log_open() {
  const char * logpath = skynet_getenv("server_logpath");
  if (logpath == NULL)
    return NULL;
  size_t sz = strlen(logpath);
  char tmp[sz + 16];

  time_t t;
  t = time(NULL);
  struct tm* pTm = gmtime(&t);

  char month[4];
  char day[4];
  memset(month, 0, 4);
  memset(day, 0, 4);
  int mon = pTm->tm_mon + 1;
  if (mon < 10)
  {
    sprintf(month, "0%d", mon);
  }
  else
  {
    sprintf(month, "%d", mon);
  }

  if (pTm->tm_mday < 10)
  {
    sprintf(day, "0%d", pTm->tm_mday);
  }
  else
  {
    sprintf(day, "%d", pTm->tm_mday);
  }

  sprintf(tmp, "%s%d%s%s.log", logpath, pTm->tm_year + 1900, month, day);
  f = fopen(tmp, "ab");
  if (f) {
    uint32_t starttime = skynet_starttime();
    uint32_t currenttime = skynet_now();
    time_t ti = starttime + currenttime/100;
    //skynet_error(ctx, "Open log file %s", tmp);
    fprintf(f, "open time: %u %s", currenttime, ctime(&ti));
    fflush(f);
  } else {
    printf("Open log file %s fail", tmp);
    //skynet_error(ctx, "Open log file %s fail", tmp);
  }
  return 1;
}

void
_skynet_log_close() {
  fprintf(f, "close time: %u\n", skynet_now());
  fclose(f);
}

static void
_log_blob(void * buffer, size_t sz) {
  size_t i;
  uint8_t * buf = buffer;
  for (i=0;i!=sz;i++) {
    fprintf(f, "%c", buf[i]);
  }
}


static void
_log_socket(struct skynet_socket_message * message, size_t sz) {
  fprintf(f, "[socket] %d %d %d ", message->type, message->id, message->ud);

  if (message->buffer == NULL) {
    const char *buffer = (const char *)(message + 1);
    sz -= sizeof(*message);
    const char * eol = memchr(buffer, '\0', sz);
    if (eol) {
      sz = eol - buffer;
    }
    fprintf(f, "[%*s]", (int)sz, (const char *)buffer);
  } else {
    sz = message->ud;
    _log_blob(message->buffer, sz);
  }
  fprintf(f, "\n");
  fflush(f);
}

void 
_skynet_log_output(const char* src_name, int level, void * buffer, size_t sz) {
  if (level == PTYPE_SOCKET) {
    _log_socket(buffer, sz);
  } else {
    uint32_t ti = skynet_now();
    fprintf(f, ":%s %s %u ", _get_level_name(level), src_name, ti);
    _log_blob(buffer, sz);
    fprintf(f,"\n");
    fflush(f);
  }
}

static const char *
get_lua_string(lua_State *L, int index) {
    const char * lua_string = lua_tostring(L, index);
    if (lua_string == NULL) {
        luaL_error(L, "dest address type (%s) must be a string or number.", lua_typename(L, lua_type(L,index)));
    }
    return lua_string;
}

static int
lopen(lua_State *L){
    _skynet_log_open();
    return 1;
}

static int
llog(lua_State *L){
    const char * src_name = NULL;
    if (src_name == 0) {
        src_name = get_lua_string(L, 1);
    }

    int type = luaL_checkinteger(L, 2);


    size_t len = 0;
    void * msg = (void *)lua_tolstring(L,3,&len);

    _skynet_log_output(src_name, type, msg, len);
    return 1;
}

static int
lclose(lua_State *L){
    _skynet_log_close();
    return 1;
}

int
luaopen_llogger(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        { "open" , lopen },
        { "log", llog },
        { "close", lclose },
        { NULL, NULL },
    };

    luaL_newlib(L,l);

    return 1;
}