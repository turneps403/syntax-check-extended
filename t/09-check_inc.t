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
        $m->new(file => 't/data/inc/hello.pl', inc => [], verbose => 1)->check;
    };
    like $err, qr/syntax error at t\/data\/inc\/hello.pl/, 'no custom lib path';
}

{
    my ($out, $err) = capture {
        $m->new(file => 't/data/inc/hello.pl', inc => ['t/data/inc/lib'], verbose => 1)->check;
    };
    like $err, qr/syntax OK/, "use custom lib path";
}

done_testing;
