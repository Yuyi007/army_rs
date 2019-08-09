include platform.mk

LUA_CLIB_PATH ?= luaclib
CSERVICE_PATH ?= cservice

SKYNET_BUILD_PATH ?= .

DBG_FLAGS= -g3 -Og #-g -O2

CFLAGS = -m64  -Wall -I$(LUA_INC) $(MYCFLAGS) $(DBG_FLAGS)
# CFLAGS += -DUSE_PTHREAD_LOCK
CPPFLAGS = -m64  -Wall -I$(LUA_INC) $(MYCFLAGS) $(DBG_FLAGS)

# lua

LUA_STATICLIB := ./3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= ./3rd/lua

$(LUA_STATICLIB) :
	cd ./3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)

# jemalloc 

JEMALLOC_STATICLIB := ./3rd/jemalloc/lib/libjemalloc_pic.a
JEMALLOC_INC := ./3rd/jemalloc/include/jemalloc

all : jemalloc
	
.PHONY : jemalloc

MALLOC_STATICLIB := $(JEMALLOC_STATICLIB)

$(JEMALLOC_STATICLIB) : 3rd/jemalloc/Makefile
	cd ./3rd/jemalloc && $(MAKE) CC=$(CC) 


3rd/jemalloc/autogen.sh :
	git submodule update --init

3rd/jemalloc/Makefile : 3rd/jemalloc/autogen.sh
	cd ./3rd/jemalloc && ./autogen.sh --with-jemalloc-prefix=je_ --disable-valgrind

jemalloc : $(MALLOC_STATICLIB)

#cjson
$(LUA_CLIB_PATH)/cjson.so : 3rd/lua-cjson/Makefile
	cd ./3rd/lua-cjson && $(MAKE) clean && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT) && $(MAKE) install

all : $(LUA_CLIB_PATH)/cjson.so

#fcgi
fcgi : 
	cd fcgi && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)

all : fcgi

#navigation
$(LUA_CLIB_PATH)/navigator.so : 3rd/recastnavigation/Makefile $(LUA_LIB)
	cd ./3rd/recastnavigation && $(MAKE) clean && $(MAKE)

all : $(LUA_CLIB_PATH)/navigator.so

#libfixmath
$(LUA_CLIB_PATH)/fixmath.so : 3rd/libfixmath/libfixmath/Makefile $(LUA_LIB)
	cd ./3rd/libfixmath/libfixmath && $(MAKE)

all : $(LUA_CLIB_PATH)/fixmath.so

# skynet

CSERVICE = snlua logger gate harbor syslogger

LUA_CLIB = skynet  bson md5 client sproto lpeg \
    			 llogger luasocket lxyssl lfcgi aoi lfractor cmsgpack \
    			 lfs lkcp lsyslog

LUA_CLIB_SKYNET = \
  lua-skynet.c lua-seri.c \
  lua-socket.c \
  lua-mongo.c \
  lua-netpack.c \
  lua-memory.c \
  lua-profile.c \
  lua-multicast.c \
  lua-cluster.c \
  lua-crypt.c lsha1.c \
  lua-sharedata.c \
  lua-stm.c \
  lua-mysqlaux.c \
  lua-debugchannel.c \
  lua-datasheet.c \
  \

SKYNET_SRC = skynet_main.c skynet_handle.c skynet_module.c skynet_mq.c \
  skynet_server.c skynet_start.c skynet_timer.c skynet_error.c skynet_syslog.c\
  skynet_harbor.c skynet_env.c skynet_monitor.c skynet_socket.c socket_server.c \
  malloc_hook.c skynet_daemon.c skynet_log.c

all : \
  $(SKYNET_BUILD_PATH)/skynet \
  $(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(SKYNET_BUILD_PATH)/skynet : $(foreach v, $(SKYNET_SRC), skynet-src/$(v)) $(LUA_LIB) $(MALLOC_STATICLIB)
	$(CC) $(CFLAGS) -o $@ $^ -Iskynet-src -I$(JEMALLOC_INC) $(LDFLAGS) $(EXPORT) $(SKYNET_LIBS) $(SKYNET_DEFINES)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

define CSERVICE_TEMP
  $$(CSERVICE_PATH)/$(1).so : service-src/service_$(1).c | $$(CSERVICE_PATH)
	$$(CC) $$(CFLAGS) $$(SHARED) $$< -o $$@ -Iskynet-src
endef

$(foreach v, $(CSERVICE), $(eval $(call CSERVICE_TEMP,$(v))))

$(LUA_CLIB_PATH)/skynet.so : $(addprefix lualib-src/,$(LUA_CLIB_SKYNET)) | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -Iskynet-src -Iservice-src -Ilualib-src

$(LUA_CLIB_PATH)/bson.so : lualib-src/lua-bson.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Iskynet-src $^ -o $@ -Iskynet-src

$(LUA_CLIB_PATH)/md5.so : 3rd/lua-md5/md5.c 3rd/lua-md5/md5lib.c 3rd/lua-md5/compat-5.2.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-md5 $^ -o $@ 

$(LUA_CLIB_PATH)/client.so : lualib-src/lua-clientsocket.c lualib-src/lua-crypt.c lualib-src/lsha1.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/sproto.so : lualib-src/sproto/sproto.c lualib-src/sproto/lsproto.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/sproto $^ -o $@ 

$(LUA_CLIB_PATH)/lpeg.so : 3rd/lpeg/lpcap.c 3rd/lpeg/lpcode.c 3rd/lpeg/lpprint.c 3rd/lpeg/lptree.c 3rd/lpeg/lpvm.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lpeg $^ -o $@ 


LXYSSL_SRC = aes.c arc4.c base64.c bignum.c certs.c debug.c des.c dhm.c havege.c md2.c \
						 md4.c md5.c net.c padlock.c rsa.c sha1.c sha2.c sha4.c ssl_cli.c ssl_srv.c \
						 ssl_tls.c timing.c x509parse.c lxyssl.c
$(LUA_CLIB_PATH)/lxyssl.so : $(foreach v, $(LXYSSL_SRC), lualib-src/lxyssl/$(v)) | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/lxyssl $^ -o $@	

$(LUA_CLIB_PATH)/lfcgi.so : lualib-src/fcgi/lfcgi.c lualib-src/fcgi/fcgi_stdio.c lualib-src/fcgi/fcgiapp.c lualib-src/fcgi/fcgio.cpp lualib-src/fcgi/os_unix.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/llogger.so : lualib-src/logger/lua-logger.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Iskynet-src $^ -o $@

$(LUA_CLIB_PATH)/aoi.so : lualib-src/aoi/lua-aoi.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Iskynet-src $^ -o $@

FRACTOR_SRC = acos_table.cpp atan2_table.cpp sincos_table.cpp fractor.cpp lfractor.cpp
$(LUA_CLIB_PATH)/lfractor.so : $(foreach v, $(FRACTOR_SRC), lualib-src/libfractor/$(v)) | $(LUA_CLIB_PATH)
	$(CXX) $(CPPFLAGS) $(SHARED) -Ilualib-src/libfractor $^ -o $@	
	
$(LUA_CLIB_PATH)/cmsgpack.so : lualib-src/msgpack/lua-cmsgpack.c | $(LUA_CLIB_PATH)
	$(CXX) $(CPPFLAGS) $(SHARED) -Ilualib-src/libfractor -Iskynet-src $^ -o $@

LUASOCKET_SRC = luasocket.c timeout.c buffer.c io.c auxiliar.c options.c \
								inet.c tcp.c udp.c except.c select.c usocket.c
$(LUA_CLIB_PATH)/luasocket.so : $(foreach v, $(LUASOCKET_SRC), lualib-src/luasocket/$(v)) | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/luasocket $^ -o $@

$(LUA_CLIB_PATH)/lfs.so : 3rd/luafilesystem/lfs.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/lkcp.so : lualib-src/kcp/ikcp.c lualib-src/kcp/lkcp.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/lsyslog.so : 3rd/lua-syslog/lua-syslog.c  | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

clean :
	rm -f $(SKYNET_BUILD_PATH)/skynet $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so

cleanall: clean
ifneq (,$(wildcard 3rd/jemalloc/Makefile))
	cd ./3rd/jemalloc && $(MAKE) clean
endif
	cd ./3rd/lua && $(MAKE) clean
	rm -f $(LUA_STATICLIB)
	cd fcgi && $(MAKE) clean

