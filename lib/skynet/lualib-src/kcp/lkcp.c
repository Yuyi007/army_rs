/**
 *
 * Copyright (C) 2015 by David Lin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALING IN
 * THE SOFTWARE.
 *
 */

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>

#include "ikcp.h"

// /*
// ** set functions from list 'l' into table at top - 'nup'; each
// ** function gets the 'nup' elements at the top as upvalues.
// ** Returns with only the table at the stack.
// */
// static void luaL_setfuncs (lua_State *L, const luaL_Reg *l, int nup) {
//   luaL_checkstack(L, nup, "too many upvalues");
//   for (; l && l->name; l++) {  /* fill the table with given functions */
//     int i;
//     for (i = 0; i < nup; i++)  /* copy upvalues to the top */
//       lua_pushvalue(L, -nup);
//     lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
//     lua_setfield(L, -(nup + 2), l->name);
//   }
//   lua_pop(L, nup);  /* remove upvalues */
// }

#define RECV_BUFFER_LEN 4*1024//*1024

/*#define check_kcp(L, idx)\
	*(ikcpcb**)luaL_checkudata(L, idx, "kcp_meta")*/

#define check_buf(L, idx)\
	(char*)luaL_checkudata(L, idx, "recv_buffer")

struct Callback {
    uint64_t handle;
    lua_State* L;
};

static ikcpcb* check_kcp(lua_State* L, int idx){
    ikcpcb* res = *(ikcpcb**)luaL_checkudata(L, idx, "kcp_meta");

    struct Callback* c = (struct Callback*)res->user;
    c -> L = L;

    return res;
}

static int kcp_output_callback(const char *buf, int len, ikcpcb *kcp, void *arg) {
    struct Callback* c = (struct Callback*)arg;
    lua_State* L = c -> L;
    uint64_t handle = c -> handle;

    lua_rawgeti(L, LUA_REGISTRYINDEX, handle);
    lua_pushlstring(L, buf, len);
    lua_call(L, 1, 0);

    return 0;
}

static int kcp_gc(lua_State* L) {
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        return 0;
	}
    if (kcp->user != NULL) {
        struct Callback* c = (struct Callback*)kcp -> user;
        uint64_t handle = c -> handle;
        luaL_unref(L, LUA_REGISTRYINDEX, handle);
        free(c);
        kcp->user = NULL;
    }
    ikcp_release(kcp);
    kcp = NULL;

    //printf("kcp object release!");
    return 0;
}

static int lkcp_create(lua_State* L){
    uint64_t handle = luaL_ref(L, LUA_REGISTRYINDEX);
    int32_t conv = luaL_checkinteger(L, 1);

    struct Callback* c = malloc(sizeof(struct Callback));
    memset(c, 0, sizeof(struct Callback));
    c -> handle = handle;
    c -> L = L;

    ikcpcb* kcp = ikcp_create(conv, (void*)c);
    if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: fail to create kcp");
        return 2;
    }

    kcp->output = kcp_output_callback;

    *(ikcpcb**)lua_newuserdata(L, sizeof(void*)) = kcp;
    luaL_getmetatable(L, "kcp_meta");
    lua_setmetatable(L, -2);
    return 1;
}

static int lkcp_recv(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
    lua_getfield(L, LUA_REGISTRYINDEX, "kcp_lua_recv_buffer");
    char* buf = check_buf(L, -1);
    lua_pop(L, 1);

    int32_t hr = ikcp_recv(kcp, buf, RECV_BUFFER_LEN);
    if (hr <= 0) {
        lua_pushinteger(L, hr);
        return 1;
    }

    lua_pushinteger(L, hr);
	lua_pushlstring(L, (const char *)buf, hr);

    return 2;
}

static int lkcp_send(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
	size_t size;
	const char *data = luaL_checklstring(L, 2, &size);
    int32_t hr = ikcp_send(kcp, data, size);

    lua_pushinteger(L, hr);
    return 1;
}

static int lkcp_update(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
    int32_t current = luaL_checkinteger(L, 2);
    ikcp_update(kcp, current);
    return 0;
}

static int lkcp_check(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
    int32_t current = luaL_checkinteger(L, 2);
    int32_t hr = ikcp_check(kcp, current);
    lua_pushinteger(L, hr);
    return 1;
}

static int lkcp_input(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
	size_t size;
	const char *data = luaL_checklstring(L, 2, &size);
    int32_t hr = ikcp_input(kcp, data, size);

    lua_pushinteger(L, hr);
    return 1;
}

static int lkcp_peeksize(lua_State* L){
    ikcpcb* kcp = check_kcp(L, 1);
    if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
    }
    int32_t hr = ikcp_peeksize(kcp);

    lua_pushinteger(L, hr);
    return 1;
}

static int lkcp_flush(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
    ikcp_flush(kcp);
    return 0;
}

static int lkcp_setmtu(lua_State* L){
    ikcpcb* kcp = check_kcp(L, 1);
    if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
    }
    int32_t mtu = luaL_checkinteger(L, 2);
    ikcp_setmtu(kcp, mtu);
    return 0;
}

static int lkcp_waitsnd(lua_State* L){
    ikcpcb* kcp = check_kcp(L, 1);
    if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
    }
    int32_t hr = ikcp_waitsnd(kcp);

    lua_pushinteger(L, hr);
    return 1;
}

static int lkcp_wndsize(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
    int32_t sndwnd = luaL_checkinteger(L, 2);
    int32_t rcvwnd = luaL_checkinteger(L, 3);
    ikcp_wndsize(kcp, sndwnd, rcvwnd);
    return 0;
}

static int lkcp_nodelay(lua_State* L){
	ikcpcb* kcp = check_kcp(L, 1);
	if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
	}
    int32_t nodelay = luaL_checkinteger(L, 2);
    int32_t interval = luaL_checkinteger(L, 3);
    int32_t resend = luaL_checkinteger(L, 4);
    int32_t nc = luaL_checkinteger(L, 5);
    int32_t hr = ikcp_nodelay(kcp, nodelay, interval, resend, nc);
    lua_pushinteger(L, hr);
    return 1;
}

static int lkcp_getconv(lua_State* L){
    ikcpcb* kcp = check_kcp(L, 1);
    if (kcp == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: kcp not args");
        return 2;
    }
    IUINT32 hr = ikcp_getconv(kcp);

    lua_pushnumber(L, hr);
    return 1;
}


static const struct luaL_Reg lkcp_methods [] = {
    { "recv" , lkcp_recv },
    { "send" , lkcp_send },
    { "update" , lkcp_update },
    { "check" , lkcp_check },
    { "input" , lkcp_input },
    { "peeksize" , lkcp_peeksize },
    { "flush" , lkcp_flush },
    { "setmtu" , lkcp_setmtu },
    { "waitsnd" , lkcp_waitsnd },
    { "wndsize" , lkcp_wndsize },
    { "nodelay" , lkcp_nodelay },
    { "getconv" , lkcp_getconv },
	{NULL, NULL},
};

static const struct luaL_Reg l_methods[] = {
    { "create" , lkcp_create },
    {NULL, NULL},
};

LUALIB_API int luaopen_lkcp(lua_State* L) {
    luaL_checkversion(L);

    luaL_newmetatable(L, "kcp_meta");

    lua_newtable(L);
    luaL_setfuncs(L, lkcp_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, kcp_gc);
    lua_setfield(L, -2, "__gc");

    luaL_newmetatable(L, "recv_buffer");

    char* global_recv_buffer = lua_newuserdata(L, sizeof(char)*RECV_BUFFER_LEN);
    memset(global_recv_buffer, 0, sizeof(char)*RECV_BUFFER_LEN);
    luaL_getmetatable(L, "recv_buffer");
    lua_setmetatable(L, -2);
    lua_setfield(L, LUA_REGISTRYINDEX, "kcp_lua_recv_buffer");

    // luaL_newlib(L, l_methods);
    // luaL_register(L, "lkcp", l_methods);
    luaL_setfuncs(L, l_methods, 0);

    return 1;
}

