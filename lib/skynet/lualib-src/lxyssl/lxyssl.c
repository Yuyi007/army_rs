/*
* lxyssl.c
* xyssl library binding for Lua 5.1
* Copyright 2007 Gary Ng<linux@garyng.com>
* This code can be distributed under the LGPL license
*/

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <fcntl.h>
#if !defined(_WIN32)
#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <unistd.h>
#elif defined(WP8)
#include <time.h>
#include <winsock2.h>
#else
#include <time.h>
#include <winsock.h>
#endif
#include <errno.h>
#define USE_LIBEVENT_NO
#ifdef USE_LIBEVENT
#include <poll.h>
#include <event.h>
#endif
#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"

#include "xyssl/net.h"
#include "xyssl/ssl.h"
#include "xyssl/havege.h"
#include "xyssl/certs.h"
#include "xyssl/x509.h"
#include "xyssl/sha1.h"
#include "xyssl/sha2.h"
#include "xyssl/md5.h"
#include "xyssl/aes.h"
#include "xyssl/arc4.h"

/*
 * Computing a safe DH-1024 prime takes ages, so it's faster
 * to use a precomputed value (provided below as an example).
 * Run the dh_genprime program to generate an acceptable P.
 */
char *default_dhm_P = 
    "E4004C1F94182000103D883A448B3F80" \
    "2CE4B44A83301270002C20D0321CFD00" \
    "11CCEF784C26A400F43DFB901BCA7538" \
    "F2C6B176001CF5A0FD16D2C48B1D0C1C" \
    "F6AC8E1DA6BCC3B4E1F96B0564965300" \
    "FFA1D0B601EB2800F489AA512C4B248C" \
    "01F76949A60BB7F00A40B1EAB64BDD48" \
    "E8A700D60B7F1200FA8E77B0A979DABF";

char *default_dhm_G = "4";

#ifndef SSL3_RSA_RC4_128_MD5
#define SSL3_RSA_RC4_128_MD5 SSL_RSA_RC4_128_MD5
#define SSL3_RSA_RC4_128_SHA SSL_RSA_RC4_128_SHA
#define TLS1_EDH_RSA_AES_256_SHA SSL_EDH_RSA_AES_256_SHA
#define TLS1_RSA_AES_256_SHA SSL_RSA_AES_256_SHA
#define ERR_NET_WOULD_BLOCK XYSSL_ERR_NET_TRY_AGAIN
#define ERR_NET_CONN_RESET XYSSL_ERR_NET_CONN_RESET
#define ERR_SSL_PEER_CLOSE_NOTIFY XYSSL_ERR_SSL_PEER_CLOSE_NOTIFY
#define XYSSL_POST_07
#define ssl_set_rng_func ssl_set_rng
#define ssl_set_ciphlist ssl_set_ciphers
#define aes_decrypt(c,i,o) aes_crypt_ecb(c, AES_DECRYPT, i , o)
#define aes_encrypt(c,i,o) aes_crypt_ecb(c, AES_ENCRYPT, i , o)
#define aes_cbc_encrypt(c, iv, i, o, l) aes_crypt_cbc(c, AES_ENCRYPT, l, iv, i, o)
#define aes_cbc_decrypt(c, iv, i, o, l) aes_crypt_cbc(c, AES_DECRYPT, l, iv, i, o)
#define x509_add_certs x509parse_crt
#define x509_parse_key x509parse_key
#define ssl_set_rsa_cert ssl_set_own_cert
#define x509_free_cert x509_free
#endif

#define _LEN_TYPE long

/*
 * sorted by order of preference
 */
int my_preferred_ciphers[] =
{
    SSL3_RSA_RC4_128_MD5,
    SSL3_RSA_RC4_128_SHA,
    TLS1_EDH_RSA_AES_256_SHA,
    TLS1_RSA_AES_256_SHA,
#if 0
    SSL3_EDH_RSA_DES_168_SHA,
    SSL3_RSA_DES_168_SHA,
#endif
    0
};

enum {
    MD5,
    SHA1,
    SHA2,
    HMAC_MD5,
    HMAC_SHA1,
    HMAC_SHA2,
};

typedef struct {
 ssl_context ssl;
 x509_cert cacert;
 x509_cert mycert;
 rsa_context mykey;
 double timeout;
 int last_send_size;
 char *peer_cn;
 int closed;
 int re_open;
 int read_fd;
 int write_fd;
 char *dhm_P;
 char *dhm_G;
 #ifdef XYSSL_POST_07
 ssl_session ssn;
 #endif
} xyssl_context;

typedef struct {
  aes_context enc;
  aes_context dec;
} dual_aes_context;

#ifdef USE_LIBEVENT
typedef struct {
    struct event_base *base;
    int event_fd_map;
    int r_cnt;
    int w_cnt;
    int rtab;
    int wtab;
    int o_rtab;
    int o_wtab;
    lua_State *L;
} libevent_context;

typedef struct {
    struct event ev;
    int open;
    int fd;
    int want;
    libevent_context *libevent;
} event_context;

libevent_context libevent_handle;
#endif

/* sharing session info across ssl context in server mode */

int session_table_idx = -1;
lua_State *Current_LVM = NULL;

#ifndef SSL_SESSION_TBL_LEN
#define SSL_SESSION_TBL_LEN 256
#endif
unsigned char default_session_table[SSL_SESSION_TBL_LEN];
unsigned char *session_table = default_session_table;
int malloc_sidtable = 0;

#ifdef XYSSL_POST_07
/*
 * These session callbacks use a simple chained list
 * to store and retrieve the session information.
 */
ssl_session s_list[SSL_SESSION_TBL_LEN];

static const void * getbuffer(lua_State *L, int index, size_t *sz) {
    const void * buffer = NULL;
    int t = lua_type(L, index);
    if (t == LUA_TSTRING) {
        buffer = lua_tolstring(L, index, sz);
    } else {
        if (t != LUA_TUSERDATA && t != LUA_TLIGHTUSERDATA) {
            luaL_argerror(L, index, "Need a string or userdata");
            return NULL;
        }
        buffer = lua_touserdata(L, index);
        *sz = luaL_checkinteger(L, index+1);
    }
    return buffer;
}

static int default_get_session( ssl_context *ssl )
{
    time_t t = time( NULL );
    int i;

    for (i=0; i < SSL_SESSION_TBL_LEN; i++) {
      ssl_session *cur = &s_list[i];
      if( ssl->timeout != 0 && t - cur->start > ssl->timeout )
          continue;
      if( ssl->session->cipher != cur->cipher ||
          ssl->session->length != cur->length )
          continue;
      if( memcmp( ssl->session->id, cur->id, cur->length ) != 0 )
          continue;
      memcpy( ssl->session->master, cur->master, 48 );
      return( 0 );
    }

    return( 1 );
}

static int default_set_session( ssl_context *ssl )
{
    time_t t = time( NULL );
    int i;
    ssl_session *cur;

    for (i=0; i < SSL_SESSION_TBL_LEN; i++) {
      cur = &s_list[i];
      if( memcmp( ssl->session->id, cur->id, cur->length ) == 0 )
          break; /* client reconnected */
      if( cur->start == 0 || (ssl->timeout != 0 && t - cur->start > ssl->timeout))
          break; /* expired */
    }

    if (i >= SSL_SESSION_TBL_LEN) 
      i = *((unsigned short*)(ssl->session->id)) % SSL_SESSION_TBL_LEN;
    cur = &s_list[i];
    memcpy( cur, ssl->session, sizeof( ssl_session ) );
    cur->start = t;
    return( 0 );
}

#endif

#define EXPORT_HASH_FUNCTIONS
#if 0
#define EXPORT_SHA2
#endif

typedef void (*hash_start_func)(void *);
typedef void (*hash_update_func)(void *, unsigned char *, int);
typedef unsigned char* (*hash_finish_func)(void *, unsigned char*);

typedef struct {
    union {
        md5_context md5;
        sha1_context sha1;
#ifdef EXPORT_SHA2
        sha2_context sha2;
#endif
    } eng;
    void (*starts)(void *);
    void (*update)(void *, unsigned char*, int);
    unsigned char* (*finish)(void *, unsigned char*);
    int hash_size;
    int id;
} hash_context;


#ifdef XYSSL_POST_07
#define MYVERSION	"XySSL 0.8 for " LUA_VERSION "/0.2"
#else
#define MYVERSION	"XySSL 0.7 for " LUA_VERSION "/0.2"
#endif
#define MYTYPE		"XySSL SSL object"
#define MYHASH      "XySSL Hash object"
#define MYAES       "XySSL AES object"
#define MYRC4       "XySSL RC4 object"
#define MYEVENT     "Libevent object"

havege_state hs;
arc4_context arc4_stream;

#ifdef XYSSL_POST_07
static int my_get_session(ssl_context *ssl)
{
    lua_State *L = Current_LVM;
    int ret;
    if (L == NULL) return 1;
    lua_pushstring(L, "get_session");
    lua_gettable(L, 1);
    if (lua_isnil(L, -1)) {
      lua_pop(L,1);
      return default_get_session(ssl);
	  }
    lua_pushvalue(L, 1);
    lua_pushlstring(L, ssl->session->id, ssl->session->length);
    lua_pushnumber(L, ssl->session->cipher);
    ret = lua_pcall(L, 3, 1, 0);
    if (ret) {
        lua_pop(L,1);
        return 1;
    }
    if (lua_isstring(L, -1)) {
        _LEN_TYPE len;
        const char *master = luaL_checklstring(L, -1, &len);
        memcpy(ssl->session->master, master, len < sizeof(ssl->session->master) ? len : sizeof(ssl->session->master));
        lua_pop(L, 1);
        return 0;
    }
    lua_pop(L, 1);
    return 1;
}

static int my_set_session(ssl_context *ssl)
{
    lua_State *L = Current_LVM;
    int ret;
    if (L == NULL) return 0;
    lua_pushstring(L, "set_session");
    lua_gettable(L, 1);
    if (lua_isnil(L, -1)) {
        lua_pop(L,1);
        return default_set_session(ssl);
    }
    lua_pushvalue(L, 1);
    lua_pushlstring(L, ssl->session->id, ssl->session->length);
    lua_pushnumber(L, ssl->session->cipher);
    lua_pushlstring(L, ssl->session->master, sizeof(ssl->session->master));
    ret = lua_pcall(L, 4, 1, 0);
    lua_pop(L,1);
    return 0;
}
#endif

static int arc4_rand(void *state)
{
    unsigned char temp[1];

    arc4_crypt(state, temp, 1);
    return temp[0];
}

static int Pselect(int fd, double t, int w)
{
    struct timeval tm;
    fd_set set;
    FD_ZERO(&set); 

    if (t >= 0.0) {
        tm.tv_sec = (int) t;
        tm.tv_usec = (int) ((t - tm.tv_sec)*1000);
    }

    FD_SET(fd, &set); 
    if (w) {
        return select(fd+1, NULL, &set, NULL, t < 0 ? NULL : &tm);
    }
    else {
        return select(fd+1, &set, NULL, NULL, t < 0 ? NULL : &tm);
    }
}

static xyssl_context *Pget(lua_State *L, int i)
{
 return lua_touserdata(L,i);
}

static int Preset(lua_State *L)			/** reset(c) */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 int is_server = ssl->endpoint;
 int authmode = ssl->authmode;
 int ret;

 #if 0
 #endif
 ssl_free(ssl);
 #ifdef XYSSL_POST_07
 ret = ssl_init(ssl);
 #else
 ret = ssl_init(ssl, is_server ? 0 : 1);
 #endif
 ssl_set_endpoint( ssl, is_server ? SSL_IS_SERVER : SSL_IS_CLIENT );
 ssl_set_authmode( ssl, authmode );
 #ifdef XYSSL_POST_07
 ssl_set_session( ssl, 1, is_server ? 0 : 600, &xyssl->ssn);
 #endif
 #if 0
 ssl_set_rng_func( ssl, havege_rand, &hs );
 #endif
 ssl_set_rng_func( ssl, arc4_rand, &arc4_stream );
 ssl_set_ciphlist( ssl, my_preferred_ciphers);
 #if 0
 ssl_set_ciphlist( ssl, ssl_default_ciphers );
 #endif

 if (is_server) {
 #ifndef XYSSL_POST_07
    ssl_set_sidtable( ssl, session_table );
    ssl_set_dhm_vals( ssl, xyssl->dhm_P ? xyssl->dhm_P : default_dhm_P, xyssl->dhm_G ? xyssl->dhm_G : default_dhm_G);
 #else
    ssl_set_scb(ssl, my_get_session, my_set_session);
    ssl_set_dh_param( ssl, xyssl->dhm_P ? xyssl->dhm_P : default_dhm_P, xyssl->dhm_G ? xyssl->dhm_G : default_dhm_G);
 #endif
 }
 return ret;
}


static int Psetfd(lua_State *L)		/** setfd(r[,w]) */
{
 xyssl_context *xyssl=Pget(L,1);
 int read_fd = luaL_checknumber(L,2);
 int re_open = lua_toboolean(L, lua_isnumber(L,3) ? 4 : 3);
 int write_fd = lua_isnumber(L, 3) ? lua_tointeger(L,3) : read_fd;

 ssl_context *ssl=&xyssl->ssl;

 #ifndef _WIN32
 if (re_open) {
    xyssl->re_open = re_open;
    if (read_fd != write_fd) {
        read_fd = dup(read_fd);
        write_fd = dup(write_fd);
    } else {
        write_fd = read_fd = dup(read_fd);
    }
 }
 xyssl->re_open = re_open;
 #endif
 xyssl->read_fd = read_fd;
 xyssl->write_fd = write_fd;
 #ifndef XYSSL_POST_07
 ssl_set_io_files( ssl, read_fd, write_fd );
 #else
 ssl_set_bio(ssl, net_recv, &xyssl->read_fd, net_send, &xyssl->write_fd);
 #endif
 return 0;

}

static int Laes(lua_State *L)
{
 _LEN_TYPE klen;
 const unsigned char *key = luaL_checklstring(L, 1, &klen);
 int bits = luaL_optinteger(L, 2, 128);
 dual_aes_context *aes = lua_newuserdata(L,sizeof(dual_aes_context));

 if (klen*8 != bits) {
    lua_pop(L, 1);
    luaL_error(L,"xyssl.aes: key not long enough for selected bits length");
 }
 luaL_getmetatable(L,MYAES);
 lua_setmetatable(L,-2);
 #ifndef XYSSL_POST_07
 aes_set_key(&aes->enc, (unsigned char *)key, bits);
 aes_set_key(&aes->dec, (unsigned char *)key, bits);
 #else
 aes_setkey_enc(&aes->enc, (unsigned char *)key, bits);
 aes_setkey_dec(&aes->dec, (unsigned char *)key, bits);
 #endif

 return 1;
}

static int Lrc4(lua_State *L)
{
 _LEN_TYPE klen;
 const unsigned char *key = luaL_checklstring(L, 1, &klen);
 arc4_context *rc4 = lua_newuserdata(L,sizeof(arc4_context));
 arc4_setup(rc4, (unsigned char *)key, klen);
 luaL_getmetatable(L,MYRC4);
 lua_setmetatable(L,-2);

 return 1;
}

#ifdef USE_LIBEVENT
void Pevent_cb(int fd, short ev, void *arg)
{
 event_context *p = arg;
 libevent_context *libevent = p->libevent;
 lua_State *L = libevent->L;
 int top = lua_gettop(L);

 if (fd == -1) return;

 lua_rawgeti(L, LUA_REGISTRYINDEX, libevent->event_fd_map); 
 lua_pushinteger(L, fd);
 lua_gettable(L, -2);
 if (lua_isnil(L, -1)) {
    lua_pop(L,2);
 }
 else {
    if (ev & EV_READ && p->want & EV_READ) {
        p->want &= ~EV_READ;
        #if 0
        lua_pushvalue(L, -1);
        lua_gettable(L, libevent->rtab); /* want to read table */
        #endif
        if (1 || !lua_isnil(L, -1)) { /* interested */
            libevent->r_cnt++;
            lua_pushinteger(L, libevent->r_cnt);
            lua_pushvalue(L, -2);
            lua_settable(L, libevent->o_rtab);
            lua_pushvalue(L, -1);
            lua_pushinteger(L, libevent->r_cnt);
            lua_settable(L, libevent->o_rtab);
        }
        #if 0
        lua_pop(L,1);
        #endif
    }
    if (ev & EV_WRITE && p->want & EV_WRITE) {
        p->want &= ~EV_WRITE;
        #if 0
        lua_pushvalue(L, -1);
        lua_gettable(L, libevent->wtab); /* want to write table */
        #endif
        if (1 || !lua_isnil(L, -1)) { /* interested */
            libevent->w_cnt++;
            lua_pushvalue(L, -1);
            lua_pushinteger(L, libevent->w_cnt);
            lua_settable(L, libevent->o_wtab);
            lua_pushinteger(L, libevent->w_cnt);
            lua_pushvalue(L, -2);
            lua_settable(L, libevent->o_wtab);
        }
        #if 0
        lua_pop(L,1);
        #endif
    }
    lua_pop(L, 2); /* event_fd_map on stack and fd->obj value */
 }
}

static event_context *Pevent(lua_State *L, int i)
{
 return lua_touserdata(L,i);
}

static int Levent_select(lua_State *L)
{
 double t = luaL_optnumber(L, 3, -1);
 #if 0
 int flags = 0;
 #endif
 int flags = EVLOOP_ONCE;
 int i = 0;
 int itab, rtab, wtab;
 event_context tout;
 libevent_context *libevent = &libevent_handle;
 struct timeval tv, *ptv = NULL;

 if (t >= 0.0) {
    tv.tv_sec = (int) t;
    tv.tv_usec = (t - tv.tv_sec)*1000000;
    #if 1
    tout.libevent = &libevent_handle;
    evtimer_set(&tout.ev, Pevent_cb, &tout);
    evtimer_add(&tout.ev, &tv);
    #endif
    flags |= EVLOOP_NONBLOCK;
    ptv = &tv;
 }

 lua_settop(L, 3);
 lua_newtable(L); rtab = lua_gettop(L);
 lua_newtable(L); wtab = lua_gettop(L);

 libevent->r_cnt = 0;
 libevent->w_cnt = 0;
 libevent->rtab = 1;
 libevent->wtab = 2;
 libevent->o_rtab = rtab;
 libevent->o_wtab = wtab;
 libevent->L = L;

 i=0;
 while (++i) {
    int dirty = 0;
    lua_pushnumber(L,i);
    lua_gettable(L, 1);
    if (lua_isnil(L,-1)) {
        lua_pop(L,1);
        break;
    }
    lua_pushstring(L,"dirty");
    lua_gettable(L,-2);
    if (!lua_isnil(L, -1)) {
        lua_pushvalue(L,-2);
        lua_call(L, 1, 1);
        dirty = lua_toboolean(L, -1);
    }
    lua_pop(L,1);
    if (dirty) {
        lua_pushnumber(L, ++libevent->r_cnt);
        lua_pushvalue(L,-2);
        lua_settable(L, libevent->o_rtab);
        lua_pushnumber(L, libevent->r_cnt);
        lua_settable(L, libevent->o_rtab);
    } else {
        lua_pushstring(L,"event");
        lua_gettable(L,-2);
        if (!lua_isnil(L, -1)) {
            event_context *p = Pevent(L, -1); 
                #if 0
                event_set(&p->ev, p->fd, EV_READ , Pevent_cb, p);
                event_add(&p->ev, ptv);  
                #endif
                p->want = EV_READ;
        }
        lua_pop(L,2);
    }
 }

 i=0;
 while (++i) {
    lua_pushnumber(L,i);
    lua_gettable(L, 2);
    if (lua_isnil(L,-1)) {
        lua_pop(L,1);
        break;
    }
    lua_pushstring(L,"event");
    lua_gettable(L,-2);
    if (!lua_isnil(L, -1)) {
        event_context *p = Pevent(L, -1); 
        #if 0
        event_set(&p->ev, p->fd, EV_WRITE , Pevent_cb, p);
        event_add(&p->ev, ptv);  
        #endif
        p->want |= EV_WRITE;
    }
    lua_pop(L,2);
 }

 event_base_loop(libevent->base, flags);
 #if 1
 if (t >= 0.0) evtimer_del(&tout.ev);
 #endif
 return 2;
}

static void Pevent_close(lua_State *L)
{
 event_context *p = Pevent(L,1);

 if (p->open) {
    event_del(&p->ev);
    lua_rawgeti(L, LUA_REGISTRYINDEX, p->libevent->event_fd_map); 
    lua_pushinteger(L, p->ev.ev_fd);
    lua_pushnil(L);
    lua_settable(L,-3);
    lua_pop(L, 1);
 }
 p->open = 0;

}

static int Levent_gc(lua_State *L)
{
 Pevent_close(L);

 return 0;
}

static int Levent_close(lua_State *L)
{
 Pevent_close(L);

 return 0;
}

static int Levent(lua_State *L)
{
 const int fd = luaL_checkinteger(L, 1);
 double t = luaL_optnumber(L, 3, -1);
 event_context *p = lua_newuserdata(L,sizeof(event_context));
 struct timeval tv;

 if (t >= 0) {
    tv.tv_sec = (int) t;
    tv.tv_usec = (t - tv.tv_sec)*1000000;
 }
 p->libevent = &libevent_handle;
 event_set(&p->ev, fd, EV_READ | EV_WRITE | EV_PERSIST, Pevent_cb, p);
 #if 0
 event_set(&p->ev, fd, EV_READ | EV_WRITE | EV_PERSIST, Pevent_cb, p);
 event_set(&p->ev, fd, EV_READ , Pevent_cb, p);
 event_add(&p->ev, t < 0.0 ? NULL : &tv);
 #endif
 p->open = 1;
 p->fd = fd;

 luaL_getmetatable(L, MYEVENT);
 lua_setmetatable(L,-2);

 lua_rawgeti(L, LUA_REGISTRYINDEX, p->libevent->event_fd_map); 
 lua_pushinteger(L, fd);
 lua_pushvalue(L,2);
 lua_settable(L,-3);
 lua_pop(L, 1);

 return 1;
}

#endif

#ifdef EXPORT_HASH_FUNCTIONS
static int Lhash(lua_State *L)
{
 const char *type = luaL_checkstring(L,1);
 _LEN_TYPE klen;
 const unsigned char *key = luaL_optlstring(L, 2, NULL, &klen);
 hash_context *obj = lua_newuserdata(L,sizeof(hash_context));
 
 if (!klen) {
     if (memcmp(type,"md5",3)==0) {
        md5_starts(&obj->eng.md5);
        obj->id = MD5;
        obj->hash_size = 16;
        obj->starts = (hash_start_func) md5_starts;
        obj->update = (hash_update_func) md5_update;
        obj->finish = (hash_finish_func) md5_finish;
     } else if (memcmp(type,"sha1",4)==0) {
        sha1_starts(&obj->eng.sha1);
        obj->id = SHA1;
        obj->hash_size = 20;
        obj->starts = (hash_start_func) sha1_starts;
        obj->update = (hash_update_func) sha1_update;
        obj->finish = (hash_finish_func) sha1_finish;
#ifdef EXPORT_SHA2
     } else if (memcmp(type,"sha2",4)==0) {
        sha2_starts(&obj->eng.sha2,0);
        obj->id = SHA2;
        obj->hash_size = 32;
        obj->starts = (hash_start_func) sha2_starts;
        obj->update = (hash_update_func) sha2_update;
        obj->finish = (hash_finish_func) sha2_finish;
#endif
     } else {
        lua_pop(L, 1);
        luaL_error(L,"xyssl.hash: unknown hash function");
     }
 }
 else {
     if (memcmp(type,"hmac-md5",8)==0) {
        md5_hmac_starts(&obj->eng.md5, (unsigned char *)key, klen);
        obj->id = HMAC_MD5;
        obj->hash_size = 16;
        obj->starts = (hash_start_func) md5_starts;
        obj->update = (hash_update_func) md5_hmac_update;
        obj->finish = (hash_finish_func) md5_hmac_finish;
     } else if (memcmp(type,"hmac-sha1",9)==0) {
        sha1_hmac_starts(&obj->eng.sha1, (unsigned char *)key, klen);
        obj->id = HMAC_SHA1;
        obj->hash_size = 20;
        obj->starts = (hash_start_func) sha1_starts;
        obj->update = (hash_update_func) sha1_hmac_update;
        obj->finish = (hash_finish_func) sha1_hmac_finish;
#ifdef EXPORT_SHA2
     } else if (memcmp(type,"hmac-sha2",9)==0) {
        sha2_hmac_starts(&obj->eng.sha2, 0, (unsigned char *)key, klen);
        obj->id = HMAC_SHA2;
        obj->hash_size = 32;
        obj->starts = sha2_starts;
        obj->update = sha2_hmac_update;
        obj->finish = sha2_hmac_finish;
#endif
     } else {
        lua_pop(L, 1);
        luaL_error(L,"xyssl.hash: unknown hmac function");
     }
 }
 luaL_getmetatable(L,MYHASH);
 lua_setmetatable(L,-2);

 return 1;
}

static hash_context *Pget_hash(lua_State *L, int i)
{
 return lua_touserdata(L,i);
}

static dual_aes_context *Pget_aes(lua_State *L, int i)
{
 return lua_touserdata(L,i);
}

static arc4_context *Pget_rc4(lua_State *L, int i)
{
 return lua_touserdata(L,i);
}

static int Lhash_reset(lua_State *L)
{
 hash_context *obj=Pget_hash(L,1);
 obj->starts(&obj->eng);
 if (obj->id == HMAC_MD5) {
    char *inpad = obj->eng.md5.ipad;
    int len = sizeof(obj->eng.md5.ipad);
    obj->update(&obj->eng, inpad, len);
 }
 else if (obj->id == HMAC_SHA1) {
    char *inpad = obj->eng.sha1.ipad;
    int len = sizeof(obj->eng.sha1.ipad);
    obj->update(&obj->eng, inpad, len);
 } 
#ifdef EXPORT_SHA2
 else if (obj->id == HMAC_SHA2) {
    char *inpad = obj->eng.sha2.ipad;
    int len = sizeof(obj->eng.sha2.ipad);
    obj->update(&obj->eng, inpad, len);
 }
#endif

 lua_pushvalue(L, 1);
 return 1;
}

static int Laes_encrypt(lua_State *L)
{
 dual_aes_context *obj=Pget_aes(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 int i;
 luaL_Buffer B;

 if (len % 16) luaL_error(L,"xyssl.aes: data must be in 16 byte multiple");
 luaL_buffinit(L, &B);
 for(i = 0; i < len; i+=16) {
    unsigned char temp[16];

    aes_encrypt(&obj->enc, (unsigned char *)&data[i], temp);
    luaL_addlstring(&B, temp, 16);
 }
 luaL_pushresult(&B);

 return 1;
}

static int Laes_decrypt(lua_State *L)
{
 dual_aes_context *obj=Pget_aes(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 int i;
 luaL_Buffer B;

 if (len % 16) luaL_error(L,"xyssl.aes: data must be in 16 byte multiple");
 luaL_buffinit(L, &B);
 for(i = 0; i < len; i+=16) {
    unsigned char temp[16];

    aes_decrypt(&obj->dec, (unsigned char *)&data[i], temp);
    luaL_addlstring(&B, temp, 16);
 }
 luaL_pushresult(&B);

 return 1;
}

static int Lrc4_crypt(lua_State *L)
{
 arc4_context *obj=Pget_rc4(L,1);
 _LEN_TYPE len;
 const char *data = getbuffer(L, 2, &len);
 luaL_Buffer B;
 unsigned char temp[256];
 int t_size = sizeof(temp);
 int i;

 luaL_buffinit(L, &B);
 for(i = 0; i < len - t_size; i+=sizeof(temp)) {
    memcpy(temp, &data[i], sizeof(temp));
    arc4_crypt(obj, temp, sizeof(temp));
    luaL_addlstring(&B, temp, sizeof(temp));
 }
 if (i < len) {
    int j = len - i;
    memcpy(temp, &data[i], j);
    arc4_crypt(obj, temp, j);
    luaL_addlstring(&B, temp, j);
 }
 luaL_pushresult(&B);

 return 1;
}

static int Laes_cbc_encrypt(lua_State *L)
{
 dual_aes_context *obj=Pget_aes(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 _LEN_TYPE iv_len;
 const char *IV = luaL_checklstring(L, 3, &iv_len);
 int i=0;
 luaL_Buffer B;
 unsigned char iv[16];
 unsigned char temp[256];
 int t_size = sizeof(temp);

 if (len % 16) luaL_error(L,"xyssl.aes: data must be in 16 byte multiple");
 if (iv_len != 16) luaL_error(L,"xyssl.aes: IV must be 16 bytes");

 luaL_buffinit(L, &B);
 memcpy(iv, IV, 16);
 for(i = 0; i < len - t_size; i+=sizeof(temp)) {
    aes_cbc_encrypt(&obj->enc, iv, (unsigned char *)&data[i], temp, sizeof(temp));
    luaL_addlstring(&B, temp, sizeof(temp));
 }
 if (i < len) {
    aes_cbc_encrypt(&obj->enc, iv, (unsigned char *)&data[i], temp, len - i);
    luaL_addlstring(&B, temp, len - i);
 }
 luaL_pushresult(&B);
 lua_pushlstring(L,iv, 16);

 return 2;
}

static int Laes_cbc_decrypt(lua_State *L)
{
 dual_aes_context *obj=Pget_aes(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 _LEN_TYPE iv_len;
 const char *IV = luaL_checklstring(L, 3, &iv_len);
 int i;
 luaL_Buffer B;
 unsigned char iv[16];
 unsigned char temp[256];
 int t_size = sizeof(temp);

 if (len % 16) luaL_error(L,"xyssl.aes: data must be in 16 byte multiple");
 if (iv_len != 16) luaL_error(L,"xyssl.aes: IV must be 16 bytes");

 luaL_buffinit(L, &B);
 memcpy(iv, IV, 16);
 for(i = 0; i < len - t_size; i+=sizeof(temp)) {
    aes_cbc_decrypt(&obj->dec, iv, (unsigned char *)&data[i], temp, sizeof(temp));
    luaL_addlstring(&B, temp, sizeof(temp));
 }
 if (i < len) {
    aes_cbc_decrypt(&obj->dec, iv, (unsigned char *)&data[i], temp, len - i);
    luaL_addlstring(&B, temp, len - i);
 }
 luaL_pushresult(&B);
 lua_pushlstring(L,iv, 16);

 return 2;
}

static int Laes_cfb_encrypt(lua_State *L)
{
 dual_aes_context *obj=Pget_aes(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 _LEN_TYPE iv_len;
 const char *IV = luaL_checklstring(L, 3, &iv_len);
 int start = luaL_optinteger(L,4,0);
 int i;
 luaL_Buffer B;
 unsigned char iv[16];
 unsigned char temp[256];
 unsigned char *o;

 if (iv_len != 16) luaL_error(L,"xyssl.aes: IV must be 16 bytes");

 luaL_buffinit(L, &B);
 memcpy(iv, IV, 16);
 for(i = 0, o = temp; i < len; i++) {
    if (!start) aes_encrypt(&obj->enc, iv, iv);
    iv[start] = *o++ = data[i]^iv[start];
    start = (start + 1)%16;
    if (i%256==255) {
        luaL_addlstring(&B, temp, sizeof(temp));
        o = temp;
    }
 }
 if (o - temp) {
    luaL_addlstring(&B, temp, o - temp);
 }
 luaL_pushresult(&B);
 lua_pushlstring(L,iv, 16);
 lua_pushinteger(L,start);

 return 3;
}

static int Laes_cfb_decrypt(lua_State *L)
{
 dual_aes_context *obj=Pget_aes(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 _LEN_TYPE iv_len;
 const char *IV = luaL_checklstring(L, 3, &iv_len);
 int start = luaL_optinteger(L,4,0);
 int i;
 luaL_Buffer B;
 unsigned char iv[16];
 unsigned char temp[256];
 unsigned char *o;

 if (iv_len != 16) luaL_error(L,"xyssl.aes: IV must be 16 bytes");

 luaL_buffinit(L, &B);
 memcpy(iv, IV, 16);
 for(i = 0, o = temp; i < len; i++) {
    unsigned char c;
    if (!start) aes_encrypt(&obj->enc, iv, iv);
    c = data[i];
    *o++ = c^iv[start];
    iv[start] = c;
    start = (start + 1)%16;
    if (i%256==255) {
        luaL_addlstring(&B, temp, sizeof(temp));
        o = temp;
    }
 }
 if (o - temp) {
    luaL_addlstring(&B, temp, o - temp);
 }
 luaL_pushresult(&B);
 lua_pushlstring(L,iv, 16);
 lua_pushinteger(L,start);

 return 3;
}

static int Lhash_update(lua_State *L)
{
 hash_context *obj=Pget_hash(L,1);
 _LEN_TYPE len;
 const char *data = luaL_checklstring(L, 2, &len);
 obj->update(&obj->eng, (unsigned char *)data, len);
 lua_pushvalue(L, 1);

 return 1;
}

static int Lhash_digest(lua_State *L)
{
 hash_context *obj=Pget_hash(L,1);
 unsigned char out[64];
 _LEN_TYPE len;
 const char *data = luaL_optlstring(L, 2, "", &len);
 obj->update(&obj->eng, (unsigned char *)data, len);
 obj->finish(&obj->eng, out);
 
 lua_pushlstring(L,out, obj->hash_size);

 return 1;
}

#endif

static int Lsessions(lua_State *L)
{
     int cnt = luaL_optinteger(L,1,8);
     int now_size = malloc_sidtable ? malloc_sidtable : sizeof(default_session_table)/128;

     if (cnt < 8 || cnt > 65536) 
        luaL_error(L,"xyssl.sessions: sessions table entries must be within 8 and 65536");

    if (cnt != now_size) {
        unsigned char *new = malloc(cnt*128);
        if (!new) {
            lua_pushnil(L);
            lua_pushstring(L,"oom");
            return 2;
        }
        memcpy(new, session_table, (now_size > cnt ? cnt : now_size)*128);
        if (malloc_sidtable) {
            free(session_table);
        }
        session_table = new;
        malloc_sidtable = cnt;
    }
    lua_pushnumber(L, now_size);
    return 1;
}

static int Lprobe(lua_State *L)
{
 #ifndef _WIN32
 int fd = luaL_checkinteger(L,1);
 struct {
    char buf[1];
    struct msghdr msg;
    struct iovec iov;
 } msg;
 int ret;

 memset(&msg,0,sizeof(msg));

 msg.iov.iov_base = msg.buf;
 msg.iov.iov_len = sizeof(msg.buf);
 msg.msg.msg_iov = &msg.iov;
 msg.msg.msg_iovlen = 1;
 ret = sendmsg(fd, &msg.msg, 0);

 if (ret <= 0) {
    lua_pushnil(L);
    if (errno == EAGAIN || errno == EWOULDBLOCK) lua_pushstring(L,"timeout");
    else lua_pushstring(L,"closed");
    return 2;
 } else {
    lua_pushboolean(L, 1);
    return 1;
 }
 #else
    lua_pushboolean(L, 1);
    return 1;
 #endif
}

static int Lssl(lua_State *L)
{
 int ret;
 int is_server = luaL_optinteger(L,1,0);
 char *dhm_P = (char *)luaL_optstring(L, 2, default_dhm_P);
 char *dhm_G = (char *)luaL_optstring(L, 3, default_dhm_G);
 xyssl_context *xyssl=lua_newuserdata(L,sizeof(xyssl_context));
 ssl_context *ssl = &xyssl->ssl;

 memset(xyssl, 0, sizeof( xyssl_context) );
 xyssl->timeout = 0.1;
 xyssl->last_send_size = -1;

 
 luaL_getmetatable(L,MYTYPE);
 lua_setmetatable(L,-2);

 #ifdef XYSSL_POST_07
 ret = ssl_init(ssl);
 #if 0
 ssl_set_debuglvl(ssl, 3);
 #endif
 #else
 ret = ssl_init(ssl,is_server ? 0 : 1);
 #endif
 if (ret!= 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushnumber(L, ret);
    return 2;
 }

 ssl_set_endpoint( ssl, is_server ? SSL_IS_SERVER : SSL_IS_CLIENT );
 ssl_set_authmode( ssl, SSL_VERIFY_NONE );
 #ifdef XYSSL_POST_07
 ssl_set_session( ssl, 1, is_server ? 0: 600, &xyssl->ssn);
 #else
 #endif

 #if 0
 ssl_set_rng_func( ssl, havege_rand, &hs );
 #endif
 ssl_set_rng_func( ssl, arc4_rand, &arc4_stream );
 #if 0
 ssl_set_ciphlist( ssl, my_preferred_ciphers);
 #endif
 ssl_set_ciphlist( ssl, ssl_default_ciphers );

 if (is_server) {
 #ifndef XYSSL_POST_07
    ssl_set_sidtable( ssl, session_table );
    ssl_set_dhm_vals( ssl, dhm_P, dhm_G );
 #else
    ssl_set_scb(ssl, my_get_session, my_set_session);
    ssl_set_dh_param( ssl, xyssl->dhm_P ? xyssl->dhm_P : default_dhm_P, xyssl->dhm_G ? xyssl->dhm_G : default_dhm_G);
 #endif
    xyssl->dhm_P = malloc(strlen(dhm_P)+1);
    xyssl->dhm_G = malloc(strlen(dhm_G)+1);
    if (xyssl->dhm_P) strcpy(xyssl->dhm_P, dhm_P);
    if (xyssl->dhm_G) strcpy(xyssl->dhm_G, dhm_G);
 }
 return 1;
}

static int Lconnect(lua_State *L)			/** connect(read_fd[,write_fd]) */
{
 xyssl_context *xyssl=Pget(L,1);

 if (xyssl->closed) {
    int ret = Preset(L);
    if (ret) {
        lua_pushnil(L);
        lua_pushnumber(L, ret);
        return 2;
    }
 }
 xyssl->closed = 0;

 Psetfd(L);
 
 lua_pushnumber(L, 1);

 return 1;
}

static int Pclose(lua_State *L)			
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;

 ssl_close_notify( ssl );
 xyssl->closed = 1;
 #ifndef _WIN32
 if (xyssl->re_open) {
    close(xyssl->read_fd);
    if (xyssl->read_fd != xyssl->write_fd) {
        close(xyssl->write_fd);
    }
 }
 #endif
 return 0;
}

static int Lclose(lua_State *L)			/** close(c) */
{
 return Pclose(L);

}
static int Lsessinfo(lua_State *L)			/** sessinfo(c) */
{
 xyssl_context *xyssl=Pget(L,1);
 _LEN_TYPE id_len;
 char *sessid = (char *)luaL_optlstring(L, 2, NULL, &id_len);
 _LEN_TYPE master_len;
 char *master = (char *)luaL_optlstring(L, 3, NULL, &master_len);
 int cipher = luaL_optnumber(L,4,0);
 
 #ifndef XYSSL_POST_07
 ssl_context *ssl=&xyssl->ssl;
 lua_pushlstring(L,ssl->sessid, ssl->sidlen);
 lua_pushlstring(L,ssl->master, sizeof(ssl->master));
 if (sessid && master) {
    ssl->sidlen = id_len < sizeof(ssl->sessid) ? id_len : sizeof(ssl->sessid);
    memcpy(ssl->sessid, sessid, ssl->sidlen);
    memcpy(ssl->master, master, master_len < sizeof(ssl->master) ? master_len : sizeof(ssl->master));
 }
 return 2;
 #else
 lua_pushlstring(L,xyssl->ssn.id, xyssl->ssn.length);
 lua_pushlstring(L,xyssl->ssn.master, sizeof(xyssl->ssn.master));
 lua_pushnumber(L, xyssl->ssn.cipher);
 if (sessid && master && cipher > 0) {
    xyssl->ssn.cipher = cipher;
    xyssl->ssn.length = id_len < sizeof(xyssl->ssn.id) ? id_len : sizeof(xyssl->ssn.id);
    memcpy(xyssl->ssn.id, sessid, xyssl->ssn.length);
    memcpy(xyssl->ssn.master, master, master_len < sizeof(xyssl->ssn.master) ? master_len : sizeof(xyssl->ssn.master));
 }
 return 3;
 #endif
}

static int Lreset(lua_State *L)			/** reset(c) */
{
 int ret = Preset(L);
 if (ret) {
    lua_pushnil(L);
    lua_pushnumber(L, ret);
    return 2;
 }
 lua_pushnumber(L, 1);
 return 1;
}

static int Lsend(lua_State *L)		/** send(data) */
{
 int    top = lua_gettop(L);
 _LEN_TYPE size = 0, sent = 0;
 int err = 0;
 int l;
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 int pending = ssl->out_left;
 const char *data = luaL_checklstring(L, 2, &size);
 int start = luaL_optinteger(L,3,1);
 
 Current_LVM = L;

 if (xyssl->closed) {
    lua_pushnil(L);
    lua_pushstring(L,"closed");
    lua_pushnumber(L, 0);
    return 3;
 }
 if (start < 1) start = 1;

 #ifndef XYSSL_POST_07
 if (ssl->out_uoff && (size != xyssl->last_send_size || start-1 != ssl->out_uoff)) {
    luaL_error(L, "xyssl(send): partial send data in buffer(%i, must use data and return index+1 from previous send");
    }
 #else
 size = size - start + 1;
 #endif

 if (1) {
    /* always from start of buffer as it is memorized from last 
     * call
     */
    int tries;
    for (tries = 0; tries == 0 || (tries < 2 &&  ( xyssl->timeout > 0.0 && Pselect(xyssl->write_fd, 0, 1) > 0)); tries++) {
        err = ssl_write(ssl, (char *)data + start - 1, size
			
			
			); 
	#ifndef XYSSL_POST_07
        if (err) {
            xyssl->last_send_size = size;
            sent = ssl->out_uoff ? ssl->out_uoff : 0;
        } else {
            sent = size;
            xyssl->last_send_size = -1;
            }
	#else
	if (err > 0) {
	    xyssl->last_send_size = size;
	    sent = err;
	    err = 0;
	}
	#endif
        if (sent > 0 || err != ERR_NET_WOULD_BLOCK) break;
    }
 } else sent = 0;

 if (err!=0 || sent < size) {
    lua_pushnil(L);
    if (err == ERR_NET_WOULD_BLOCK ) lua_pushstring(L, "timeout");
    else if (err == ERR_NET_CONN_RESET) {
        lua_pushstring(L,"closed");
        xyssl->closed = 1;
    }
    else if (err == ERR_SSL_PEER_CLOSE_NOTIFY) {
        lua_pushstring(L,"nossl");
        xyssl->closed = 1;
        }
    else lua_pushstring(L, "handshake");
    #ifndef XYSSL_POST_07
    lua_pushnumber(L, start > sent ? start-1 : sent);
    #else
    lua_pushnumber(L, start + sent - 1);
    #endif
 } else {
    lua_pushnumber(L, sent);
    lua_pushnil(L);
    lua_pushnil(L);
 }

 return lua_gettop(L) - top;
}

static int Lreceive(lua_State *L)		/** receive(cnt) */
{
 int    top = lua_gettop(L);
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 _LEN_TYPE cnt = luaL_checknumber(L,2);
 _LEN_TYPE part_cnt;
 const char *part = luaL_optlstring(L, 3, NULL, &part_cnt);
 _LEN_TYPE len = 0;
 int    ret;
 char   *buf = malloc(cnt);
 luaL_Buffer B;

 Current_LVM = L;

 if (xyssl->closed) {
    if (buf) free(buf);
    lua_pushnil(L);
    lua_pushstring(L,"nossl");
    lua_pushstring(L, "");
    return 3;
 }
 if (buf) {
     int tries;
     for (tries = 0; tries == 0 || (tries < 2 &&  ( xyssl->timeout > 0.0 && Pselect(xyssl->read_fd, 0, 0) > 0)); tries++) {
        len = cnt;
	#ifndef XYSSL_POST_07
        ret = ssl_read(ssl, buf, &len );
        if (len > 0 || ret != ERR_NET_WOULD_BLOCK) break;
	#else
        ret = ssl_read(ssl, buf, len );
	if (ret > 0) {len = ret; ret = 0; break; }
        else if (ret != ERR_NET_WOULD_BLOCK) break;
	#endif
     } 

     if (ret==0) {
        luaL_buffinit(L, &B);
        luaL_addlstring(&B, part, part_cnt);
        luaL_addlstring(&B, buf, len);
        luaL_pushresult(&B);
        lua_pushnil(L);
        lua_pushnil(L);
     } else {
        lua_pushnil(L);
        if (ret == ERR_NET_WOULD_BLOCK ) lua_pushstring(L, "timeout");
        else if (ret == ERR_NET_CONN_RESET) {
            xyssl->closed = 1;
            lua_pushstring(L,"closed");
        }
        else if (ret == ERR_SSL_PEER_CLOSE_NOTIFY) {
            lua_pushstring(L,"nossl");
            xyssl->closed = 1;
            }
        else lua_pushstring(L,"handshake");
        
        luaL_buffinit(L, &B);
        if (part_cnt) luaL_addlstring(&B, part, part_cnt);
	#ifndef XYSSL_POST_07
        if (len) luaL_addlstring(&B, buf, len);
	#endif
        luaL_pushresult(&B);
    }
    free(buf);
 } else {
    lua_pushnil(L);
    lua_pushstring(L, "oom");
    lua_pushstring(L, "");
 }
 return lua_gettop(L) - top;
}

static int Lgc(lua_State *L)		/** garbage collect */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 x509_cert *cacert = &xyssl->cacert;
 x509_cert *mycert= &xyssl->mycert;
 rsa_context *rsa = &xyssl->mykey;
 int ret = Pclose(L);

 x509_free_cert( cacert );
 x509_free_cert( mycert );
 rsa_free( rsa );
 ssl_free(ssl);

 if (xyssl->peer_cn) {
    free(xyssl->peer_cn);
    xyssl->peer_cn = NULL;
 }
 if (xyssl->dhm_P) {
    free(xyssl->dhm_P);
    xyssl->dhm_P = NULL;
 }
 if (xyssl->dhm_G) {
    free(xyssl->dhm_G);
    xyssl->dhm_G = NULL;
 }

 return 0;
}

static int Lkeycert(lua_State *L)		/** set the key/cert to use */
{
 int    top = lua_gettop(L);

 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 x509_cert *cacert = &xyssl->cacert;
 x509_cert *mycert= &xyssl->mycert;
 rsa_context *rsa = &xyssl->mykey;
 _LEN_TYPE ca_len;
 const char *ca = luaL_optlstring(L, 2, test_ca_crt , &ca_len);
 _LEN_TYPE cert_len;
 const char *cert = luaL_optlstring(L, 3, ssl->endpoint ? test_srv_crt: NULL, &cert_len);
 _LEN_TYPE key_len;
 const char *key = luaL_optlstring(L, 4, ssl->endpoint ? test_srv_key: NULL, &key_len);
 _LEN_TYPE pwd_len;
 const char *pwd = luaL_optlstring(L, 5, NULL, &pwd_len);
 int ret;

 ret = x509_add_certs( cacert, (unsigned char *) ca, ca_len);
 if (ret) {
    lua_pushnil(L);
    lua_pushstring(L,"bad ca");
    lua_pushnumber(L, ret);
    goto exit;
 }
 if (cert) ret = x509_add_certs( mycert, (unsigned char *) cert,cert_len );
 if (ret) {
    lua_pushnil(L);
    lua_pushstring(L,"bad cert");
    lua_pushnumber(L, ret);
    goto free_ca;
 }
 if (key) ret = x509_parse_key(rsa, (unsigned char *) key, key_len, (unsigned char *)pwd, pwd_len);
 if (ret) {
    lua_pushnil(L);
    lua_pushstring(L,"bad rsa key/pwd");
    lua_pushnumber(L, ret);
    goto free_key;
 }

 ssl_set_ca_chain( ssl, cacert, xyssl->peer_cn );
 if (cert) ssl_set_rsa_cert( ssl, mycert, rsa );
 lua_pushnumber(L, 1);
 goto exit;
 
free_key:
 rsa_free( rsa );

free_cert:
 x509_free_cert( mycert );

free_ca:
 x509_free_cert( cacert );
 
exit:

 return lua_gettop(L) - top;
}

static int Lgetfd(lua_State *L)		/** getfd */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 lua_pushnumber(L, xyssl->read_fd);
 lua_pushnumber(L, xyssl->write_fd);
 return 2;
}

static int Lsetfd(lua_State *L)		/** setfd(r[,w]) */
{
 Psetfd(L);
 lua_pushnumber(L, 1);
 return 1;
}

static int Lauthmode(lua_State *L)		/** authmode(level) */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 int verification = luaL_optinteger(L,2,0);
 _LEN_TYPE peer_len;
 const char *expected_peer= luaL_optlstring(L, 3, NULL, &peer_len);
 ssl_set_authmode( ssl, verification );
 if (xyssl->peer_cn) free(xyssl->peer_cn);
 if (expected_peer) {
    xyssl->peer_cn = malloc(peer_len+1);
    memcpy(xyssl->peer_cn, expected_peer, peer_len);
    xyssl->peer_cn[peer_len]='\0';
 } else {
    xyssl->peer_cn = NULL;
 }
 if (ssl->ca_chain) ssl_set_ca_chain( ssl, ssl->ca_chain, xyssl->peer_cn );

 return 0;
}

static int Lhandshake(lua_State *L)		/** handshake() */
{
 int ret;
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;

 Current_LVM = L;

 if (1 || xyssl->timeout <= 0.0 || (ret = Pselect(xyssl->write_fd, xyssl->timeout, 1)) > 0) {
     ret = ssl_handshake( ssl );
 } 
 lua_pushnumber(L, ret);

 return 1;
}

static int Lverify(lua_State *L)		/** verify() */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 int ret = ssl_get_verify_result ( ssl );

 lua_pushnumber(L, ret);

 return 1;
}

static int Lpeer(lua_State *L)		/** peer() */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 if (ssl->peer_cert) {
     #ifndef XYSSL_POST_07
     char *info = x509_cert_info ( ssl->peer_cert );
     #else
     char *info = x509parse_cert_info ( "",ssl->peer_cert );
     #endif

     if (info) {
        lua_pushstring(L,info);
        free(info);
     } else lua_pushnil(L);
 } else lua_pushnil(L);

 return 1;
}

static int Lcipher_info(lua_State *L)		/** cipher_info() */
{
 xyssl_context *xyssl=Pget(L,1);
 #ifndef XYSSL_POST_07
 ssl_context *ssl=&xyssl->ssl;
 char *cipher_choosen = ssl_get_cipher_name(ssl);
 #else
 char *cipher_choosen = NULL;
 #endif
 if (cipher_choosen) {
    lua_pushstring(L,cipher_choosen);
 } else lua_pushnil(L);

 return 1;
}

static int Lname(lua_State *L)		/** name() */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 if (ssl->own_cert) {
     #ifndef XYSSL_POST_07
     char *info = x509_cert_info ( ssl->own_cert );
     #else
     char *info = x509parse_cert_info ( "",ssl->own_cert );
     #endif

     if (info) {
        lua_pushstring(L,info);
        free(info);
     } else lua_pushnil(L);
 }
 else lua_pushnil(L);

 return 1;
}

static int Lsettimeout(lua_State *L) /** settimeout(sec) **/
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl = &xyssl->ssl;
 double t = luaL_optnumber(L, 2, -1);
 lua_pushnumber(L,xyssl->timeout);
 xyssl->timeout = t;
 if (t < 0.0) {
     net_set_block(xyssl->read_fd);
     net_set_block(xyssl->write_fd);
 } else {
     net_set_nonblock(xyssl->read_fd);
     net_set_nonblock(xyssl->write_fd);
 }
 return 1;
}

static int Ldirty(lua_State *L)		/** dirty() */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 int dirty = ssl->in_offt != NULL || xyssl->closed;
 lua_pushboolean(L, dirty);
 return 1;
}

static int Ledh(lua_State *L)		/** edh() */
{
 xyssl_context *xyssl=Pget(L,1);
 int edh = luaL_optinteger(L,2,0);
 ssl_context *ssl=&xyssl->ssl;
 if (edh) ssl_set_ciphlist( ssl, ssl_default_ciphers );
 return 0;
}

static int Ltostring(lua_State *L)		/** tostring(c) */
{
 xyssl_context *xyssl=Pget(L,1);
 ssl_context *ssl=&xyssl->ssl;
 char s[64];
 sprintf(s,"%s %p",MYTYPE,ssl);
 lua_pushstring(L,s);
 return 1;
}

static int Lrand(lua_State *L)		/** rand(bytes) */
{
 luaL_Buffer B;
 int cnt = luaL_optnumber(L,1,1);
 int i;
 int rem;
 unsigned char buf[256];
 unsigned char *o = buf;

 luaL_buffinit(L, &B);
 for (i = 0; i < cnt; i++) {
    *o++ = havege_rand(&hs);
    if (i % 256 == 255) {
        luaL_addlstring(&B, buf, 256);
        o = buf;
    }
 }
 rem = i % 256;
 if (rem) luaL_addlstring(&B, buf, rem);
 luaL_pushresult(&B);

 return 1;
}

static const luaL_Reg R[] =
{
	{ "__tostring",	Ltostring},
	{ "write",  Lsend	},
	{ "send",	Lsend	},
	{ "read",	Lreceive	},
	{ "receive",Lreceive	},
	{ "__gc",	Lgc	},
	{ "close",	Lclose},
	{ "reset",	Lreset},
	{ "getfd",	Lgetfd},
	{ "setfd",	Lsetfd},
	{ "dirty",Ldirty},
	{ "edh",Ledh},
    { "sessinfo",Lsessinfo },
	{ "handshake",Lhandshake},
	{ "authmode",	Lauthmode},
	{ "verify",	Lverify},
	{ "peer",	Lpeer},
	{ "cipher",	Lcipher_info},
	{ "name",	Lname},
	{ "settimeout",	Lsettimeout},
	{ "keycert",Lkeycert},
	{ "connect",	Lconnect	},
	{ NULL,		NULL	}
};

#ifdef EXPORT_HASH_FUNCTIONS
static const luaL_Reg Rhash[] = 
{
	{ "update",	Lhash_update},
	{ "digest",	Lhash_digest},
	{ "reset",	Lhash_reset},
	{ NULL,		NULL	}
};
#endif

static const luaL_Reg Raes[] = 
{
    { "encrypt", Laes_encrypt},
    { "decrypt", Laes_decrypt},
    { "cbc_encrypt", Laes_cbc_encrypt},
    { "cbc_decrypt", Laes_cbc_decrypt},
    { "cfb_encrypt", Laes_cfb_encrypt},
    { "cfb_decrypt", Laes_cfb_decrypt},
	{ NULL,		NULL	}
};

static const luaL_Reg Rrc4[] = 
{
    { "crypt", Lrc4_crypt},
	{ NULL,		NULL	}
};

static const luaL_Reg Rm[] = {
	{ "ssl",	Lssl	},
#ifdef USE_LIBEVENT
	{ "event",  Levent	},
	{ "ev_select", Levent_select},
#endif
	{ "probe",	Lprobe	},
	{ "sessions",	Lsessions},
	{ "rand",	Lrand	},
	{ "aes",	Laes	},
	{ "rc4",	Lrc4	},
#ifdef EXPORT_HASH_FUNCTIONS
	{ "hash",	Lhash	},
#endif
	{ NULL,		NULL	}
};

#ifdef USE_LIBEVENT
static const luaL_Reg Revent[] = {
	{ "__gc",	Levent_gc	},
	{ "close",  Levent_close},
	{ NULL,		NULL	},
};
#endif

int luaopen_lxyssl(lua_State *L)
{
 unsigned char random_bits[256];
 int i;

 havege_init( &hs );

 for (i=0; i < sizeof(random_bits); i++) random_bits[i] = havege_rand(&hs);
 arc4_setup(&arc4_stream, random_bits, sizeof(random_bits));

 for (i=0; i < 4; i++) 
    arc4_crypt(&arc4_stream, random_bits, sizeof(random_bits));

 luaL_newmetatable(L,MYTYPE);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 #ifndef XYSSL_POST_07
 lua_pushliteral(L,"buffered_write");
 lua_pushnumber(L,1);
 lua_settable(L,-3);
 #endif
 luaL_newlibtable(L,R);
 luaL_setfuncs(L, R, 1);

#ifdef EXPORT_HASH_FUNCTIONS
 luaL_newmetatable(L,MYHASH);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 luaL_newlibtable(L,Rhash);
 luaL_setfuncs(L, Rhash, 1);
#endif

 luaL_newmetatable(L,MYAES);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 luaL_newlibtable(L,Raes);
 luaL_setfuncs(L, Raes, 0);

 luaL_newmetatable(L,MYRC4);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 luaL_newlibtable(L,Rrc4);
 luaL_setfuncs(L, Rrc4, 1);
 #if 0
 lua_pushliteral (L, "__metatable");
 lua_pushliteral (L, MYTYPE" you're not allowed to get this metatable");
 lua_settable (L, -3);
 #endif

#ifdef USE_LIBEVENT
{
 struct event_base *base;

 luaL_newmetatable(L,MYEVENT);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 luaL_newlibtable(L,Revent);
 luaL_setfuncs(L, Revent, 1);

 base = event_init();
 if (!base) {
    luaL_error(L,"luaevent: failed to allocate libevent base");
 }
 libevent_handle.base = base;

 lua_newtable(L); /* fdmap */
 lua_newtable(L); /* fdmap metatable {__mode="kv"} */
 lua_pushliteral(L,"__mode");
 lua_pushstring(L,"kv");
 lua_settable(L,-3);
 lua_setmetatable(L, -2);

 libevent_handle.event_fd_map = luaL_ref(L, LUA_REGISTRYINDEX);
 libevent_handle.L = L;
}
#endif

 lua_newtable(L); /* sessions */
 lua_newtable(L); /* sessions metatable {__mode="kv"} */
 lua_pushliteral(L,"__mode");
 lua_pushstring(L,"kv");
 lua_settable(L,-3);
 lua_setmetatable(L, -2);
 session_table_idx = luaL_ref(L, LUA_REGISTRYINDEX);

 luaL_newlibtable(L,Rm);
 luaL_setfuncs(L, Rm, 0);

 lua_pushliteral(L,"version");			/** version */
 lua_pushliteral(L,MYVERSION);
 lua_settable(L,-3);

 return 1;
}
