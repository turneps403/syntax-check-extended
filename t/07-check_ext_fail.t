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
        $m->new(file => 't/data/ext/hello.pl', ext => '', verbose => 1)->check;
    };
    like $err, qr/not allowed while "strict subs"/, 'Bareword "xxxx" not allowed while "strict subs"';
}

{
    my ($out, $err) = capture {
        eval { $m->new(file => 't/data/ext/hello.pl', ext => 't/data/ext/UNEXISTS.pm', verbose => 1)->check; 1; } || warn $@;
    };
    like $err, qr/but it's not a file or unreadable/, 'not a file or unreadable: t/data/ext/UNEXISTS.pm';
}

done_testing;
