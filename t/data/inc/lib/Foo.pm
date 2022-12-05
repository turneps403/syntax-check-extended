package Foo;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(baz);
our %EXPORT_TAGS = (all => ['baz']);

sub baz(@) { join ",", @_ }

1;