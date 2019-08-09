#include <assert.h>
#include <string.h>
#include <math.h>
#include <limits.h>

extern "C"{
#include <lua.h>
#include <lauxlib.h>
}

#include "fractor.h"


#ifndef FRACTOR_MODELNAME
#define FRACTOR_MODELNAME "lfractor"
#endif

#ifndef FRACTOR_VERSION
#define FRACTOR_VERSION   "0.0.1"
#endif

#define READ_FRACTOR(index) 	Fractor *fp; \
															Fractor *p; \
															p = (Fractor *)lua_touserdata(L, index); \
															luaL_argcheck(L, p != NULL, 1, "args Fractor not exist"); \
															fp = p; 

#define READ_FRACTOR2(index)  Fractor *fp1, *fp2; \
															Fractor *p; \
															p = (Fractor *)lua_touserdata(L, index); \
															luaL_argcheck(L, p != NULL, 1, "args Fractor not exist"); \
															fp1 = p; \
															p = (Fractor *)lua_touserdata(L, index + 1); \
															luaL_argcheck(L, p != NULL, 1, "args Fractor not exist"); \
															fp2 = p; 



#define PUSH_FRACTOR(x)  *((Fractor *) lua_newuserdata(L, sizeof(Fractor))) = x; \
												luaL_getmetatable(L, "Fractor"); \
												lua_setmetatable(L, -2); 



extern "C" {



static int lfractor_to_string(lua_State *L)
{
	char psz[24] = {0};
	READ_FRACTOR(1)

	(*fp).cstr(psz);
	lua_pushstring(L, psz);
	return 1;
}

static int lfractor_add(lua_State *L)
{
	READ_FRACTOR2(1)
	PUSH_FRACTOR((*fp1) + (*fp2))
	return 1; 
}

static int lfractor_sub(lua_State *L)
{
	READ_FRACTOR2(1)
	PUSH_FRACTOR((*fp1) - (*fp2))
	return 1; 
}

static int lfractor_mul(lua_State *L)
{
	READ_FRACTOR2(1)
	PUSH_FRACTOR((*fp1) * (*fp2))
	return 1; 
}

static int lfractor_div(lua_State *L)
{
	READ_FRACTOR2(1)
	assert((*fp2) != Fractor::zero);

	PUSH_FRACTOR((*fp1) / (*fp2))
	return 1; 
}

static int lfractor_eq(lua_State *L)
{
	bool b;
	READ_FRACTOR2(1);
	b = ((*fp1) == (*fp2));
	lua_pushboolean(L, b);
	return 1;
}

static int lfractor_lt(lua_State *L)
{
	bool b;
	READ_FRACTOR2(1)
	
	b = ((*fp1) < (*fp2));
	lua_pushboolean(L, b);
	return 1;
}

static int lfractor_le(lua_State *L)
{
	bool b;
	READ_FRACTOR2(1)

	b = ((*fp1) <= (*fp2));
	lua_pushboolean(L, b);
	return 1;
}

static int lfractor_unm(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR(-(*fp));
	return 1;
}

static int lfractor_to_int(lua_State *L)
{
	READ_FRACTOR(1)

	lua_pushinteger(L, (*fp).to_i());
	return 1;
}

static int lfractor_to_float(lua_State *L)
{
	READ_FRACTOR(1)
	lua_pushnumber(L, (lua_Number)((*fp).to_d()));
	return 1;
}

static int lfractor_abs(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).absf())
	return 1;
}

static int lfractor_sqrt(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).sqrtf())
	return 1;
}

static int lfractor_sin(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).sinf())
	return 1;
}

static int lfractor_cos(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).cosf())
	return 1;
}

static int lfractor_tan(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).tanf())
	return 1;
}

static int lfractor_exp(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).expf())
	return 1;
}

static int lfractor_ln(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).lnf())
	return 1;
}

static int lfractor_log(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).logf())
	return 1;
}

static int lfractor_atan2(lua_State *L)
{
	Fractor ret;
	READ_FRACTOR2(1)
	ret = Fractor::atan2f((*fp1), (*fp2));
	PUSH_FRACTOR(ret)
	return 1;
}

static int lfractor_atan(lua_State *L)
{
	Fractor ret;
	READ_FRACTOR(1)
	ret = Fractor::atanf((*fp));
	PUSH_FRACTOR(ret)
	return 1;
}

static int lfractor_asin(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).asinf())
	return 1;
}

static int lfractor_acos(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).acosf())
	return 1;
}

static int lfractor_deg_to_rad(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).to_rad())
	return 1;
}

static int lfractor_rad_to_deg(lua_State *L)
{
	READ_FRACTOR(1)
	PUSH_FRACTOR((*fp).to_deg())
	return 1;
}

static int lfractor_pow(lua_State *L)
{
	Fractor ret;
	READ_FRACTOR2(2)
	ret = Fractor::powf((*fp1), (*fp2));
	PUSH_FRACTOR(ret)
	return 1;
}


static int lfractor_from_float(lua_State *L)
{
	double d = (double)lua_tonumber(L, 1);
	Fractor fp(d);
	PUSH_FRACTOR(fp);
	return 1;
}

static int lfractor_from_int(lua_State *L)
{
	int n = (int)lua_tointeger(L, 1);
	PUSH_FRACTOR( Fractor(n) );
	return 1;
}

//Implements for lua table fractor
static Fractor fra1, fra2;
#define READ_FRACTOR_LT    	fra1.nom = (int64_t)lua_tonumber(L, 1); \
														fra1.den = (int64_t)lua_tonumber(L, 2);

#define READ_FRACTOR_LT2    fra1.nom = (int64_t)lua_tonumber(L, 1); \
														fra1.den = (int64_t)lua_tonumber(L, 2); \
														fra2.nom = (int64_t)lua_tonumber(L, 3); \
														fra2.den = (int64_t)lua_tonumber(L, 4);

#define PUSH_FRACTOR_LT(ret) lua_pushnumber(L, (lua_Number)(ret.nom)); \
														 lua_pushnumber(L, (lua_Number)(ret.den)); \
														 return 2;  

static int lfractor_from_float_lt(lua_State *L)
{
	double d = (double)lua_tonumber(L, 1);
	Fractor ret(d);

	PUSH_FRACTOR_LT(ret)
}

static int lfractor_from_int_lt(lua_State *L)
{
	int n = (int)lua_tointeger(L, 1);
	Fractor ret(n);

	PUSH_FRACTOR_LT(ret)
}

static int lfractor_to_string_lt(lua_State *L)
{
	READ_FRACTOR_LT

	char psz[24] = {0};
	Fractor::cstrf(fra1, psz);
	lua_pushstring(L, psz);
	return 1;
}

static int lfractor_add_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	Fractor ret = (fra1 + fra2);
	
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_sub_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	Fractor ret = (fra1 - fra2);
	
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_mul_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	Fractor ret = (fra1 * fra2);
	
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_div_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	Fractor ret = (fra1 / fra2);
	
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_eq_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	bool b = (fra1 == fra2);
	lua_pushboolean(L, b);
	return 1;
}

static int lfractor_lt_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	bool b = (fra1 < fra2);
	lua_pushboolean(L, b);
	return 1;
}

static int lfractor_le_lt(lua_State *L)
{
	READ_FRACTOR_LT2
	
	bool b = (fra1 <= fra2);
	lua_pushboolean(L, b);
	return 1;
}

static int lfractor_unm_lt(lua_State *L)
{
	READ_FRACTOR_LT

	Fractor ret = -fra1;

	PUSH_FRACTOR_LT(ret)
}

static int lfractor_to_int_lt(lua_State *L)
{
	READ_FRACTOR_LT

	lua_pushinteger(L, fra1.to_i());
	
	return 1;
}

static int lfractor_to_float_lt(lua_State *L)
{
	READ_FRACTOR_LT

	lua_pushnumber(L, (lua_Number)(fra1.to_d()));
	
	return 1;
}

static int lfractor_abs_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.absf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_sqrt_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.sqrtf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_sin_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.sinf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_cos_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.cosf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_tan_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.tanf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_exp_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.expf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_ln_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.lnf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_log_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.logf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_atan2_lt(lua_State *L)
{
	READ_FRACTOR_LT2

	Fractor ret = Fractor::atan2f(fra1, fra1);

	PUSH_FRACTOR_LT(ret)
}

static int lfractor_asin_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.asinf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_acos_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.acosf();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_deg_to_rad_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.to_rad();
	PUSH_FRACTOR_LT(ret)
}

static int lfractor_rad_to_deg_lt(lua_State *L)
{
	READ_FRACTOR_LT
	Fractor ret = fra1.to_deg();
	PUSH_FRACTOR_LT(ret)
}



static const luaL_Reg fractor_methods[] = {
	{"__tostring", lfractor_to_string},
	{"__add", lfractor_add},
  {"__sub", lfractor_sub},
  {"__mul", lfractor_mul},
  {"__div", lfractor_div},
	{"__eq", lfractor_eq},
	{"__lt", lfractor_lt},
	{"__le", lfractor_le},
	{"__unm", lfractor_unm},
	{"to_int", lfractor_to_int},
	{"to_float", lfractor_to_float},
	{"abs", lfractor_abs},
	{"sqrt", lfractor_sqrt},
	{"sin", lfractor_sin},
	{"cos", lfractor_cos},
	{"tan", lfractor_tan},
	{"exp", lfractor_exp},
	{"ln", lfractor_ln},
	{"log", lfractor_log},
	{"asin", lfractor_asin},
	{"acos", lfractor_acos},
	{"deg_to_rad", lfractor_deg_to_rad},
	{"rad_to_deg", lfractor_rad_to_deg},
	{NULL, NULL}
};

static const luaL_Reg lfractor_methods[] = {
	{"from_float", lfractor_from_float},
	{"from_int", lfractor_from_int},
	{"to_float", lfractor_to_float},
	{"to_int", lfractor_to_int},
	{"abs", lfractor_abs},
	{"sqrt", lfractor_sqrt},
	{"sin", lfractor_sin},
	{"cos", lfractor_cos},
	{"tan", lfractor_tan},
	{"exp", lfractor_exp},
	{"ln", lfractor_ln},
	{"log", lfractor_log},
	{"pow", lfractor_pow},
	{"atan2", lfractor_atan2},
	{"atan", lfractor_atan},
	{"asin", lfractor_asin},
	{"acos", lfractor_acos},
	{"deg_to_rad", lfractor_deg_to_rad},
	{"rad_to_deg", lfractor_rad_to_deg},
	//implement for lua table fractor
	{"lf_from_float", lfractor_from_float_lt},
	{"lf_from_int", lfractor_from_int_lt},
	{"lf_tostring", lfractor_to_string_lt},
	{"lf_add", lfractor_add_lt},
  {"lf_sub", lfractor_sub_lt},
  {"lf_mul", lfractor_mul_lt},
  {"lf_div", lfractor_div_lt},
	{"lf_eq", lfractor_eq_lt},
	{"lf_lt", lfractor_lt_lt},
	{"lf_le", lfractor_le_lt},
	{"lf_unm", lfractor_unm_lt},
	{"lf_to_int", lfractor_to_int_lt},
	{"lf_to_float", lfractor_to_float_lt},
	{"lf_abs", lfractor_abs_lt},
	{"lf_sqrt", lfractor_sqrt_lt},
	{"lf_sin", lfractor_sin_lt},
	{"lf_cos", lfractor_cos_lt},
	{"lf_tan", lfractor_tan_lt},
	{"lf_exp", lfractor_exp_lt},
	{"lf_ln", lfractor_ln_lt},
	{"lf_log", lfractor_log_lt},
	{"lf_atan2", lfractor_atan2_lt},
	{"lf_asin", lfractor_asin_lt},
	{"lf_acos", lfractor_acos_lt},
	{"lf_deg_to_rad", lfractor_deg_to_rad_lt},
	{"lf_rad_to_deg", lfractor_rad_to_deg_lt},
	{NULL, NULL}
};


static void create_fractor_metatable(lua_State *L)
{
	luaL_newmetatable(L, "Fractor");

	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);             
	lua_rawset(L, -3);    

	lua_pushinteger(L, 1);
	lua_setfield(L, -2, "__FRAC__");

#if LUA_VERSION_NUM==503
	luaL_setfuncs(L, fractor_methods, 0);
#else
	luaL_register(L, NULL, fractor_methods);
#endif
	lua_pop(L, 1);
}


static void push_fractor_consts(lua_State *L)
{
	PUSH_FRACTOR(Fractor::max)
  lua_setfield(L, -2, "MAX");
  
  PUSH_FRACTOR(Fractor::min)
  lua_setfield(L, -2, "MIN");

  PUSH_FRACTOR(Fractor::one)
  lua_setfield(L, -2, "ONE");

  PUSH_FRACTOR(Fractor::zero)
  lua_setfield(L, -2, "ZERO");

  PUSH_FRACTOR(Fractor::two)
  lua_setfield(L, -2, "TWO");

  PUSH_FRACTOR(Fractor::half)
  lua_setfield(L, -2, "HALF");

  PUSH_FRACTOR(Fractor::ten)
  lua_setfield(L, -2, "TEN");

  PUSH_FRACTOR(Fractor::pi)
  lua_setfield(L, -2, "PI");

  PUSH_FRACTOR(Fractor::half_pi)
  lua_setfield(L, -2, "HALF_PI");
  
  PUSH_FRACTOR(Fractor::two_pi)
  lua_setfield(L, -2, "TWO_PI");

	PUSH_FRACTOR(Fractor::quat_pi)
  lua_setfield(L, -2, "QUAT_PI");
  
  PUSH_FRACTOR(Fractor::e)
  lua_setfield(L, -2, "E");

  lua_pushliteral(L, FRACTOR_MODELNAME);
  lua_setfield(L, -2, "NAME");

  lua_pushliteral(L, FRACTOR_VERSION);
  lua_setfield(L, -2, "VERSION");
}

LUALIB_API int luaopen_lfractor(lua_State *L)
{
	create_fractor_metatable(L);
#if LUA_VERSION_NUM==503	
	luaL_newlib(L, lfractor_methods);
#else
	luaL_register(L, FRACTOR_MODELNAME, lfractor_methods);
#endif
	push_fractor_consts(L);

	return 1;
}

}

