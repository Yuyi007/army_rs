//
//  lfixmath.c
//  slua
//
//  Created by wenjie on 12/18/15.
//  Copyright (c) 2015 wenjie. All rights reserved.
//

#include <stdio.h>

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
#include "fix16.h"
#ifdef __cplusplus
#include "fix16.hpp"
#endif
#include "fix16_trig_sin_lut.h"
#include "fixmath.h"
#include "fract32.h"
#include "int64.h"
#include "uint32.h"
#define null  0

#ifndef FM_LIBNAME
#define FM_LIBNAME  "fixmath"
#endif

static int lua_read_float(lua_State *L, int idx, float *ret){
    if (lua_isnumber(L, idx)) {
        *ret = (float)lua_tonumber(L, idx);
        return 1;
    }
    
    luaL_error(L, "wrong param, need number!");
    return null;
}

static int lua_read_double(lua_State *L, int idx, double *ret){
    if (lua_isnumber(L, idx)) {
        *ret = (double)lua_tonumber(L, idx);
        return 1;
    }
    
    luaL_error(L, "wrong param, need number!");
    return null;
}

static int lua_read_integer(lua_State *L, int idx, int *ret){
    if(lua_isnumber(L, idx)){
        *ret = (int)lua_tointeger(L, idx);
        return 1;
    }

    luaL_error(L, "wrong param, need integer!");
    return null;
}

static const char * lua_read_string(lua_State *L, int idx){
    if(lua_isstring(L, idx))
        return lua_tostring(L, idx);

    luaL_error(L, "wrong param, need string!");
    return null;
}

static int lua_read_userdata(lua_State *L, int idx, void **p){
    if (lua_isuserdata(L, idx)) {
        *p = lua_touserdata(L, idx);
        return 1;
    }
    
    luaL_error(L, "wrong param, need userdata!");
    return null;
}

static int lua_read_fix16(lua_State *L, int idx, fix16_t *f16){
    /*
    if (lua_isuserdata(L, idx)) {
        void *p = lua_touserdata(L, idx);
        *f16 = *((fix16_t *)p);
        return 1;
    }
    
    luaL_error(L, "wrong param, need fix16_t!");
     */
    
    if(lua_isnumber(L, idx)){
        *f16 = (fix16_t)lua_tonumber(L, idx);
        return 1;
    }
    return null;
}

static int lua_read_uint8(lua_State *L, int idx, uint8_t *u8){
    if (lua_isnumber(L, 3)) {
        *u8 = (uint8_t)lua_tonumber(L, 3);
        return 1;
    }else{
        luaL_error(L, "wrong param, need number!");
        return null;
    }
}

static int lua_read_uint16(lua_State *L, int idx, uint16_t *u16){
    if (lua_isnumber(L, 3)) {
        *u16 = (uint16_t)lua_tonumber(L, 3);
        return 1;
    }else{
        luaL_error(L, "wrong param, need number!");
        return null;
    }
}

static int lua_read_uint32(lua_State *L, int idx, uint32_t *u32){
    if (lua_isnumber(L, 3)) {
        *u32 = (uint32_t)lua_tonumber(L, 3);
        return 1;
    }else{
        luaL_error(L, "wrong param, need number!");
        return null;
    }
}

static void lua_write_fix16(lua_State *L, fix16_t f16){
    /*
    fix16_t *p = (fix16_t *)lua_newuserdata(L, sizeof(fix16_t));
    *p = f16;
    lua_pushlightuserdata(L, (void *)p);
     */
    lua_pushnumber(L, (lua_Number)f16);
}


static int lua_fix16_to_int(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    int n = fix16_to_int(f16);
    lua_pushinteger(L, (lua_Integer)n);
    return 1;
};

static int lua_fix16_to_float(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    float f = fix16_to_float(f16);
    lua_pushnumber(L, (lua_Number)f);
   
    return 1;
}

static int lua_fix16_to_dbl(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    double db = fix16_to_dbl(f16);
    lua_pushnumber(L, (lua_Number)db);

    return 1;
}

static int lua_fix16_to_str(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;

    int decimals;
    if(null == lua_read_integer(L, 2, &decimals))
        return null;
    
    int len =  sizeof(char)*13;
    char * psz = (char *)lua_newuserdata(L, len);
    fix16_to_str(f16, psz, decimals);
    lua_pushlstring(L, psz, len);

    return 1;
}

static int lua_fix16_from_int(lua_State *L){
    int n;
    if (null == lua_read_integer(L, 1, &n))
        return null;
    
    fix16_t f16 = fix16_from_int(n);
    lua_write_fix16(L, f16);
    
    return 1;
}


static int lua_fix16_from_float(lua_State *L){
    float f;
    if(null == lua_read_float(L, 1, &f))
        return null;
    
    fix16_t f16= fix16_from_float(f);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_from_dbl(lua_State *L){
    double dbl;
    if (null == lua_read_double(L, 1, &dbl))
        return null;
    
    fix16_t f16 = fix16_from_dbl(dbl);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_from_str(lua_State *L){
    const char * psz = lua_read_string(L, 1);
    if (null == psz)
        return null;
    
    fix16_t f16 = fix16_from_str(psz);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_abs(lua_State *L){
    fix16_t f16;
    if(null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_abs(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_floor(lua_State *L){
    fix16_t f16;
    if(null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_floor(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_ceil(lua_State *L){
    fix16_t f16;
    if(null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_ceil(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_min(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_min(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_max(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_max(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_clamp(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16c;
    if(null == lua_read_fix16(L, 3, &f16c))
        return null;
    
    fix16_t f16 = fix16_clamp(f16a, f16b, f16c);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_add(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_add(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sub(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_sub(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_mul(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_mul(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_div(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_mul(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sadd(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_sadd(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_ssub(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_ssub(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_smul(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_smul(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sdiv(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_sdiv(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_mod(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    fix16_t f16 = fix16_mod(f16a, f16b);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_lerp8(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;

    uint8_t u8;
    if(null == lua_read_uint8(L, 3, &u8))
        return null;
    
    fix16_t f16 = fix16_lerp32(f16a, f16b, u8);
    lua_write_fix16(L, f16);

    return 1;
}

static int lua_fix16_lerp16(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    uint16_t u16;
    if(null == lua_read_uint16(L, 3, &u16))
        return null;
    
    fix16_t f16 = fix16_lerp32(f16a, f16b, u16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_lerp32(lua_State *L){
    fix16_t f16a;
    if(null == lua_read_fix16(L, 1, &f16a))
        return null;
    
    fix16_t f16b;
    if(null == lua_read_fix16(L, 2, &f16b))
        return null;
    
    uint32_t u32;
    if(null == lua_read_uint32(L, 3, &u32))
        return null;
    
    fix16_t f16 = fix16_lerp32(f16a, f16b, u32);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sin_parabola(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_sin_parabola(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sin(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_sin(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_cos(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_cos(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_tan(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_tan(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_asin(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_asin(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_acos(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_acos(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_atan(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_atan(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}


static int lua_fix16_atan2(lua_State *L){
    fix16_t f16y;
    if (null == lua_read_fix16(L, 1, &f16y))
        return null;
    
    fix16_t f16x;
    if (null == lua_read_fix16(L, 1, &f16x))
        return null;
    
    fix16_t f16 = fix16_atan2(f16y, f16x);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_rad_to_deg(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_rad_to_deg(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_deg_to_rad(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_deg_to_rad(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sqrt(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_sqrt(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_sq(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_sq(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_exp(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_exp(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_log(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_log(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_log2(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_log2(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}

static int lua_fix16_slog2(lua_State *L){
    fix16_t f16;
    if (null == lua_read_fix16(L, 1, &f16))
        return null;
    
    f16 = fix16_slog2(f16);
    lua_write_fix16(L, f16);
    
    return 1;
}



static const luaL_Reg fixmath[] = {
    {"fix16_to_float", lua_fix16_to_float},
    {"fix16_to_int",  lua_fix16_to_int},
    {"fix16_to_dbl",  lua_fix16_to_dbl},
    {"fix16_to_str",  lua_fix16_to_str},
    {"fix16_from_float",  lua_fix16_from_float},
    {"fix16_from_int",  lua_fix16_from_int},
    {"fix16_from_dbl",  lua_fix16_from_dbl},
    {"fix16_from_str",  lua_fix16_from_str},
    {"fix16_abs",  lua_fix16_abs},
    {"fix16_floor",  lua_fix16_floor},
    {"fix16_ceil",  lua_fix16_ceil},
    {"fix16_min",  lua_fix16_min},
    {"fix16_max",  lua_fix16_max},
    {"fix16_clamp",  lua_fix16_clamp},
    {"fix16_add",  lua_fix16_add},
    {"fix16_sub",  lua_fix16_sub},
    {"fix16_mul",  lua_fix16_mul},
    {"fix16_div",  lua_fix16_div},
    {"fix16_sadd",  lua_fix16_sadd},
    {"fix16_ssub",  lua_fix16_ssub},
    {"fix16_smul",  lua_fix16_smul},
    {"fix16_sdiv",  lua_fix16_sdiv},
    {"fix16_mod",  lua_fix16_mod},
    {"fix16_lerp8",  lua_fix16_lerp8},
    {"fix16_lerp16",  lua_fix16_lerp16},
    {"fix16_lerp32",  lua_fix16_lerp32},
    {"fix16_sin_parabola", lua_fix16_sin_parabola},
    {"fix16_sin",  lua_fix16_sin},
    {"fix16_cos",  lua_fix16_cos},
    {"fix16_tan",  lua_fix16_tan},
    {"fix16_asin",  lua_fix16_asin},
    {"fix16_acos",  lua_fix16_acos},
    {"fix16_atan",  lua_fix16_atan},
    {"fix16_atan2",  lua_fix16_atan2},
    {"fix16_rad_to_deg",  lua_fix16_rad_to_deg},
    {"fix16_deg_to_rad",  lua_fix16_deg_to_rad},
    {"fix16_sqrt",  lua_fix16_sqrt},
    {"fix16_sq",  lua_fix16_sq},
    {"fix16_exp",  lua_fix16_exp},
    {"fix16_log",  lua_fix16_log},
    {"fix16_log2",  lua_fix16_log2},
    {"fix16_slog2",  lua_fix16_slog2},
    {NULL, NULL}
};

static void set_field(lua_State *L, const char * pszField, fix16_t data){
    lua_pushnumber(L, (lua_Number)data);
    lua_setfield(L, -2, pszField);
}


int luaopen_fixmath (lua_State *L);
int luaopen_fixmath (lua_State *L) {
    luaL_newlib(L, fixmath);
    set_field(L, "FOUR_DIV_PI", FOUR_DIV_PI);
    set_field(L, "_FOUR_DIV_PI2", _FOUR_DIV_PI2);
    set_field(L, "X4_CORRECTION_COMPONENT", X4_CORRECTION_COMPONENT);
    set_field(L, "PI_DIV_4", PI_DIV_4);
    set_field(L, "THREE_PI_DIV_4", THREE_PI_DIV_4);
    set_field(L, "fix16_maximum", fix16_maximum);
    set_field(L, "fix16_minimum", fix16_minimum);
    set_field(L, "fix16_overflow", fix16_overflow);
    set_field(L, "fix16_pi", fix16_pi);
    set_field(L, "fix16_e", fix16_e);
    set_field(L, "fix16_one", fix16_one);
    set_field(L, "fix16_rad_to_deg_mult", fix16_rad_to_deg_mult);

    lua_pushvalue(L, -1);
    lua_setglobal(L, FM_LIBNAME);
    return 1;
}

