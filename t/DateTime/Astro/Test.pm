package t::DateTime::Astro::Test;
use strict;
use Exporter 'import';
use DateTime;

our @EXPORT_OK = qw(datetime);

sub datetime {
    my ($y, $m, $d, $H, $M, $S) = @_;

    my %args = (time_zone => 'UTC');
    $args{year} = $y if defined $y;
    $args{day} = $d if defined $d;
    $args{month} = $m if defined $m;
    $args{hour} = $H if defined $H;
    $args{minute} = $M if defined $M;
    $args{second} = $S if defined $S;

    my $dt = DateTime->new(%args);
    return $dt;
}

1;
