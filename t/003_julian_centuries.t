use strict;
use Test::More;

use_ok "DateTime::Util::Astro",
    "julian_centuries",
    "julian_centuries_from_dt"
;

my $dt = DateTime->new(time_zone => 'UTC', year => 2000, month => 1, day => 1);
ok julian_centuries_from_dt( $dt ) < 0.00000005;

done_testing();