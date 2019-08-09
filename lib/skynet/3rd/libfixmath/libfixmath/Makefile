
include ../../../platform.mk

PLAT= none

LUA_VERSION = 5.3
TARGET =  ../../../luaclib/fixmath.so

ifeq ($(PLAT), macosx)
	CFLAGS =  -g -O2 -pedantic -bundle -undefined dynamic_lookup 
else
ifeq ($(PLAT), linux)
	CFLAGS = -g -O2 -shared -fPIC
endif
endif

LUA_STATICLIB := ../../lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= ../../lua


FIXMATH_INC ?= .
SRC = .
BUILD_CFLAGS = $(CFLAGS) -I$(LUA_INC) -I$(FIXMATH_INC)

.PHONY: all clean

all: $(TARGET)
		 

$(TARGET): $(foreach dir, $(SRC), $(wildcard $(dir)/*.c))
	$(CC) $(BUILD_CFLAGS) -o $@ $^ 

clean:
	rm -f *.o $(TARGET)