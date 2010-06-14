#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mpfr.h"
#include "ppport.h"
#include "DT_Util_Astro.h"

static int
__mod( mpfr_t *result, mpfr_t *target, mpfr_t *base ) {
    mpfr_t p, r;

    /* target - floor(target / base) * base */
    mpfr_init_set( p, *target, GMP_RNDN );
    mpfr_div( p, p, *base, GMP_RNDN );
    mpfr_floor( p, p );

    mpfr_mul( p, p, *base, GMP_RNDN );
    mpfr_init_set( r, *target, GMP_RNDN );
    mpfr_sub( *result, r, p, GMP_RNDN );
    mpfr_clear(r);
    mpfr_clear(p);
    return 1;
}

static int
__sin( mpfr_t *result, mpfr_t *degrees ) {
    mpfr_t pi2, r;

    mpfr_init(r);
    mpfr_init(pi2);
    mpfr_const_pi(pi2, GMP_RNDN);
    mpfr_mul_ui(pi2, pi2, 2, GMP_RNDN); /* pi * 2 */

    mpfr_init_set(r, pi2, GMP_RNDN);
    mpfr_div_ui(r, r, 360, GMP_RNDN);
    mpfr_mul(r, r, *degrees, GMP_RNDN);

    __mod( &r, &r, &pi2 );
    mpfr_sin( *result, r, GMP_RNDN );

    mpfr_clear(r);
    mpfr_clear(pi2);
    return 1;
}

static int
__cos( mpfr_t *result, mpfr_t *degrees ) {
    mpfr_t pi2, r;

    mpfr_init(r);
    mpfr_init(pi2);
    mpfr_const_pi(pi2, GMP_RNDN);
    mpfr_mul_ui(pi2, pi2, 2, GMP_RNDN); /* pi * 2 */

    mpfr_init_set(r, pi2, GMP_RNDN);
    mpfr_div_ui(r, r, 360, GMP_RNDN);
    mpfr_mul(r, r, *degrees, GMP_RNDN);

    __mod( &r, &r, &pi2 );
    mpfr_cos( *result, r, GMP_RNDN );

    mpfr_clear(r);
    mpfr_clear(pi2);
    return 1;
}

static int
__polynomial( mpfr_t *result, mpfr_t *x, int howmany, mpfr_t **coefs) {
    int i;
    mpfr_t *m;

    mpfr_set_ui( *result, 0, GMP_RNDN);
    if (howmany <= 0) {
        return 0;
    }

    m = coefs[0];
    for (i = howmany - 1; i > 0; i--) {
        mpfr_t p; /* v + next */
        mpfr_init(p);
        mpfr_add( p, *result, *(coefs[i]), GMP_RNDN );
        mpfr_mul( *result, *x, p, GMP_RNDN );
        mpfr_clear(p);
    }

    mpfr_add(*result, *result, *m, GMP_RNDN);
    return 1;
}

static int
polynomial(mpfr_t *result, mpfr_t *x, int howmany, ...) {
    va_list argptr;
    mpfr_t **coefs;
    int i;

    va_start(argptr, howmany);
    mpfr_set_ui( *result, 0, GMP_RNDN );

    Newxz(coefs, howmany, mpfr_t *);
    for(i = 0; i < howmany; i++) {
        coefs[i] = va_arg(argptr, mpfr_t *);
    }
    va_end(argptr);

    __polynomial( result, x, howmany, coefs);

    Safefree(coefs);

    return 1;
}


static int
is_leap_year(int y) {
    if (y % 4) return 0;
    if (y % 100) return 1;
    if (y % 400) return 0;
    return 1;
}

static long
gregorian_year_from_rd(long rd) {
    double approx;
    double start;

    approx = floor( (rd - RD_GREGORIAN_EPOCH + 2) * 400 / 146097 );
    start = RD_GREGORIAN_EPOCH + 365 * approx + floor(approx/4) - floor(approx/100) + floor(approx/400);

    if (rd < start) {
        return (int) approx;
    } else {
        return (int) (approx + 1);
    }
}

static int
fixed_from_ymd(int y, int m, int d) {
    return
        365 * (y -1) +
        floor( (y - 1) / 4 ) -
        floor( (y - 1) / 100 ) +
        floor( (y - 1) / 400 ) +
        floor( (367 * m - 362) / 12 ) +
        ( m <= 2 ? 0 :
          m  > 2 && is_leap_year(y) ? -1 :
          -2 
        ) + d
    ;
}

#define _amod(x, y) \
    ( y + x % ( -y ) )

static int
gregorian_components_from_rd(long rd, long *y, int *m, int *d) {
    int prior_days;
    *y = gregorian_year_from_rd( RD_GREGORIAN_EPOCH - 1 + rd + 306);

    prior_days = rd - fixed_from_ymd( *y - 1, 3, 1 );
    *m = (int) ( ((int) floor((5 * prior_days + 155) / 153) + 2) % 12 );
    if (*m == 0) *m = 12;
    *y = (long) (*y - floor( (*m + 9) / 12 ));
    *d = (int) ( rd - fixed_from_ymd(*y, *m, 1) + 1);
    return 1;
}

static int
ymd_seconds_from_moment(mpfr_t *moment, long *y, int *m, int *d, int *s) {
    long rd;
    mpfr_t frac;

    rd = mpfr_get_si( *moment, GMP_RNDN );
    gregorian_components_from_rd( rd, y, m, d );
    mpfr_init_set(frac, *moment, GMP_RNDN);
    mpfr_sub_ui(frac, frac, rd, GMP_RNDN); /* now only fractional part */
    mpfr_mul_ui(frac, frac, 86400, GMP_RNDN); /* now seconds */

    *s = mpfr_get_si( frac, GMP_RNDN );
    mpfr_clear(frac);
    return 1;
}

static int
EC_C(mpfr_t *result, int y) {
    mpfr_set_d(
        *result,
        fixed_from_ymd(y, 7, 1) - RD_MOMENT_1900_JAN_1,
        GMP_RNDN
    );
    mpfr_div_ui( *result, *result, 3652510, GMP_RNDN );
    return 1;
}

static int
EC2(mpfr_t *correction, mpfr_t *ec_c) {
    mpfr_t a, b, c, d, e, f, g, h;
    mpfr_init_set_d(a, -0.00002, GMP_RNDN);
    mpfr_init_set_d(b,  0.000297, GMP_RNDN);
    mpfr_init_set_d(c,  0.025184, GMP_RNDN);
    mpfr_init_set_d(d, -0.181133, GMP_RNDN);
    mpfr_init_set_d(e,  0.553040, GMP_RNDN);
    mpfr_init_set_d(f, -0.861938, GMP_RNDN);
    mpfr_init_set_d(g,  0.677066, GMP_RNDN);
    mpfr_init_set_d(h, -0.212591, GMP_RNDN);

    polynomial(correction, ec_c, 8, &a, &b, &c, &d, &e, &f, &g, &h);

    mpfr_clear(a);
    mpfr_clear(b);
    mpfr_clear(c);
    mpfr_clear(d);
    mpfr_clear(e);
    mpfr_clear(f);
    mpfr_clear(g);
    mpfr_clear(h);
    return 1;
}

static int
EC3(mpfr_t *correction, mpfr_t *ec_c) {
    mpfr_t a, b, c, d, e, f, g, h, i, j, k;
    mpfr_init_set_d(a, -0.000009, GMP_RNDN);
    mpfr_init_set_d(b, 0.003844, GMP_RNDN);
    mpfr_init_set_d(c, 0.083563, GMP_RNDN);
    mpfr_init_set_d(d, 0.865736, GMP_RNDN);
    mpfr_init_set_d(e, 4.867575, GMP_RNDN);
    mpfr_init_set_d(f, 15.845535, GMP_RNDN);
    mpfr_init_set_d(g, 31.332267, GMP_RNDN);
    mpfr_init_set_d(h, 38.291999, GMP_RNDN);
    mpfr_init_set_d(i, 28.316289, GMP_RNDN);
    mpfr_init_set_d(j, 11.636204, GMP_RNDN);
    mpfr_init_set_d(k, 2.043794, GMP_RNDN);

    polynomial(correction, ec_c, 11, &a, &b, &c, &d, &e, &f, &g, &h, &i, &j, &k);

    mpfr_clear(a);
    mpfr_clear(b);
    mpfr_clear(c);
    mpfr_clear(d);
    mpfr_clear(e);
    mpfr_clear(f);
    mpfr_clear(g);
    mpfr_clear(h);
    mpfr_clear(i);
    mpfr_clear(j);
    mpfr_clear(k);

    return 1;
}

static int
EC4(mpfr_t *correction, int year) {
    mpfr_t y, a, b, c, d;

    mpfr_init_set_si(y, year, GMP_RNDN);
    mpfr_init_set_d(a, 8.118780842, GMP_RNDN);
    mpfr_init_set_d(b, -0.005092142, GMP_RNDN);
    mpfr_init_set_d(c, 0.003336121, GMP_RNDN);
    mpfr_init_set_d(d, -0.0000266484, GMP_RNDN);

    polynomial(correction, &y, 4, &a, &b, &c, &d);
    return mpfr_div_ui(*correction, *correction, 86400, GMP_RNDN);
}

static int
EC5(mpfr_t *correction, int year) {
    mpfr_t y, a, b, c;

    mpfr_init_set_si(y, year, GMP_RNDN);
    mpfr_init_set_d(a, 196.58333, GMP_RNDN);
    mpfr_init_set_d(b, -4.0675, GMP_RNDN);
    mpfr_init_set_d(c, 0.0219167, GMP_RNDN);
    polynomial(correction, &y, 3, &a, &b, &c);
    return mpfr_div_ui(*correction, *correction, 86400, GMP_RNDN);

}

static int
EC_X(mpfr_t *result, int y) {
    mpfr_set_d(
        *result,
        fixed_from_ymd(y, 1, 1) - RD_MOMENT_1810_JAN_1,
        GMP_RNDN
    );
    return 1;
}

static int
EC6(mpfr_t *correction, int year) {
    mpfr_t x;
    mpfr_init(x);
    EC_X( &x, year );

    mpfr_pow_ui( *correction, x, 2, GMP_RNDN );
    mpfr_div_ui( *correction, *correction, 41048480, GMP_RNDN );
    mpfr_sub_ui( *correction, *correction, 15, GMP_RNDN );
    mpfr_div_ui( *correction, *correction, 86400, GMP_RNDN );

    mpfr_clear(x);
    return 1;
}

static int
ephemeris_correction(mpfr_t *correction, int y) {
    if (1988 < y && y <= 2019) {
        mpfr_set_si( *correction, y - 1933, GMP_RNDN );
        mpfr_div_si( *correction, *correction, 86400, GMP_RNDN );
    } else if ( 1900 <= y && y <= 1987 ) {
        mpfr_t c;
        mpfr_init(c);
        EC_C(&c, y);
        EC2(correction, &c);
        mpfr_clear(c);
    } else if ( 1800 <= y && y <= 1899 ) {
        mpfr_t c;
        mpfr_init(c);
        EC_C(&c, y);
        EC3(correction, &c);
        mpfr_clear(c);
    } else if ( 1700 <= y && y <= 1799 ) {
        EC4(correction, y - 1700);
    } else if ( 1620 <= y && 1699 ) {
        EC5(correction, y - 1600);
    } else {
        EC6(correction, y);
    }
    return 1;
}

static int
dynamical_moment(mpfr_t *result, mpfr_t *moment) {
    mpfr_t correction;
    long rd;
    mpfr_init(correction);
    mpfr_init_set( *result, *moment, GMP_RNDN );

    rd = mpfr_get_si(*moment, GMP_RNDN);

    ephemeris_correction(&correction, gregorian_year_from_rd(rd));
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "moment = %.10RNf, correction = %.10RNf\n",
    *moment, correction);
#endif
#endif
    mpfr_add( *result, *result, correction, GMP_RNDN );
    mpfr_clear(correction);
    return 1;
}

static int
julian_centuries(mpfr_t *result, mpfr_t *moment) {
    dynamical_moment(result, moment);
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "moment = %.10RNf, dynamical = %.10RNf\n",
    *moment, *result );
#endif
#endif
    mpfr_sub_d( *result, *result, RD_MOMENT_J2000, GMP_RNDN );
    mpfr_div_ui( *result, *result, 36525, GMP_RNDN );
    return 1;
}

static int
aberration(mpfr_t *result, mpfr_t *moment) {
    /* 0.0000974 * cos( 177.63 + 35999.01848 * julian_centuries(moment) ) - 0.0005575 */
    julian_centuries(result, moment);
    mpfr_mul_d( *result, *result, 35999.01848, GMP_RNDN );
    mpfr_add_d( *result, *result, 177.63, GMP_RNDN );
    __cos( result, result );
    mpfr_mul_d( *result, *result, 0.000094, GMP_RNDN );
    mpfr_sub_d( *result, *result, 0.0005575, GMP_RNDN );

    return 1;
}

static int
nutation( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t A, B, C;
    mpfr_init(C);
    julian_centuries(&C, moment);

    {
        mpfr_t a, b, c;
        mpfr_init(A);
        mpfr_init_set_d( a, 124.90, GMP_RNDN );
        mpfr_init_set_d( b, -1934.134, GMP_RNDN );
        mpfr_init_set_d( c, 0.002063, GMP_RNDN );

        polynomial(&A, &C, 3, &a, &b, &c);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    {
        mpfr_t a, b, c;
        mpfr_init(B);
        mpfr_init_set_d( a, 201.11, GMP_RNDN );
        mpfr_init_set_d( b, 72001.5377, GMP_RNDN );
        mpfr_init_set_d( c, 0.00057, GMP_RNDN );
        polynomial(&B, &C, 3, &a, &b, &c);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    __sin(&A, &A);
    mpfr_mul_d(A, A, -0.004778, GMP_RNDN);
    __sin(&B, &B);
    mpfr_mul_d(B, B, -0.0003667, GMP_RNDN);
    mpfr_add(*result, A, B, GMP_RNDN);
    return 1;
}

static int
lunar_longitude( mpfr_t *result, mpfr_t *moment ) {

    mpfr_t C, mean_moon, elongation, solar_anomaly, lunar_anomaly, moon_node, E, correction, venus, jupiter, flat_earth, N, fullangle;

    julian_centuries( &C, moment );

    {
        mpfr_t a, b, c, d, e;

        mpfr_init(mean_moon);
        mpfr_init_set_d(a, 218.316591, GMP_RNDN);
        mpfr_init_set_d(b, 481267.88134236, GMP_RNDN);
        mpfr_init_set_d(c, -0.0013268, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 538841, GMP_RNDN);
        mpfr_init_set_si(e, -1, GMP_RNDN);
        mpfr_div_ui(e, e, 65194000, GMP_RNDN);

        polynomial( &mean_moon, &C, 5, &a, &b, &c, &d, &e );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(elongation);

        mpfr_init_set_d(a, 297.8502042, GMP_RNDN);
        mpfr_init_set_d(b, 445267.1115168, GMP_RNDN);
        mpfr_init_set_d(c, -0.00163, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 545868, GMP_RNDN);
        mpfr_init_set_si(e, -1, GMP_RNDN);
        mpfr_div_ui(e, e, 113065000, GMP_RNDN);
        polynomial( &elongation, &C, 5, &a, &b, &c, &d, &e );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d;
        mpfr_init(solar_anomaly);
        mpfr_init_set_d(a, 357.5291092, GMP_RNDN);
        mpfr_init_set_d(b, 35999.0502909, GMP_RNDN);
        mpfr_init_set_d(c,  -0.0001536, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 24490000, GMP_RNDN);
        polynomial( &solar_anomaly, &C, 4, &a, &b, &c, &d );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(lunar_anomaly);

        mpfr_init_set_d(a, 134.9634114, GMP_RNDN);
        mpfr_init_set_d(b, 477198.8676313, GMP_RNDN);
        mpfr_init_set_d(c, 0.0008997, GMP_RNDN);
        mpfr_init_set_ui(d, 1, GMP_RNDN);
        mpfr_div_ui(d, d, 69699, GMP_RNDN);
        mpfr_init_set_si(e, -1, GMP_RNDN);
        mpfr_div_ui(e, e,  14712000, GMP_RNDN);
        polynomial( &lunar_anomaly, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(moon_node);
        mpfr_init_set_d(a, 93.2720993, GMP_RNDN);
        mpfr_init_set_d(b, 483202.0175273, GMP_RNDN);
        mpfr_init_set_d(c, -0.0034029, GMP_RNDN);
        mpfr_init_set_si(d, -1, GMP_RNDN);
        mpfr_div_ui(d, d, 3526000, GMP_RNDN);
        mpfr_init_set_ui(e, 1, GMP_RNDN);
        mpfr_div_ui(e, e, 863310000, GMP_RNDN);
        polynomial(&moon_node, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c;
        mpfr_init(E);
        mpfr_init_set_ui(a, 1, GMP_RNDN);
        mpfr_init_set_d(b, -0.002516, GMP_RNDN);
        mpfr_init_set_d(c, -0.0000074, GMP_RNDN);
        polynomial( &E, &C, 3, &a, &b, &c );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    {
        int i;
        mpfr_t fugly;
        mpfr_init_set_ui(fugly, 0, GMP_RNDN);

        for(i = 0; i < LUNAR_LONGITUDE_ARGS_SIZE; i++) {
            mpfr_t a, b, v, w, x, y, z;
            mpfr_init_set_d( v, LUNAR_LONGITUDE_ARGS[i][0], GMP_RNDN );
            mpfr_init_set_d( w, LUNAR_LONGITUDE_ARGS[i][1], GMP_RNDN );
            mpfr_init_set_d( x, LUNAR_LONGITUDE_ARGS[i][2], GMP_RNDN );
            mpfr_init_set_d( y, LUNAR_LONGITUDE_ARGS[i][3], GMP_RNDN );
            mpfr_init_set_d( z, LUNAR_LONGITUDE_ARGS[i][4], GMP_RNDN );

            mpfr_init(b);
            mpfr_pow(b, E, x, GMP_RNDN);

            mpfr_mul(w, w, elongation, GMP_RNDN);
            mpfr_mul(x, x, solar_anomaly, GMP_RNDN);
            mpfr_mul(y, y, lunar_anomaly, GMP_RNDN);
            mpfr_mul(z, z, moon_node, GMP_RNDN);

            mpfr_init_set(a, w, GMP_RNDN);
            mpfr_add(a, a, x, GMP_RNDN);
            mpfr_add(a, a, y, GMP_RNDN);
            mpfr_add(a, a, z, GMP_RNDN);
            __sin(&a, &a);

            mpfr_mul(a, a, v, GMP_RNDN);
            mpfr_mul(a, a, b, GMP_RNDN);
            mpfr_add(fugly, fugly, a, GMP_RNDN);

            mpfr_clear(a);
            mpfr_clear(b);
            mpfr_clear(v);
            mpfr_clear(w);
            mpfr_clear(x);
            mpfr_clear(y);
            mpfr_clear(z);
        }

        mpfr_init_set_d( correction, 0.000001, GMP_RNDN );
        mpfr_mul( correction, correction, fugly, GMP_RNDN);
        mpfr_clear(fugly);
    }

    {
        mpfr_t a, b;
        mpfr_init(venus);
        mpfr_init_set_d(a, 119.75, GMP_RNDN);
        mpfr_init_set(b, C, GMP_RNDN);
        mpfr_mul_d(b, b, 131.849, GMP_RNDN);

        mpfr_add(a, a, b, GMP_RNDN);
        __sin(&a, &a);
        mpfr_mul_d(venus, a, 0.003957, GMP_RNDN );
        mpfr_clear(a);
        mpfr_clear(b);
    }

    {
        mpfr_t a, b;
        mpfr_init(jupiter);
        mpfr_init_set_d(a, 53.09, GMP_RNDN);
        mpfr_init_set(b, C, GMP_RNDN);
        mpfr_mul_d(b, b, 479264.29, GMP_RNDN);
    
        mpfr_add(a, a, b, GMP_RNDN);
        __sin(&a, &a);
        mpfr_mul_d(jupiter, a, 0.000318, GMP_RNDN );
        mpfr_clear(a);
        mpfr_clear(b);
    }

    {
        mpfr_t a;
        mpfr_init(flat_earth);
        mpfr_init_set(a, mean_moon, GMP_RNDN);
        mpfr_sub(a, a, moon_node, GMP_RNDN);
        __sin(&a, &a);
        mpfr_mul_d(flat_earth, a, 0.001962, GMP_RNDN);
        mpfr_clear(a);
    }

    mpfr_set(*result, mean_moon, GMP_RNDN);
    mpfr_add(*result, *result, correction, GMP_RNDN);
    mpfr_add(*result, *result, venus, GMP_RNDN);
    mpfr_add(*result, *result, jupiter, GMP_RNDN);
    mpfr_add(*result, *result, flat_earth, GMP_RNDN);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "mean_moon = %.10RNf\ncorrection = %.10RNf\nvenus = %.10RNf\njupiter = %.10RNf\nflat_earth = %.10RNf\n",
    mean_moon,
    correction,
    venus,
    jupiter,
    flat_earth);
#endif
#endif

    mpfr_init(N);
    nutation(&N, moment);
    mpfr_add(*result, *result, N, GMP_RNDN);

    mpfr_init_set_ui(fullangle, 360, GMP_RNDN);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "lunar = mod(%.10RNf) = ", *result );
#endif
#endif
    __mod(result, result, &fullangle);
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "%.10RNf\n", *result );
#endif
#endif
    return 1;
}

static int
nth_new_moon( mpfr_t *result, int n_int ) {
    mpfr_t n, k, C, approx, E, solar_anomaly, lunar_anomaly, moon_argument, omega, extra, correction, additional;

    mpfr_init_set_ui( n, n_int, GMP_RNDN );

    /* k = n - 24724 */
    mpfr_init_set(k, n, GMP_RNDN);
    mpfr_sub_ui(k, k, 24724, GMP_RNDN );

    /* c = k / 1236.85 */
    mpfr_init_set(C, k, GMP_RNDN );
    mpfr_div_d(C, C, 1236.85, GMP_RNDN);

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(approx);
        mpfr_init_set_d(a, 730125.59765, GMP_RNDN );
        mpfr_init_set_d(b, MEAN_SYNODIC_MONTH * 1236.85, GMP_RNDN );
        mpfr_init_set_d(c, 0.0001337, GMP_RNDN );
        mpfr_init_set_d(d, -0.000000150, GMP_RNDN );
        mpfr_init_set_d(e, 0.00000000073, GMP_RNDN );
        polynomial( &approx, &C, 5, &a, &b, &c, &d, &e );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "approx = %.10RNf\n", approx);
#endif
#endif
    }

    {
        mpfr_t a, b, c;
        mpfr_init(E);
        mpfr_init_set_ui(a, 1, GMP_RNDN);
        mpfr_init_set_d(b, -0.002516, GMP_RNDN );
        mpfr_init_set_d(c, -0.0000074, GMP_RNDN );
        polynomial( &E, &C, 3, &a, &b, &c );
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    {
        mpfr_t a, b, c, d;
        mpfr_init(solar_anomaly);
        mpfr_init_set_d(a, 2.5534, GMP_RNDN);
        mpfr_init_set_d(b, 1236.85 * 29.10535669, GMP_RNDN);
        mpfr_init_set_d(c, -0.0000218, GMP_RNDN );
        mpfr_init_set_d(d, -0.00000011, GMP_RNDN );
        polynomial( &solar_anomaly, &C, 4, &a, &b, &c, &d);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(lunar_anomaly);
        mpfr_init_set_d(a, 201.5643, GMP_RNDN);
        mpfr_init_set_d(b, 385.81693528 * 1236.85, GMP_RNDN);
        mpfr_init_set_d(c, 0.0107438, GMP_RNDN);
        mpfr_init_set_d(d, 0.00001239, GMP_RNDN);
        mpfr_init_set_d(e, -0.000000058, GMP_RNDN);
        polynomial( &lunar_anomaly, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d, e;
        mpfr_init(moon_argument);
        mpfr_init_set_d(a, 160.7108, GMP_RNDN);
        mpfr_init_set_d(b, 390.67050274 * 1236.85, GMP_RNDN);
        mpfr_init_set_d(c, -0.0016431, GMP_RNDN);
        mpfr_init_set_d(d, -0.00000227, GMP_RNDN);
        mpfr_init_set_d(e, 0.000000011, GMP_RNDN);
        polynomial( &moon_argument, &C, 5, &a, &b, &c, &d, &e);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
        mpfr_clear(e);
    }

    {
        mpfr_t a, b, c, d;
        mpfr_init(omega);
        mpfr_init_set_d(a, 124.7746, GMP_RNDN);
        mpfr_init_set_d(b, -1.56375580 * 1236.85, GMP_RNDN);
        mpfr_init_set_d(c, 0.0020691, GMP_RNDN);
        mpfr_init_set_d(d, 0.00000215, GMP_RNDN);
        polynomial( &omega, &C, 4, &a, &b, &c, &d);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
        mpfr_clear(d);
    }

    {
        mpfr_t a, b, c;
        mpfr_init(extra);
        mpfr_init_set_d(a, 299.77, GMP_RNDN);
        mpfr_init_set_d(b, 132.8475848, GMP_RNDN);
        mpfr_init_set_d(c, -0.009173, GMP_RNDN);
        polynomial(&extra, &c, 3, &a, &b, &c);
        __sin(&extra, &extra);
        mpfr_mul_d(extra, extra, 0.000325, GMP_RNDN);
        mpfr_clear(a);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    mpfr_init(correction);
    __sin(&correction, &omega);
    mpfr_mul_d(correction, correction, -0.00017, GMP_RNDN);

    {
        int i;
        for( i = 0; i < NTH_NEW_MOON_CORRECTION_ARGS_SIZE; i++ ) {
            mpfr_t a, v, w, x, y, z;
            mpfr_init_set_d(v, NTH_NEW_MOON_CORRECTION_ARGS[i][0], GMP_RNDN);
            mpfr_init_set_d(w, NTH_NEW_MOON_CORRECTION_ARGS[i][1], GMP_RNDN);
            mpfr_init_set_d(x, NTH_NEW_MOON_CORRECTION_ARGS[i][2], GMP_RNDN);
            mpfr_init_set_d(y, NTH_NEW_MOON_CORRECTION_ARGS[i][3], GMP_RNDN);
            mpfr_init_set_d(z, NTH_NEW_MOON_CORRECTION_ARGS[i][4], GMP_RNDN);

            mpfr_mul(x, x, solar_anomaly, GMP_RNDN);
            mpfr_mul(y, y, lunar_anomaly, GMP_RNDN);
            mpfr_mul(z, z, moon_argument, GMP_RNDN);

            mpfr_add(x, x, y, GMP_RNDN);
            mpfr_add(x, x, z, GMP_RNDN);
            __sin(&x, &x);

            mpfr_init(a);
            mpfr_pow(a, E, w, GMP_RNDN);

            mpfr_mul(a, a, v, GMP_RNDN);
            mpfr_mul(a, a, x, GMP_RNDN);
            mpfr_add( correction, correction, a, GMP_RNDN );

            mpfr_clear(a);
            mpfr_clear(v);
            mpfr_clear(w);
            mpfr_clear(x);
            mpfr_clear(y);
            mpfr_clear(z);
        }
    }

    {
        int z;
        mpfr_init_set_ui(additional, 0, GMP_RNDN);
        for (z = 0; z < NTH_NEW_MOON_ADDITIONAL_ARGS_SIZE; z++) {
            mpfr_t i, j, l;
            mpfr_init_set_d(i, NTH_NEW_MOON_ADDITIONAL_ARGS[z][0], GMP_RNDN);
            mpfr_init_set_d(j, NTH_NEW_MOON_ADDITIONAL_ARGS[z][1], GMP_RNDN);
            mpfr_init_set_d(l, NTH_NEW_MOON_ADDITIONAL_ARGS[z][2], GMP_RNDN);

            mpfr_mul(j, j, k, GMP_RNDN);
            mpfr_add(j, j, i, GMP_RNDN);
            __sin(&j, &j);
            mpfr_mul(l, l, j, GMP_RNDN);

            mpfr_add(additional, additional, l, GMP_RNDN);
        }
    }

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "correction = %.10RNf\nextra = %.10RNf\nadditional = %.10RNf\n", correction, extra, additional );
#endif
#endif
    mpfr_set(*result, approx, GMP_RNDN);
    mpfr_add(*result, *result, correction, GMP_RNDN);
    mpfr_add(*result, *result, extra, GMP_RNDN);
    mpfr_add(*result, *result, additional, GMP_RNDN);

    mpfr_clear(n);
    mpfr_clear(k);
    mpfr_clear(C);
    mpfr_clear(approx);
    mpfr_clear(E);
    mpfr_clear(solar_anomaly);
    mpfr_clear(lunar_anomaly);
    mpfr_clear(moon_argument);
    mpfr_clear(omega);
    mpfr_clear(extra);
    mpfr_clear(correction);
    mpfr_clear(additional);

    return 1;
}

static int
solar_longitude( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t C, fugly, A, N, longitude, fullangle;

    mpfr_init(C);
    julian_centuries(&C, moment);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "julian_centuries = %.10RNf\n", C);
#endif
#endif
    {
        int i;
        mpfr_init_set_ui(fugly, 0, GMP_RNDN);
        for( i = 0; i < SOLAR_LONGITUDE_ARGS_SIZE; i++ ) {
            mpfr_t a, b, c;
            mpfr_init_set_d( a, SOLAR_LONGITUDE_ARGS[i][0], GMP_RNDN );
            mpfr_init_set_d( b, SOLAR_LONGITUDE_ARGS[i][1], GMP_RNDN );
            mpfr_init_set_d( c, SOLAR_LONGITUDE_ARGS[i][2], GMP_RNDN );
            mpfr_mul(c, c, C, GMP_RNDN);
            mpfr_add(b, b, c, GMP_RNDN);
            __sin(&b, &b);
            mpfr_mul(a, a, b, GMP_RNDN);
            mpfr_add(fugly, fugly, a, GMP_RNDN);
            mpfr_clear(a);
            mpfr_clear(b);
            mpfr_clear(c);
        }
    }

    {
        mpfr_t b, c;
        mpfr_init_set_d(longitude, 282.7771834, GMP_RNDN);
        mpfr_init_set_d(b, 36000.76953744, GMP_RNDN);
        mpfr_mul(b, b, C, GMP_RNDN);
        mpfr_init_set_d(c, 0.000005729577951308232, GMP_RNDN);
        mpfr_mul(c, c, fugly, GMP_RNDN);
        mpfr_add(longitude, longitude, b, GMP_RNDN);
        mpfr_add(longitude, longitude, c, GMP_RNDN);
        mpfr_clear(b);
        mpfr_clear(c);
    }

    mpfr_init(A);
    aberration(&A, moment);

    mpfr_init(N);
    nutation(&N, moment);

#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr,
    "longitude = %.10RNf\naberration = %.10RNf\nnutation = %.10RNf\n",
    longitude,
    A,
    N);
#endif
#endif

    mpfr_set( *result, longitude, GMP_RNDN);
    mpfr_add( *result, *result, A, GMP_RNDN );
    mpfr_add( *result, *result, N, GMP_RNDN );

    mpfr_init_set_ui( fullangle, 360, GMP_RNDN );
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "(solar) mod(%.10RNf) = ", *result );
#endif
#endif
    __mod( result, result, &fullangle );
#ifdef ANNOYING_DEBUG
#if (ANNOYING_DEBUG)
mpfr_fprintf(stderr, "%.10RNf\n", *result );
#endif
#endif

    mpfr_clear(A);
    mpfr_clear(N);
    mpfr_clear(C);
    mpfr_clear(longitude);
    mpfr_clear(fullangle);
    mpfr_clear(fugly);

    return 1;
}

MODULE = DateTime::Util::Astro  PACKAGE = DateTime::Util::Astro   PREFIX = DT_Util_Astro_

PROTOTYPES: DISABLE

mpfr_t
DT_Util_Astro_polynomial(x, ...)
        SV_TO_MPFR x;
    CODE:
        mpfr_init(RETVAL);
        if (items <= 1) {
            mpfr_set_ui(RETVAL, 0, GMP_RNDN);
        } else {
            int i;
            mpfr_t **coefs;
            Newxz(coefs, items - 1, mpfr_t *);
            for(i = 1; i < items; i++) {
                Newxz( coefs[i - 1], 1, mpfr_t );
                mpfr_init_set_str( *coefs[i - 1], SvPV_nolen(ST(i)), 10, GMP_RNDN);
            }

            __polynomial(&RETVAL, &x, items - 1, coefs);
            for( i = i; i < items; i++ ) {
                mpfr_clear( *coefs[i - 1] );
                Safefree(*coefs[i - 1]);
            }
            Safefree(coefs);
        }
    OUTPUT:
        RETVAL


mpfr_t
DT_Util_Astro_ephemeris_correction(year)
        int year;
    CODE:
        mpfr_init(RETVAL);
        ephemeris_correction( &RETVAL, year );
    OUTPUT:
        RETVAL

mpfr_t
DT_Util_Astro_dynamical_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        dynamical_moment( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

long
DT_Util_Astro_gregorian_year_from_rd(rd)
        long rd;
    CODE:
        RETVAL = gregorian_year_from_rd(rd);
    OUTPUT:
        RETVAL

void
DT_Util_Astro_gregorian_components_from_rd(rd)
        long rd;
    PREINIT:
        long y;
        int m, d;
    PPCODE:
        EXTEND(SP, 3);

        gregorian_components_from_rd(rd, &y, &m, &d);
        mPUSHi(y);
        mPUSHi(m);
        mPUSHi(d);

void
DT_Util_Astro_ymd_seconds_from_moment(moment)
        SV_TO_MPFR moment;
    PREINIT:
        long y;
        int m, d, s;
    PPCODE:
        ymd_seconds_from_moment( &moment, &y, &m, &d, &s );
        mpfr_clear(moment);

        EXTEND(SP, 4);
        mPUSHi(y);
        mPUSHi(m);
        mPUSHi(d);
        mPUSHi(s);


mpfr_t
DT_Util_Astro_julian_centuries_from_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        julian_centuries( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL


mpfr_t
DT_Util_Astro_nth_new_moon(n)
         int n;
    CODE:
        mpfr_init(RETVAL);
        nth_new_moon(&RETVAL, n);
    OUTPUT:
        RETVAL

mpfr_t
DT_Util_Astro_lunar_longitude_from_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        lunar_longitude( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Util_Astro_solar_longitude_from_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        solar_longitude( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Util_Astro_lunar_phase_from_moment(moment)
        SV_TO_MPFR moment
    PREINIT:
        mpfr_t sl, ll, fullangle;
    CODE:
        mpfr_init(RETVAL);
        mpfr_init(sl);
        mpfr_init(ll);
        mpfr_init_set_ui(fullangle, 360, GMP_RNDN);

        solar_longitude( &sl, &moment );
        lunar_longitude( &ll, &moment );
        mpfr_sub(RETVAL, ll, sl, GMP_RNDN );
        __mod(&RETVAL, &RETVAL, &fullangle);
        mpfr_clear(sl);
        mpfr_clear(ll);
        mpfr_clear(fullangle);
        mpfr_clear(moment);
    OUTPUT:
        RETVAL


