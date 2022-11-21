use strict;
use warnings;

use Capture::Tiny qw(:all);
use Test::More;

BEGIN {
    use_ok( 'Syntax::Check' ) || print "Bail out!\n";
}

my $m = 'Syntax::Check';

my $table_tets = [
    { file => 't/data/ext/hello.pl', ext => 't/data/ext/hello.pm', desc => 'function/const with prototypes' },
    { file => 't/data/ext/export.pl', ext => 't/data/ext/export.pm', desc => 'export imitation' },
];

for (@$table_tets) 
{
    my ($out, $err) = capture {
        $m->new(file => $_->{file}, ext => $_->{ext}, verbose => 1)->check;
    };

    like $err, qr/syntax OK/, $_->{desc};
}

done_testing;
