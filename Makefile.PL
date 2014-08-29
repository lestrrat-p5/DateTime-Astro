use inc::Module::Install;

name 'DateTime-Astro';
all_from 'lib/DateTime/Astro.pm';
license 'artistic_2';

requires 'DateTime';
requires 'DateTime::Set';
requires 'Exporter' => '5.57';

if ($ENV{MPFR_HOME}) {
    $ENV{MPFR_INCLUDES} ||= File::Spec->catdir($ENV{MPFR_HOME}, "include");
    $ENV{MPFR_LIBS}     ||= File::Spec->catdir($ENV{MPFR_HOME}, "lib");
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

use_ppport; #Module::Install::XSUtil
use_xshelper; #Module::Install::XSUtil
cc_warnings; #Module::Install::XSUtil
cc_libs 'mpfr'; #Module::Install::XSUtil
cc_src_paths 'xs'; #Module::Install::XSUtil
author_tests 'xt'; #Module::Install::AuthorTests
auto_set_repository; #Module::Install::Repository

WriteAll;