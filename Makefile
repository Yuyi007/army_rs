
all: egg

egg:
	cd lib/egg_c_src && make all

clean:
	cd lib/egg_c_src && make clean

.PHONY: all egg clean