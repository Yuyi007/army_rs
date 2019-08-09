#ifndef __SINCOS_TABLE_H
#define __SINCOS_TABLE_H

class SincosTable
{
public:
	static int BITS;
	static int MASK;
	static int COUNT;
	static int FACTOR;
	static int NOM_MUL;
	static int sin_table[4096];
	static int cos_table[4096];
	static int getIndex(int64_t nom, int64_t den);
};

#endif
