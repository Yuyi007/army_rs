#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>

#include "fractor.h"
#include "atan2_table.h"
#include "acos_table.h"
#include "sincos_table.h"
#ifdef DEBUG_CALL_LUA
#include "race/lcall.h"
#endif

#define LLMAX 9223372036854775807LL
#define LLMIN (-9223372036854775807LL - 1)
#define llabs(x) (x>0?x:-x)

Fractor Fractor::one = Fractor(1, 1);
Fractor Fractor::zero = Fractor(0, 1);
Fractor Fractor::half = Fractor(1, 2);
Fractor Fractor::two = Fractor(2, 1);
Fractor Fractor::ten = Fractor(10, 1);

Fractor Fractor::pi = Fractor((int64_t)31416LL, (int64_t)10000LL);
Fractor Fractor::half_pi = Fractor((int64_t)15708LL, (int64_t)10000LL);
Fractor Fractor::quat_pi = Fractor((int64_t)7854LL, (int64_t)10000LL);
Fractor Fractor::two_pi = Fractor((int64_t)62832LL, (int64_t)10000LL);

Fractor Fractor::max = Fractor(LLMAX, (int64_t)1LL);
Fractor Fractor::min = Fractor(LLMIN, (int64_t)1LL);

Fractor Fractor::f180 = Fractor((int64_t)180LL, (int64_t)1LL);


Fractor Fractor::rad_deg_unit = Fractor::pi / Fractor::f180;
Fractor Fractor::deg_rad_unit = Fractor::f180/ Fractor::pi;
	
Fractor Fractor::e = Fractor(2.71828f);

int64_t Fractor::mask = LLMAX;
int64_t Fractor::upper = (int64_t)10000LL;// 16777215LL;

Fractor::Fractor()
	:nom(0)
	,den(1)
{}

Fractor::Fractor(const Fractor &other)
	:nom(other.nom)
	,den(other.den)
{}

Fractor::Fractor(int64_t n, int64_t d)
	: nom(n)
	, den(d)
{}

Fractor::Fractor(int n, int d)
	: nom(n)
	, den(d)

{}

Fractor::Fractor(int n)
	:nom(n)
	,den(1)
{}


Fractor::Fractor(float f)
{
	if (f >= -0.0000001f && f <= 0.0000001f)
	{
		nom = 0;
		den = 1;
		return;
	}

	den = (int64_t)10000LL;// pow(10, FRACTOR_PRECISION);
	nom = (int64_t)(f * den);

	strip();
}

Fractor::Fractor(double d)
{
	from_double(d);
}

void Fractor::from_double(double d)
{
	if (d >= -0.0000001f && d <= 0.0000001f)
	{
		nom = (int64_t)0LL;
		den = (int64_t)1LL;
		return;
	}

	den = (int64_t)10000LL;// pow(10, FRACTOR_PRECISION);
	nom = (int64_t)(d * den);

	strip();
}

void Fractor::from_int(int n)
{
	nom = n;
	den = 1;
}

uint64_t Fractor::gcb(uint64_t a, uint64_t b)
{
	// make sure a < b
	if (a > b)
	{
		uint64_t temp = a;
		a = b;
		b = temp;
	}

	uint64_t r = b % a;
	while (r != 0)
	{
		b = a;
		a = r;
		r = b % a;
	}

	return a;
}


Fractor::operator int() const
{
	return to_i();
}

Fractor::operator int64_t() const
{
	return (int64_t)to_l();
}

Fractor::operator float() const
{
	return to_f();
}

Fractor::operator double() const
{
	return (double)to_f();
}

void Fractor::strip()
{
	uint64_t un = (uint64_t)llabs(nom);
	uint64_t ud = (uint64_t)llabs(den);

	if (un == 0ULL)
	{
		nom = 0LL;
		den = 1LL;
		return;
	}

	if ((ud / un) >= (int64_t)100000LL)
	{
		nom = 0LL;
		den = 1LL;
		return;
	}

	int64_t g = Fractor::gcb(un, ud);
	nom /= g;
	den /= g;

	while (llabs(nom) > Fractor::upper && llabs(den) > Fractor::upper)
	{
		nom >>= 1;
		den >>= 1;
	}

}

Fractor& Fractor::operator = (const Fractor &b)
{
	nom = b.nom;
	den = b.den;
	return *this;
}

Fractor& Fractor::operator = (const int b)
{
	nom = b;
	den = 1LL;
	return *this;
}

Fractor& Fractor::operator = (const float f)
{
	den = (int64_t)10000LL;
	nom = (int64_t)(f * den);
	strip();
	return *this;
}

Fractor& Fractor::operator = (const double d)
{
	den = (int64_t)10000LL;
	nom = (int64_t)(d * den);
	strip();
	return *this;
}

Fractor& Fractor::operator = (const int64_t i)
{
	nom = i;
	den = 1LL;
	return *this;
}

bool Fractor::operator < (const Fractor &b)  const
{
	int64_t num = nom * b.den;
	int64_t num2 = b.nom * den;
	bool flag = (b.den > 0LL) ^ (den > 0LL);
	return (!flag) ? (num < num2) : (num > num2);
}

bool Fractor::operator > (const Fractor &b)  const
{
	int64_t num = nom * b.den;
	int64_t num2 = b.nom * den;
	bool flag = (b.den > 0LL) ^ (den > 0LL);
	return (!flag) ? (num > num2) : (num < num2);
}

bool Fractor::operator <= (const Fractor &b)  const
{
	int64_t num = nom * b.den;
	int64_t num2 = b.nom * den;
	bool flag = (b.den > 0LL) ^ (den > 0LL);
	return (!flag) ? (num <= num2) : (num >= num2);
}

bool Fractor::operator >= (const Fractor &b)  const
{
	int64_t num = nom * b.den;
	int64_t num2 = b.nom * den;
	bool flag = (b.den > 0LL) ^ (den > 0LL);
	return (!flag) ? (num >= num2) : (num <= num2);
}

bool Fractor::operator == (const Fractor &b)  const
{
	return nom * b.den == b.nom * den;
}

bool Fractor::operator != (const Fractor &b)  const
{
	return nom * b.den != b.nom * den;
}


bool Fractor::operator < (const int64_t b) const
{
	int64_t num = nom;
	int64_t num2 = b * den;
	return (den <= 0LL) ? (num > num2) : (num < num2);
}

bool Fractor::operator > (const int64_t b) const
{
	int64_t num = nom;
	int64_t num2 = b * den;
	return (den <= 0L) ? (num < num2) : (num > num2);
}

bool Fractor::operator <= (const int64_t b) const
{
	int64_t num = nom;
	int64_t num2 = b * den;
	return (den <= 0L) ? (num >= num2) : (num <= num2);
}

bool Fractor::operator >= (const int64_t b) const
{
	int64_t num = nom;
	int64_t num2 = b * den;
	return (den <= 0L) ? (num <= num2) : (num >= num2);
}

bool Fractor::operator == (const int64_t b) const
{
	return nom == b * den;
}

bool Fractor::operator != (const int64_t b) const
{
	return nom != b * den;
}


Fractor Fractor::operator + (const Fractor &b)  const
{
	Fractor ret = Fractor(nom * b.den + b.nom * den, den * b.den);
	ret.strip();
	return ret;
}

Fractor Fractor::operator - (const Fractor &b)  const
{
	Fractor ret = Fractor(nom * b.den - b.nom * den, den * b.den);
	ret.strip();
	return ret;
}

Fractor Fractor::operator * (const Fractor &b)  const
{
	Fractor ret = Fractor(nom * b.nom, den * b.den);
	ret.strip();
	return ret;
}

Fractor Fractor::operator / (const Fractor &b)  const
{
	Fractor ret = Fractor(nom * b.den, den * b.nom);
	ret.strip();
	return ret;
}


Fractor Fractor::operator + (const int64_t b) const
{
	Fractor ret = Fractor(nom + b * den, den);
	ret.strip();
	return ret;
}

Fractor Fractor::operator - (const int64_t b) const
{
	Fractor ret = Fractor(nom - b * den, den);
	ret.strip();
	return ret;
}

Fractor Fractor::operator * (const int64_t b) const
{
	Fractor ret = Fractor(nom * b, den);
	ret.strip();
	return ret;
}

Fractor Fractor::operator / (const int64_t b) const
{
	Fractor ret = Fractor(nom, den * b);
	ret.strip();
	return ret;
}

Fractor& Fractor::operator += (const Fractor &b)
{
	nom = nom * b.den + b.nom * den;
	if (nom == 0LL)
		den = 1LL;
	else
		den = den * b.den;
	strip();
	return *this;
}

Fractor& Fractor::operator -= (const Fractor &b)
{
	nom = nom * b.den - b.nom * den;
	den = den * b.den;
	if (nom == 0LL)
		den = 1LL;
	strip();
	return *this;
}

Fractor& Fractor::operator *= (const Fractor &b)
{
	nom *= b.nom;
	den *= b.den;

	strip();
	return *this;
}

Fractor& Fractor::operator /= (const Fractor &b)
{
	nom *= b.den;
	den *= b.nom;

	strip();
	return *this;
}


Fractor& Fractor::operator += (const int64_t b)
{
	nom = nom + b * den;
	if (nom == 0LL)
		den = 1LL;
	strip();
	return *this;
}

Fractor& Fractor::operator -= (const int64_t b)
{
	nom = nom - b * den;
	if (nom == 0LL)
		den = 1LL;
	strip();
	return *this;
}

Fractor& Fractor::operator *= (const int64_t b)
{
	nom = nom * b;
	if (nom == 0LL)
		den = 1LL;
	strip();
	return *this;
}

Fractor& Fractor::operator /= (const int64_t b)
{
	bool isNe = isNegative();
	den = den * b;
	if (den == 0LL)
	{
		nom = isNe ? LLMIN : LLMAX;
		den = 1LL;
	}
	strip();
	return *this;
}

Fractor Fractor::operator-(void) const
{
	return Fractor(-nom, den);
}

Fractor Fractor::invserse()
{
	return Fractor(den, nom);
}

bool Fractor::isPositive() const
{
	return Fractor::positive(nom, den);
}

bool Fractor::positive(int64_t nom, int64_t den)
{
	if (nom == 0LL)
		return false;
	
	bool flag = nom > 0LL;
	bool flag2 = den > 0LL;
	return !(flag ^ flag2);
}

bool Fractor::isNegative() const
{
	return Fractor::negative(nom, den);
}

bool Fractor::negative(int64_t nom, int64_t den)
{
	if (nom == 0LL)
	return false;
	
	bool flag = nom > 0LL;
	bool flag2 = den > 0LL;
	return flag ^ flag2;
}



int Fractor::round() const
{
	return (int)Fractor::div32(nom, den);
}

int Fractor::to_i() const
{
	return (int)(nom / den);
}

long Fractor::to_l() const
{
	return (long)(nom / den);
}

float Fractor::to_f() const
{
	double num = (double)nom / (double)den;
	return (float)num;
}

double Fractor::to_d() const
{
	return (double)nom / (double)den;
}

void Fractor::cstr(char *psz)
{
	Fractor::cstrf(*this, psz);
}

void Fractor::cstrf(const Fractor &x, char *psz)
{
	assert(psz != NULL);

	double d = x.to_d();
	sprintf(psz, "%.5f", d);
}

Fractor Fractor::sqrtf()
{
	return Fractor::sqrtf(*this);
}

Fractor Fractor::absf()
{
	return Fractor::absf(*this);
}

Fractor Fractor::sinf()
{
	return Fractor::sinf(*this);
}

Fractor Fractor::cosf()
{
	return Fractor::cosf(*this);
}

Fractor Fractor::tanf()
{
	return Fractor::tanf(*this);
}

Fractor Fractor::expf()
{
	return Fractor::expf(*this);
}

Fractor Fractor::acosf()
{
	return Fractor::acosf(*this);
}

Fractor Fractor::asinf()
{
	return Fractor::asinf(*this);
}

Fractor Fractor::to_rad() const
{
	return Fractor::deg_to_rad(*this);
}

Fractor Fractor::to_deg() const
{
	return Fractor::rad_to_deg(*this);
}

int64_t Fractor::div64(int64_t a, int64_t b)
{
	int64_t num = (int64_t)(((uint64_t)((a ^ b) & -9223372036854775807LL)) >> 63 );
	int64_t num2 = num * -2LL + 1LL;
	return (a + b / 2LL * num2) / b;
}

int	Fractor::div32(int a, int b)
{
	int num = (int)(((unsigned int)((a ^ b) & -2147483648)) >> 31);
	int num2 = num * -2 + 1;
	return (a + b / 2 * num2) / b;
}

unsigned int Fractor::sqrt32(unsigned int a)
{
	uint32_t num  = 0u;
	uint32_t num2 = 0u;
	for (int i = 0; i < 16; i++)
	{
		num2 <<= 1;
		num <<= 2;
		num += a >> 30;
		a <<= 2;
		if (num2 < num)
		{
			num2 += 1u;
			num -= num2;
			num2 += 1u;
		}
	}
	return num2 >> 1 & 0xffffu;
}
	
uint64_t	Fractor::sqrt64(uint64_t a)
{
	uint64_t num = 0ULL;
	uint64_t num2 = 0ULL;
	for (int i = 0; i < 32; i++)
	{
		num2 <<= 1;
		num <<= 2;
		num += a >> 62;
		a <<= 2;
		if (num2 < num)
		{
			num2 += 1uL;
			num -= num2;
			num2 += 1uL;
		}
  }
   return (uint64_t)(num2 >> 1 & 0xffffffffu);
}

int	Fractor::sqrtInt(uint64_t a)
{
	if (a <= 0L)
	{
		return 0;
	}
	if (a <= (int64_t)(0xffffu))
	{
		return (int)Fractor::sqrt32((unsigned int)a);
	}
	return (int)Fractor::sqrt64((uint64_t)a);
}

int64_t	Fractor::sqrtLong(uint64_t a)
{
	if (a <= 0L)
	{
		return 0;
	}
	if (a <= (int64_t)(0xffffu))
	{
		return (int64_t)(uint64_t)Fractor::sqrt32((unsigned int)a);
	}
	return (int64_t)Fractor::sqrt64((uint64_t)a);
}

int64_t Fractor::clamp(int64_t a, int64_t min, int64_t max)
{
	if (a < min)
	{
		return min;
	}
	if (a > max)
	{
		return max;
	}
	return a;
}

int Fractor::lerpInt(int src, int dst, int nom, int den)
{
	return Fractor::div32(src * den + (dst - src) * nom, den);
}
	
int64_t Fractor::lerpLong(int64_t src, int64_t dst, int64_t nom, int64_t den)
{
	return Fractor::div64(src * den + (dst - src) * nom, den);
}

Fractor Fractor::asinf(const Fractor &x)
{
	if((x > Fractor::one) || 
		(x < -Fractor::one) || 
		x == Fractor::zero)
		return Fractor::zero;

	if (x == Fractor::one)
		return Fractor::half_pi;

	if (x == -Fractor::one)
		return -Fractor::half_pi;
	
	Fractor y = (Fractor::one - x * x).sqrtf();
	if (y == Fractor::zero)
	{
		if (x > Fractor::zero)
			return Fractor::half_pi;

		if (x < Fractor::zero)
			return -Fractor::half_pi;
	}

	Fractor tan = x / y;
	return Fractor::atanf(tan);
}

Fractor Fractor::atanf(const Fractor &x)
{
	return Fractor::atan2f(x, Fractor::one);
}

Fractor Fractor::atan2f(const Fractor &y, const Fractor &x)
{
	int64_t nom = y.nom * x.den;
	int64_t den = x.nom * y.den;
#ifdef DEBUG_CALL_LUA
	call_lua("logdebug", "siiiiii", "[core] vector3 toDegreeY atan2f: x.nom:%d x.den:%d y.nom:%d y.den:%d nom:%d den:%d", 
	          x.nom, x.den, y.nom, y.den, nom, den);
#endif
	if(den == 0)
	{
		int _y = 1;
		int _x = 0;
		return Fractor::atan2f(_y, _x);
	}

	if(nom == 0) 
	{
		int _y = 0;
		int _x = 1;
		return Fractor::atan2f(_y, _x);
	}
	
	int64_t g = Fractor::gcb(llabs(nom), llabs(den));
	int _y = (int)(nom / g);
	int _x = (int)(den / g);

#ifdef DEBUG_CALL_LUA
	call_lua("logdebug", "siii", "[core] vector3 toDegreeY gcb: g:%d _x:%d _y:%d", 
	         g, _x, _y);
#endif
	return Fractor::atan2f(_y, _x);
}

Fractor Fractor::acosf(const Fractor &f)
{
	return Fractor::acosf(f.nom, f.den);
}

Fractor Fractor::sinf(const Fractor &f)
{
	return Fractor::sinf(f.nom, f.den);
}

Fractor Fractor::cosf(const Fractor &f)
{
	return Fractor::cosf(f.nom, f.den);
}

Fractor Fractor::tanf(const Fractor &f)
{
	return Fractor::tanf(f.nom, f.den);
}


Fractor Fractor::rad_to_deg(const Fractor &rad)
{
	return Fractor::deg_rad_unit * rad;
}

Fractor Fractor::deg_to_rad(const Fractor &deg)
{
	return Fractor::rad_deg_unit * deg;
}

Fractor Fractor::atan2f(int y, int x)
{
	int num;
	int num2;
	if (x < 0)
	{
		if (y < 0)
		{
			x = -x;
			y = -y;
			num = 1;
		}
		else
		{
			x = -x;
			num = -1;
		}
		num2 = -31416;
	}
	else
	{
		if (y < 0)
		{
			y = -y;
			num = -1;
		}
		else
		{
			num = 1;
		}
		num2 = 0;
	}
	int dIM = Atan2Table::DIM;
	int64_t num3 = (int64_t)(dIM - 1);
	int64_t b = (int64_t)((x >= y) ? x : y);
	int num4 = (int)Fractor::div64((int64_t)x * num3, b);
	int num5 = (int)Fractor::div64((int64_t)y * num3, b);
	int num6 = Atan2Table::table[num5 * dIM + num4];
	
	int64_t nom = (int64_t)((num6 + num2) * num);
	int64_t den = (int64_t)10000LL;

	return Fractor(nom, den);
}

Fractor Fractor::acosf(int64_t nom, int64_t den)
{
	int num = (int)Fractor::div64(nom * (int64_t)AcosTable::HALF_COUNT, den) + AcosTable::HALF_COUNT;
	num = Fractor::clamp(num, 0, AcosTable::COUNT);
	int64_t _nom = (int64_t)AcosTable::table[num];
	int64_t _den = (int64_t)10000LL;
	return Fractor(_nom, _den);
}

Fractor Fractor::sinf(int64_t nom, int64_t den)
{
	int index = SincosTable::getIndex(nom, den);
	return Fractor((int64_t)SincosTable::sin_table[index], (int64_t)SincosTable::FACTOR);
}

Fractor Fractor::cosf(int64_t nom, int64_t den)
{
	int index = SincosTable::getIndex(nom, den);
	return Fractor((int64_t)SincosTable::cos_table[index], (int64_t)SincosTable::FACTOR);
}

Fractor Fractor::tanf(int64_t nom, int64_t den)
{
	Fractor c = Fractor::cosf(nom, den);
	if(c == Fractor::zero)
	{
		if (Fractor::positive(nom, den))
			return Fractor(LLMAX, (int64_t)1LL);
		else
			return Fractor(LLMIN, (int64_t)1LL);
	}

	Fractor s = Fractor::sinf(nom, den);
	return s/c;
}

Fractor Fractor::absf(const Fractor &x)
{
	return (x < Fractor::zero) ? -x : x;
}


Fractor Fractor::powf(const Fractor &num, const Fractor &m)
{
 	double dn = num.to_f();
 	double dm = m.to_f();
 	double r = pow(dn, dm);
 	return Fractor(r);
}

Fractor Fractor::sqrtf(const Fractor &x)
{
	if (x < Fractor::zero)
		 return Fractor::zero;

	double dx = x.to_d();
	double r = sqrt(dx);
	return Fractor(r);
}

Fractor Fractor::expf(const Fractor &x)
{
	 double dx = x.to_d();
	 dx = exp(dx);
	 return Fractor(dx);
}

Fractor Fractor::modf(const Fractor &x, const Fractor &y)
{
 double dx = x.to_d();
 double dy = y.to_d();
 double r = fmod(dx, dy);
 return Fractor(r);
}

Fractor Fractor::logf(const Fractor &x)
{
	double d = x.to_d();
	double r = log10(d);
	return Fractor(r);
}

Fractor Fractor::lnf(const Fractor &x)
{
	double d = x.to_d();
	double r = log(d);
	return Fractor(r);
}

Fractor Fractor::lnf()
{
	return Fractor::lnf(*this);
}

Fractor Fractor::logf()
{
	return Fractor::logf(*this);
}

//Fractor Fractor::coef(const int n)
//{
//	if(n == 0) return Fractor(0, 1);
//
//	Fractor t = Fractor(1, n);
//	if(n % 2 == 0) t = -t;
//
//	return t;
//}
//
//Fractor Fractor::horner(const Fractor &x)
//{
//	const int N = 100;
//	Fractor u = Fractor::coef(N);
//	for(int i = N; i>=0; i--)
//	{
//		u *= x;
//		u += coef(i);
//	}
//
//	return u;
//}
//
//static Fractor __eps_max = Fractor(0.001f);
//static Fractor __eps_min = Fractor(-0.001f);
//
//Fractor Fractor::sqrt(const Fractor &b)
//{
//	Fractor x = Fractor::one;
//	int step = 0;
//	Fractor _t = x * x - b;
//	while( (_t < __eps_min || _t > __eps_max) &&
//				 step < 50)
//	{
//		x = (b/x + x)/Fractor::two;
//		step ++;
//		_t = x * x - b;
//	}
//	return x;
//}
//
//Fractor Fractor::ln(const Fractor &x)
//{
//	Fractor _x = x;
//	Fractor f15 = Fractor(3, 2);
//	Fractor f125 = Fractor(5, 4);
//	Fractor f07 = Fractor(7, 10);
//	if(_x > f15)
//	{
//		int i = 0;
//		for(; _x>f125; i++)
//			_x = Fractor::sqrt(_x);
//		return Fractor(1<<i) * horner(_x - Fractor::one);
//	}
//	else if(_x < f07 && _x > Fractor::zero)
//	{
//		int i = 0;
//		for(; _x<f07; i++)
//			_x = Fractor::sqrt(_x);
//		return Fractor(1<<i) * horner(_x - Fractor::one);
//	}
//	else if(_x > Fractor::zero)
//	{
//		return horner(_x - Fractor::one);
//	}
//	return Fractor::zero;
//}
//
//Fractor Fractor::log(const Fractor &m, const Fractor &base)
//{
//	Fractor nom = Fractor::ln(m);
//	Fractor den = Fractor::ln(base);
//	return nom / den;
//}
//
//Fractor Fractor::exp(const Fractor &x)
//{
//	Fractor sum = Fractor::one;
//	for(long i = 100; i > 0; i--)
//	{
//		sum /= i;
//		sum *= x;
//		sum += Fractor::one;
//	}
//	return sum;
//}
//
//Fractor Fractor::pow(const Fractor &m, const Fractor &n)
//{
//	return Fractor::exp(n * ln(m));
//}