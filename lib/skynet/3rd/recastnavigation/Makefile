
include ../../platform.mk

PLAT= none

LUA_VERSION = 5.3
TARGET =  ../../luaclib/navigator.so

ifeq ($(PLAT), macosx)
	CFLAGS =  -g -O2 -pedantic -bundle -undefined dynamic_lookup 
else
ifeq ($(PLAT), linux)
	CFLAGS = -g -O2 -shared -fPIC
endif
endif

LUA_STATICLIB := ../lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= ../lua


DETOUR_INC ?= ./Detour/Include
RECAST_INC ?= ./Recast/Include

BUILD_CFLAGS = $(CFLAGS) -I$(LUA_INC) -I$(RECAST_INC) -I$(DETOUR_INC) 

DETOUR_SRC = DetourAlloc.cpp DetourCommon.cpp DetourNavMesh.cpp DetourNavMeshBuilder.cpp \
							DetourNavMeshBuilder.cpp  DetourNavMeshQuery.cpp DetourNode.cpp\

RECAST_SRC = Recast.cpp RecastAlloc.cpp RecastArea.cpp RecastContour.cpp RecastFilter.cpp RecastLayers.cpp\
							RecastMesh.cpp RecastMeshDetail.cpp RecastRasterization.cpp RecastRegion.cpp

UTIL_SRC = Navigator.cpp LRecastNavigation.cpp

.PHONY: all clean

all: $(TARGET)
		 

$(TARGET): $(foreach v, $(DETOUR_SRC), Detour/Source/$(v)) \
					 $(foreach v, $(RECAST_SRC), Recast/Source/$(v)) \
					 $(foreach v, $(UTIL_SRC), $(v))
	$(CC) $(BUILD_CFLAGS) -o $@ $^ 

clean:
	rm -f *.o $(TARGET)