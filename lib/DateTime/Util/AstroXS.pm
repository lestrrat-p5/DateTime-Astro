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

sub dynamical_moment_from_dt {
    return dynamical_moment( moment( $_[0] ) );
}

sub julian_centuries {
    return julian_centuries_from_moment( dynamical_moment_from_dt( $_[0] ) );
}

sub lunar_phase {
    return lunar_phase_from_moment( moment($_[0]) );
}

sub solar_longitude {
    return solar_longitude_from_moment( moment($_[0]) );
}
    
sub lunar_longitude {
    return lunar_longitude_from_moment( moment($_[0]) );
}

sub new_moon_after {
    return dt_from_moment( new_moon_after_from_moment( moment( $_[0] ) ) );
}

sub new_moon_before {
    return dt_from_moment( new_moon_before_from_moment( moment( $_[0] ) ) );
}

sub solar_longitude_before {
    return dt_from_moment( solar_longitude_before_from_moment( moment( $_[0] ), $_[1] ) );
}

1;
