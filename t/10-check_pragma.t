use strict;
use warnings;

use Capture::Tiny qw(:all);
use Test::More;

BEGIN {
    use_ok( 'Syntax::Check' ) || print "Bail out!\n";
}

my $m = 'Syntax::Check';

{
    my ($out, $err) = capture {
        $m->new(file => 't/data/pragma.pl', verbose => 1)->check;
    };
    like $err, qr/syntax OK/, "custom pragma foo::bar";
}

done_testing;
