#include "dt_astro.h"

struct DT_ASTRO_GLOBAL_CACHE {
    int cache_size;
    mpfr_t **cache;
} dt_astro_global_cache;

static void
DT_Astro__init_global_cache() {
    dt_astro_global_cache.cache_size = 0;
    dt_astro_global_cache.cache = NULL;
}

static void
DT_Astro__clear_global_cache() {
    int i;
    for(i = 0; i < dt_astro_global_cache.cache_size; i++ ) {
        mpfr_t *v = dt_astro_global_cache.cache[i];
        if (v != NULL) {
            mpfr_clear(*v);
            Safefree(v);
        }
    }
    Safefree(dt_astro_global_cache.cache);
}

MODULE = DateTime::Astro PACKAGE = DateTime::Astro   PREFIX = DT_Astro_

PROTOTYPES: DISABLE

void
DT_Astro__init_global_cache()
    

void
DT_Astro__clear_global_cache()

mpfr_t
DT_Astro_polynomial(x, ...)
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

            dt_astro_polynomial(&RETVAL, &x, items - 1, coefs);
            for( i = i; i < items; i++ ) {
                mpfr_clear( *coefs[i - 1] );
                Safefree(*coefs[i - 1]);
            }
            Safefree(coefs);
        }
    OUTPUT:
        RETVAL


mpfr_t
DT_Astro_ephemeris_correction(year)
        int year;
    CODE:
        mpfr_init(RETVAL);
        ephemeris_correction( &RETVAL, year );
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_dynamical_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        dynamical_moment( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

long
DT_Astro_gregorian_year_from_rd(rd)
        long rd;
    CODE:
        RETVAL = gregorian_year_from_rd(rd);
    OUTPUT:
        RETVAL

void
DT_Astro_gregorian_components_from_rd(rd)
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
DT_Astro_ymd_seconds_from_moment(moment)
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
DT_Astro_julian_centuries_from_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        julian_centuries( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL


mpfr_t
DT_Astro_nth_new_moon(n)
         int n;
    CODE:
        mpfr_init(RETVAL);
        nth_new_moon(&RETVAL, n);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_lunar_longitude_from_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        lunar_longitude( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_solar_longitude_from_moment(moment)
        SV_TO_MPFR moment;
    CODE:
        mpfr_init(RETVAL);
        solar_longitude( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_lunar_phase_from_moment(moment)
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        lunar_phase( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_new_moon_after_from_moment(moment)
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        new_moon_after_from_moment( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_new_moon_before_from_moment(moment)
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        new_moon_before_from_moment( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_solar_longitude_before_from_moment( moment, phi )
        SV_TO_MPFR moment
        SV_TO_MPFR phi
    CODE:
        mpfr_init(RETVAL);
        solar_longitude_before(&RETVAL, &moment, &phi );
        mpfr_clear(moment);
        mpfr_clear(phi);
    OUTPUT:
        RETVAL

mpfr_t
DT_Astro_solar_longitude_after_from_moment( moment, phi )
        SV_TO_MPFR moment
        SV_TO_MPFR phi
    CODE:
        mpfr_init(RETVAL);
        solar_longitude_after(&RETVAL, &moment, &phi );
        mpfr_clear(moment);
        mpfr_clear(phi);
    OUTPUT:
        RETVAL

NV
MEAN_SYNODIC_MONTH()
    CODE:
        RETVAL = MEAN_SYNODIC_MONTH;
    OUTPUT:
        RETVAL

NV
MEAN_TROPICAL_YEAR()
    CODE:
        RETVAL = MEAN_TROPICAL_YEAR;
    OUTPUT:
        RETVAL

MODULE = DateTime::Astro PACKAGE = DateTime::Event::SolarTerm   PREFIX = DT_Event_SolarTerm_

PROTOTYPES: DISABLE

mpfr_t
DT_Event_SolarTerm_next_term_at_from_moment( moment, phi )
        SV_TO_MPFR moment
        SV_TO_MPFR phi
    CODE:
        mpfr_init(RETVAL);
        next_term_at( &RETVAL, &moment, &phi );
        mpfr_clear(moment);
        mpfr_clear(phi);
    OUTPUT:
        RETVAL

mpfr_t
DT_Event_SolarTerm_prev_term_at_from_moment( moment, phi )
        SV_TO_MPFR moment
        SV_TO_MPFR phi
    CODE:
        mpfr_init(RETVAL);
        prev_term_at( &RETVAL, &moment, &phi );
        mpfr_clear(moment);
        mpfr_clear(phi);
    OUTPUT:
        RETVAL

mpfr_t
DT_Event_SolarTerm_major_term_after_from_moment( moment )
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        major_term_after( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Event_SolarTerm_major_term_before_from_moment( moment )
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        major_term_before( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Event_SolarTerm_minor_term_after_from_moment( moment )
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        minor_term_after( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

mpfr_t
DT_Event_SolarTerm_minor_term_before_from_moment( moment )
        SV_TO_MPFR moment
    CODE:
        mpfr_init(RETVAL);
        minor_term_before( &RETVAL, &moment );
        mpfr_clear(moment);
    OUTPUT:
        RETVAL

IV
_constant()
    ALIAS:
        CHUNFEN = CHUNFEN
        SHUNBUN = SHUNBUN
        QINGMING = QINGMING
        SEIMEI = SEIMEI
        GUYU = GUYU
        KOKUU = KOKUU
        LIXIA = LIXIA
        RIKKA = RIKKA
        XIAOMAN = XIAOMAN
        SHOMAN  = SHOMAN
        MANGZHONG = MANGZHONG
        BOHSHU = BOHSHU
        XIAZHO = XIAZHO
        GESHI = GESHI
        SUMMER_SOLSTICE = SUMMER_SOLSTICE
        XIAOSHU = XIAOSHU
        SHOUSHO = SHOUSHO
        DASHU = DASHU
        TAISHO = TAISHO
        LIQIU = LIQIU
        RISSHU = RISSHU
        CHUSHU = CHUSHU
        SHOSHO = SHOSHO
        BAILU = BAILU
        HAKURO = HAKURO
        QIUFEN = QIUFEN
        SHUUBUN = SHUUBUN
        HANLU = HANLU
        KANRO = KANRO
        SHUANGJIANG = SHUANGJIANG
        SOHKOH = SOHKOH
        LIDONG = LIDONG
        RITTOH = RITTOH
        XIAOXUE = XIAOXUE
        SHOHSETSU = SHOHSETSU
        DAXUE = DAXUE
        TAISETSU = TAISETSU
        DONGZHI = DONGZHI
        TOHJI = TOHJI
        WINTER_SOLSTICE = WINTER_SOLSTICE
        XIAOHAN = XIAOHAN
        SHOHKAN = SHOHKAN
        DAHAN = DAHAN
        DAIKAN = DAIKAN
        LICHUN = LICHUN
        RISSHUN = RISSHUN
        YUSHUI = YUSHUI
        USUI = USUI
        JINGZE = JINGZE
        KEICHITSU = KEICHITSU 
    CODE:
        RETVAL = ix;
    OUTPUT:
        RETVAL




