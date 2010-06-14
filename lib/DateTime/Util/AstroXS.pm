package DateTime::Util::Astro;
use strict;

sub dt_from_moment {
    my ($y, $m, $d, $seconds) = ymd_seconds_from_moment($_[0]);
    my $dt = DateTime->new(
        time_zone => 'UTC',
        year => $y,
        month => $m,
        day => $d,
    );
    $dt->add(seconds => $seconds);
    return $dt;
}

1;
