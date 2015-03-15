use inc::Module::Install;

name 'DateTime-Astro';
all_from 'lib/DateTime/Astro.pm';
license 'artistic_2';

requires 'DateTime';
requires 'DateTime::Set';
requires 'Exporter' => '5.57';

my (@libs, @includes);

for my $dir ($ENV{GMP_HOME}, $ENV{MPFR {_HOME}) {
    if ($dir) {
        push @includes, File::Spec->catdir($dir, "include");
        push @libs,     File::Spec->catdir($dir, "lib");
    }
}

if (@includs) {
    $ENV{MPFR_INCLUDES} ||= join ":", @includes;
}
if (@libs) {
    $ENV{MPFR_LIBS}     ||= join ":", @libs;
}

print "Detected the following ZMQ settings:\n";
foreach my $env (qw(MPFR_HOME MPFR_INCLUDES MPFR_LIBS)) {
    printf " + %s = %s\n", $env, exists $ENV{$env} ? $ENV{$env} : "(null)";
}

if ($ENV{MPFR_INCLUDES}) {
    cc_include_paths split/\s+/, $ENV{MPFR_INCLUDES};
}
if ($ENV{MPFR_LIBS}) {
    cc_libs $ENV{MPFR_LIBS};
}

use_ppport;
use_xshelper;
cc_warnings;
cc_libs "mpfr", "gmp";
cc_src_paths 'xs';
author_tests 'xt';
auto_set_repository;

WriteAll;