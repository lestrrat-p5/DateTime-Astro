use strict;
use Test::More;

use_ok "DateTime::Util::Astro",
    "nth_new_moon",
    "lunar_longitude_from_moment",
    "solar_longitude_from_moment",
    "dt_from_moment",
    "lunar_phase"
;

my $DELTA_LONGITUDE = $ENV{ALLOW_NEW_MOON_DELTA_LONGITUDE} || 0.006;
my $DELTA_PHASE = $ENV{ALLOW_NEW_MOON_DELTA_PHASE} || 0.006;

my @data = (
    [ 24724, 2000,  1,  6, 18, 14 ],
    [ 24725, 2000,  2,  5, 13,  3 ],
    [ 24726, 2000,  3,  6,  5, 17 ],
    [ 24727, 2000,  4,  4, 18, 12 ],
    [ 24728, 2000,  5,  4,  4, 12 ],
    [ 24729, 2000,  6,  2, 12, 14 ],
    [ 24730, 2000,  7,  1, 19, 20 ],
    [ 24731, 2000,  7, 31,  2, 25 ],
    [ 24732, 2000,  8, 29, 10, 19 ],
    [ 24733, 2000,  9, 27, 19, 53 ],
    [ 24734, 2000, 10, 27,  7, 58 ],
    [ 24735, 2000, 11, 25, 23, 11 ],
    [ 24736, 2000, 12, 25, 17, 22 ],
);

foreach my $data (@data) {
    my ($n, $y, $m, $d, $H, $M) = @$data;
    subtest "$n-th new moon ($y-$m-$d $H:$M)" => sub {
        my $moment = nth_new_moon($n);
        ok $moment > 0, "$n-th new moon ($moment)";
        my $lunar_longitude = lunar_longitude_from_moment($moment);
        my $solar_longitude = solar_longitude_from_moment($moment);

        note "solar longitude = $solar_longitude";
        note "lunar longitude = $lunar_longitude";

        my $delta = $lunar_longitude - $solar_longitude;
        ok $delta < $DELTA_LONGITUDE, "$n-th new moon [lunar = $lunar_longitude][solar = $solar_longitude][delta = $delta] (allowed delta = $DELTA_LONGITUDE)";
        my $dt = dt_from_moment( $moment );
        is $dt->year, $y, "[year = " . $dt->year . "] ($y)";
        is $dt->month, $m, "[month = " . $dt->month . "] ($m)";
        is $dt->day, $d, "[day = " . $dt->day . "] ($d)";
        is $dt->hour, $H, "[hour = " . $dt->hour . "] ($H)";

        ok abs($dt->minute - $M) <= 1, "[minute = " . $dt->minute . "] ($M)";

        my $lunar_phase = lunar_phase($dt);
        ok $lunar_phase < $DELTA_PHASE, "[phase = $lunar_phase] (0)";
        done_testing;
    };
}
done_testing;
