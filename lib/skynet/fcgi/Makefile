include ../platform.mk
PLAT= none

LUA_CLIB_PATH ?= luaclib

LUA_STATICLIB := ../3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= ../3rd/lua

default: $(PLAT)

all: $(LUA_STATICLIB)\
			fvfcgi\

$(LUA_STATICLIB):
	cd ../3rd/lua && $(MAKE) CC='$(CC) -std=gnu99' $(PLAT)

CFLAGS = -g -O2 -Wall
ifeq ($(PLAT), linux)
	CFLAGS =  -g -O2 -lm -Wl,-E -ldl
endif

fvfcgi: main.c $(LUA_LIB)
	$(CC) $(CFLAGS) -I$(LUA_INC) -o $@ $^ $(LDFLAGS) $(EXPORT)

clean: rm -rf fvfcgi.dSYM\
	rm -f fvfcgi
