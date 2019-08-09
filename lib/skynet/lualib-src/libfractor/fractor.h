#ifndef __FRACTOR_H
#define __FRACTOR_H
#include <stdint.h>
#include <math.h>

#define FRACTOR_PRECISION = 4

class Fractor
{
public:
	int64_t nom;
	int64_t den;

public:
	Fractor();
	Fractor(const Fractor &other);
	Fractor(int n, int d);
	Fractor(int64_t n, int64_t d);
	Fractor(int n);
	Fractor(float d);
	Fractor(double f);

	void from_double(double d);
	void from_int(int n);

	static Fractor one;
	static Fractor zero;
	static Fractor two;
	static Fractor half;
	static Fractor ten;
	static Fractor f180;

	static Fractor pi;
	static Fractor half_pi;
	static Fractor quat_pi;
	static Fractor two_pi;
	static Fractor rad_deg_unit;
	static Fractor deg_rad_unit;
	static Fractor e;

	static Fractor max;
	static Fractor min;

	static int64_t mask;
	static int64_t upper;
	
	operator int() const;
	operator float() const;
	operator double() const;
	operator int64_t() const;

	Fractor& operator = (const Fractor &b);
	Fractor& operator = (const int b);
	Fractor& operator = (const float f);
	Fractor& operator = (const double d);
	Fractor& operator = (const int64_t b);

	bool operator < (const Fractor &b)  const;
	bool operator > (const Fractor &b)  const;
	bool operator <= (const Fractor &b)  const;
	bool operator >= (const Fractor &b)  const;
	bool operator == (const Fractor &b)  const;
	bool operator != (const Fractor &b)  const;

	bool operator < (const int64_t b) const;
	bool operator > (const int64_t b) const;
	bool operator <= (const int64_t b) const;
	bool operator >= (const int64_t b) const;
	bool operator == (const int64_t b) const;
	bool operator != (const int64_t b) const;

	Fractor operator + (const Fractor &b)  const;
	Fractor operator - (const Fractor &b)  const;
	Fractor operator * (const Fractor &b)  const;
	Fractor operator / (const Fractor &b)  const;

	Fractor operator + (const int64_t b) const;
	Fractor operator - (const int64_t b) const;
	Fractor operator * (const int64_t b) const;
	Fractor operator / (const int64_t b) const;

	Fractor& operator += (const Fractor &b);
	Fractor& operator -= (const Fractor &b);
	Fractor& operator *= (const Fractor &b);
	Fractor& operator /= (const Fractor &b);

	Fractor& operator += (const int64_t b);
	Fractor& operator -= (const int64_t b);
	Fractor& operator *= (const int64_t b);
	Fractor& operator /= (const int64_t b);

	Fractor operator-(void) const;


public:
	Fractor invserse();
	bool isPositive() const;
	bool isNegative() const;

	int round() const;
	int to_i() const;
	long to_l() const;
	float to_f() const;
	double to_d() const;
	void cstr(char* psz);
	void strip();

	Fractor sqrtf();
	Fractor absf();
	Fractor sinf();
	Fractor cosf();
	Fractor tanf();
	Fractor asinf();
	Fractor acosf();
	Fractor expf();
	Fractor lnf();
	Fractor logf();
	Fractor to_rad() const;
	Fractor to_deg() const;

public:
	static bool positive(int64_t nom, int64_t den);
	static bool negative(int64_t nom, int64_t den);

	static void cstrf(const Fractor &x, char *psz);
	static Fractor atanf(const Fractor &x);
	static Fractor atan2f(const Fractor &y, const Fractor &x);
	static Fractor asinf(const Fractor &x);
	static Fractor acosf(const Fractor &f);
	static Fractor sinf(const Fractor &f);
	static Fractor cosf(const Fractor &f);
	static Fractor tanf(const Fractor &f);

	static Fractor rad_to_deg(const Fractor &rad);
	static Fractor deg_to_rad(const Fractor &deg);

	
	static Fractor atan2f(int y, int x);
	static Fractor acosf(int64_t nom, int64_t den);
	static Fractor sinf(int64_t nom, int64_t den);
	static Fractor cosf(int64_t nom, int64_t den);
	static Fractor tanf(int64_t nom, int64_t den);
	static Fractor absf(const Fractor &x);

	static Fractor powf(const Fractor &num, const Fractor &m);
	static Fractor sqrtf(const Fractor &x);
	static Fractor expf(const Fractor &x);
	static Fractor modf(const Fractor &x, const Fractor &y);
	static Fractor logf(const Fractor &x);
	static Fractor lnf(const Fractor &x);

	//static Fractor Fractor::coef(const int n);
	//static Fractor Fractor::horner(const Fractor &x);
	//static Fractor Fractor::sqrt(const Fractor &b);
	//static Fractor Fractor::ln(const Fractor &x);
	//static Fractor Fractor::log(const Fractor &m, const Fractor &base = Fractor::ten);
	//static Fractor Fractor::exp(const Fractor &x);
	//static Fractor Fractor::pow(const Fractor &m, const Fractor &n);

	static int64_t div64(int64_t a, int64_t b);
	static int	div32(int a, int b);

	static unsigned int		sqrt32(unsigned int a);
	static uint64_t	sqrt64(uint64_t a);
	static int	sqrtInt(uint64_t a);
	static int64_t	sqrtLong(uint64_t a);
	
	static int64_t clamp(int64_t a, int64_t min, int64_t max);
	
	static int	lerpInt(int src, int dst, int nom, int den);
	static int64_t lerpLong(int64_t src, int64_t dst, int64_t nom, int64_t den);

	static uint64_t gcb(uint64_t a, uint64_t b);

};


#endif
