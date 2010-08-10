#ifndef __DT_ASTRO_LUNAR_C__
#define __DT_ASTRO_LUNAR_C__
#include "dt_astro.h"

int
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

int
lunar_phase( mpfr_t *result, mpfr_t *moment ) {
    mpfr_t sl, ll, fullangle;
    mpfr_init(sl);
    mpfr_init(ll);
    mpfr_init_set_ui(fullangle, 360, GMP_RNDN);

    solar_longitude( &sl, moment );
    lunar_longitude( &ll, moment );
    mpfr_sub(*result, ll, sl, GMP_RNDN );
    __mod(result, result, &fullangle);

    mpfr_clear(sl);
    mpfr_clear(ll);
    mpfr_clear(fullangle);
    return 1;
}

static inline void
__adjust_lunar_phase_to_zero(mpfr_t *result) {
    mpfr_t ll, delta;
    int mode = -1;
    int loop = 1;
    /* Adjust values so that it's as close as possible to 0 degrees */

    mpfr_init(ll);
    mpfr_init_set_d(delta, 0.0001, GMP_RNDN);
        
    while (loop) {
        int flipped = mode;
        mpfr_t new_moment;
        mpfr_init(new_moment);
        lunar_phase(&ll, result);
#if (TRACE)
mpfr_fprintf(stderr,
    "Adjusting ll from (%.30RNf) moment is %.5RNf delta is %.30RNf\n", ll, *result, delta);
#endif
            if (mpfr_cmp_ui( ll, 180 ) > 0) {
                mode = 1;
                mpfr_add( new_moment, *result, delta, GMP_RNDN );
#if (TRACE)
mpfr_fprintf(stderr, "add %.30RNf -> %.30RNf\n", *result, new_moment);
#endif
                mpfr_set(*result, new_moment, GMP_RNDN);
                if (mpfr_cmp(new_moment, *result) == 0) {
                    loop = 0;
                }
            } else if (mpfr_cmp_ui( ll, 180 ) < 0 ) {
                if ( mpfr_cmp_d( ll, 0.000000000000000000001 ) < 0) {
                    loop = 0;
                } else {
                    mode = 0;
                    mpfr_sub( new_moment, *result, delta, GMP_RNDN );
#if (TRACE)
mpfr_fprintf(stderr, "sub %.120RNf -> %.120RNf\n", *result, new_moment);
#endif
                    if (mpfr_cmp(new_moment, *result) == 0) {
                        loop = 0;
                    }
                    mpfr_set(*result, new_moment, GMP_RNDN);
                }
            } else {
                loop = 0;
            }
            if (flipped != -1 && flipped != mode) {
                mpfr_div_d(delta, delta, 1.1, GMP_RNDN);
            }
        }
        mpfr_clear(delta);
        mpfr_clear(ll);
    }

int
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
        mpfr_init_set_d(b, 1236.85, GMP_RNDN);
        mpfr_mul_d(b, b, 29.10535669, GMP_RNDN);
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

    __adjust_lunar_phase_to_zero( result );

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
__check_new_moon_before(mpfr_t *x, void *args) {
    mpfr_t result;
    int ok;

    int n = mpfr_get_si(*x, GMP_RNDN);
    mpfr_init(result);
    nth_new_moon(&result, n),
#if (0)
mpfr_fprintf(stderr,
    "%d-th moon comparing %.10RNf against %.10RNf\n",
        n,
        result, *((mpfr_t *) args));
#endif
    ok = mpfr_cmp(result, *((mpfr_t *) args)) < 0;
    mpfr_clear(result);
    return ok;
}

static int
__next_new_moon_before(mpfr_t *next, mpfr_t *x, void *args) {
    ((void) args);
    mpfr_set(*next, *x, GMP_RNDN);
    mpfr_sub_ui(*next, *next, 1, GMP_RNDN);
    return 1;
}

static int
__check_new_moon_after(mpfr_t *x, void *args) {
    mpfr_t result;
    int ok;

    int n = mpfr_get_si(*x, GMP_RNDN);
    mpfr_init(result);
    nth_new_moon(&result, n),
#if (0)
mpfr_fprintf(stderr,
    "%d-th moon comparing %.10RNf against %.10RNf\n",
        n,
        result, *((mpfr_t *) args));
#endif
    ok = mpfr_cmp(result, *((mpfr_t *) args)) > 0;
    mpfr_clear(result);
    return ok;
}

static int
__next_new_moon_after(mpfr_t *next, mpfr_t *x, void *args) {
    ((void) args);
    mpfr_set(*next, *x, GMP_RNDN);
    mpfr_add_ui(*next, *next, 1, GMP_RNDN);
    return 1;
}

int
new_moon_before_from_moment(mpfr_t *result, mpfr_t *o_moment) {
    mpfr_t phi, n;
    mpfr_t moment;

    mpfr_init(n);
    mpfr_init(phi);
    mpfr_init_set(moment, *o_moment, GMP_RNDN);

    lunar_phase( &phi, &moment );

    {
        mpfr_t a;

        mpfr_init_set(a, phi, GMP_RNDN);
        mpfr_div_ui(a, a, 360, GMP_RNDN);

        mpfr_init_set(n, moment, GMP_RNDN);
        mpfr_sub_d(n, n, ZEROTH_NEW_MOON, GMP_RNDN);
        mpfr_div_d(n, n, MEAN_SYNODIC_MONTH, GMP_RNDN);
        mpfr_sub(n, n, a, GMP_RNDN);
        mpfr_round(n, n);
        mpfr_clear(a);
    }

    {
        mpfr_t nm_index;
        int nm;

        mpfr_init(nm_index);
        __search_next( &nm_index, &n,
            __check_new_moon_before, (void *) &moment,
            __next_new_moon_before, NULL );
        nm = mpfr_get_ui(nm_index, GMP_RNDN);

        nth_new_moon(result, nm);
        mpfr_clear(nm_index);
    }

    mpfr_clear(phi);
    mpfr_clear(n);
    mpfr_clear(moment);
    return 1;
}

int
new_moon_after_from_moment(mpfr_t *result, mpfr_t *o_moment) {
    mpfr_t phi, n, moment;

    mpfr_init(n);
    mpfr_init(phi);
    mpfr_init_set( moment, *o_moment, GMP_RNDN );

    lunar_phase( &phi, &moment );

    {
        mpfr_t a;

        mpfr_init_set(a, phi, GMP_RNDN);
        mpfr_div_ui(a, a, 360, GMP_RNDN);

        mpfr_init_set(n, moment, GMP_RNDN);
        mpfr_sub_d(n, n, ZEROTH_NEW_MOON, GMP_RNDN);
        mpfr_div_d(n, n, MEAN_SYNODIC_MONTH, GMP_RNDN);
#if (0)
mpfr_fprintf(stderr,
    "moment = %.10RNf, a = %.10RNf, phi = %.10RNf\n",
    moment,
    a, phi);
#endif
        mpfr_sub(n, n, a, GMP_RNDN);
        mpfr_round(n, n);
        mpfr_clear(a);
    }

    {
        mpfr_t nm_index;
        int nm;

        mpfr_init(nm_index);
        __search_next( &nm_index, &n,
            __check_new_moon_after, (void *) moment,
            __next_new_moon_after, NULL );
        nm = mpfr_get_ui(nm_index, GMP_RNDN);

        nth_new_moon(result, nm);
        mpfr_clear(nm_index);
    }

#if (0)
mpfr_fprintf(stderr,
    "result -> %.10RNf\n", *result );
#endif

    mpfr_clear(phi);
    mpfr_clear(n);
    return 1;
}

#endif /** __DT_ASTRO_LUNAR_C__ **/

