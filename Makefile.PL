use inc::Module::Install;

name 'DateTime-Util-Astro';
all_from 'lib/DateTime/Util/Astro.pm';

use_ppport;
cc_warnings;
cc_libs 'mpfr';
cc_src_paths 'xs';
author_tests 'xt';
auto_set_repository;

WriteAll;