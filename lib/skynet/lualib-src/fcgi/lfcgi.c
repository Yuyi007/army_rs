
#include "lua.h"
#include "lauxlib.h"

#include "fcgi_config.h"
#include "fcgiapp.h"
#include <stdlib.h>
#include <string.h> /* memset */
#include <unistd.h> /* close */

static  FCGX_Stream *in, *out, *err;
static  FCGX_ParamArray envp;

static int
_fcgi_accept(lua_State *L){
    int ret = FCGX_Accept(&in, &out, &err, &envp);
    lua_pushinteger(L, ret);
    return 1;
}

static int
_fcgi_getdata(lua_State *L){
    char *contentLength = FCGX_GetParam("CONTENT_LENGTH", envp);
    int len = 0;
    if (contentLength != NULL)
            len = strtol(contentLength, NULL, 10);
    if (len <= 0){
            FCGX_FPrintF(out, "No data from standard input.\n");
        }
    else{
        int i, ch;
        char *psz = (char*)malloc(len+1);
        if(!psz){
            FCGX_FPrintF(out, "Error: Not enough memory.\n");
            return 0;
        }

        memset(psz, 0, len+1);
        for (i = 0; i < len; i++) {
            if ((ch = FCGX_GetChar(in)) < 0) {
                FCGX_FPrintF(out, "Error: Not enough bytes received on standard input.\n");
                break;
            }

            psz[i] = (char)ch;
        }

        lua_pushstring(L, psz);
        if(psz) 
            free(psz);
        return 1;
    }

    return 0;
}

static int
_fcgi_response(lua_State *L){
    const char * str = luaL_checkstring(L,1);
    FCGX_FPrintF(out, str);
    return 1;
}

static int
_fcgi_finish(lua_State *L){
    FCGX_Finish();
    return 1;
}

static int
_fcgi_data_len(lua_State *L){
    const char * str = luaL_checkstring(L,1);
    int nLen = strlen(str)*sizeof(char);
    lua_pushinteger(L, nLen);
    return 1;
}

int
luaopen_lfcgi(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        { "accept" , _fcgi_accept },
        { "getdata", _fcgi_getdata },
        { "response", _fcgi_response },
        { "finish", _fcgi_finish },
        { "datalen", _fcgi_data_len},
        { NULL, NULL },
    };

    luaL_newlib(L,l);

    return 1;
}