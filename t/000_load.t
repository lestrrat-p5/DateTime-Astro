use strict;
use Test::More;
use_ok "DateTime::Util::Astro";

if (! exists $ENV{PERL_DATETIME_UTIL_ASTRO_BACKEND} ||
    $ENV{PERL_DATETIME_UTIL_ASTRO_BACKEND} eq 'XS')
{
    is DateTime::Util::Astro::BACKEND(), "XS";
} else {
    is DateTime::Util::Astro::BACKEND(), "PP";
}

done_testing;
