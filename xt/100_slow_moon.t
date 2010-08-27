use strict; 
use warnings; 
use Test::More;
use DateTime::Astro qw/new_moon_after/; 
use DateTime; 
use Time::HiRes qw(time);

my $dt = DateTime->today(time_zone=>'Asia/Tokyo'); 
for my $i (0..200) { 
    my $start = time();
    my $p = new_moon_after( $dt ); 
    my $end = time();
    ok( ($end - $start) < 0.05, "elapsed time is less than 0.05 (" . ($end-$start). ")");
    $dt = $p; 
} 

done_testing;