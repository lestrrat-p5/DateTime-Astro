use strict;
use Cwd ();
use File::Spec;

my $ROOT   = Cwd::abs_path( Cwd::cwd() );
my $EXTDIR = File::Spec->catdir($ROOT, "ext");

sub mysystem(@) {
    system(@_) == 0 or die "Failed to execute @_: $!";
}

sub cpanm (@) {
    @_ = ("cpanm", "--notest", @_);
    goto &mysystem;
}

sub run_tests {
    eval {
        cpanm("--installdeps", ".");
    };
    if (my $e = $@) {
        mysystem("cat", "/home/travis/.cpanm/build.log");
        die $e;
    }
    mysystem("perl", "Makefile.PL");
    mysystem("make", "test");
}

cpanm(qw(
    inc::Module::Install
    Module::Install::AuthorTests
    Module::Install::Repository
    Module::Install::XSUtil
));

{
    my $basename = "mpfr-3.1.1";
    my $prefix = File::Spec->catfile($EXTDIR, $basename);
    my $file = "$basename.tar.gz";
    mysystem("curl", "-LO", "http://www.mpfr.org/mpfr-current/$file");
    mysystem("tar", "xzf", $file);
    chdir $basename;
    mysystem("./configure", "--prefix", $prefix);
    mysystem("make");
    mysystem("make", "install");

    my $incdir = File::Spec->catdir($prefix, "include");
    my $libdir = File::Spec->catdir($prefix, "lib");
    $ENV{CCFLAGS} = "-I$incdir";
    $ENV{LDFLAGS} = "-L$libdir";
}

run_tests();

