package Syntax::Check;

use warnings;
use strict;
use feature 'say';

use Carp qw(croak confess);
use Data::Dumper;
use Exporter qw(import);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Spec qw();
use Module::Installed qw(module_installed);
use PPI;

our $VERSION = '1.10';

my $SEPARATOR;

my $PRAGMA_RE = qr/^(attributes|autodie|autouse|base|bigint|bignum|bigrat|blib|bytes|charnames|constant|diagnostics|encoding|feature|fields|filetest|if|integer|less|lib|locale|mro|open|ops|overload|overloading|parent|re|sigtrap|sort|strict|subs|threads|threads::shared|utf8|vars|vmsish|warnings|warnings::register)/;

BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

sub new {
    my ($class, %p) = @_;

    if (! exists $p{file} || ! -f $p{file}) {
        croak "new() requires a file name as its first parameter";
    }

    if ($p{ext} && (! -f $p{ext} || ! -r _)) {
        croak "'ext' was sent to new() but it's not a file or unreadable: ".$p{ext};
    }

    for (@{$p{inc} ||= []}) {
        croak "'inc' was sent to new() but it's not a directory: ".$_ unless -d $_;
        push @INC, $_;
    }

    my $self = bless {%p}, $class;

    return $self;
}

sub check {
    my ($self) = @_;

    if ($self->{ext}) {
        $self->_create_lib_dir;
        copy($self->{ext}, $self->{lib}."/main.pm") || croak $!;
    }

    my $doc = PPI::Document->new($self->{file});

    my $includes = $doc->find('PPI::Statement::Include');

    for my $include (@$includes) {

        my $module = $include->module;
        my $package = $module;

        if ($module =~ $PRAGMA_RE) {
            # Skip pragmas
            say "Skipping assumed pragma '$module'" if $self->{verbose};
            next;
        }

        next if $module =~ /^Carp/;

        $module =~ s|::|/|g;

        if (my ($vol, $dir, $file) = File::Spec->splitpath($module)) {
            $file .= '.pm';
            my $path = $dir ? "$dir/$file" : $file;

            if (module_installed($package)) {
                # Skip includes that are actually installed
                say "Skipping available module '$package'" if $self->{verbose};
                next;
            }
            else {
                $self->_create_lib_dir;

                if ($dir && ! -d "$self->{lib}/$dir") {
                    # Create the module directory structure
                    make_path("$self->{lib}/$dir") or die $!;
                }

                if (! -f "$self->{lib}/$path") {
                    # Create the module file
                    say "Created temp file '$path'" if $self->{verbose};
                    open my $wfh, '>', "$self->{lib}/$path" or die $!;
                    print $wfh '1;';
                    close $wfh or die $!;
                }
            }
        }
        else {
            # Single-word module, ie. no directory structure
            $self->_create_lib_dir;

            my $module_file = "$module.pm";
            if (! -f "$self->{lib}/$module_file") {
                # Create the module file
                say "Created temp file '$module_file'" if $self->{verbose};
                open my $wfh, '>', "$self->{lib}/$module_file" or die $!;
                print $wfh '1;';
                close $wfh or die $!;
            }
        }
    }

    push @{$self->{inc}}, $self->{lib} if $self->{lib};
    my $I = join(" ", map {"-I $_"} @{$self->{inc}});

    my $M = $self->{ext} ? "-Mmain" : "";

    say "RUN as: perl $I $M -wc $self->{file}" if $self->{verbose};

    `perl $I $M -wc $self->{file}`;
}

sub _create_lib_dir {
    my ($self) = @_;
    if (! exists $self->{lib} || ! -d $self->{lib}) {
        $self->{cleanup} = exists $self->{keep} ? ! $self->{keep} : 1;
        $self->{lib} = tempdir(CLEANUP => $self->{cleanup});
        say "Created temp lib dir '$self->{lib}'" if $self->{verbose};
    }
}

1;
__END__

=head1 NAME

Syntax::Check - Wraps 'perl -c' so it works even if modules are unavailable

=for html
<a href="http://travis-ci.com/stevieb9/syntax-check"><img src="https://www.travis-ci.com/stevieb9/syntax-check.svg?branch=master"/>
<a href='https://coveralls.io/github/stevieb9/syntax-check?branch=master'><img src='https://coveralls.io/repos/stevieb9/syntax-check/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 DESCRIPTION

There is a binary already available upon install of this distribution. Please
see L<syncheck|https://metacpan.org/pod/distribution/Syntax-Check/bin/syncheck>
for details.

This module is a wrapper around C<perl -c> for situations where you're trying
to do a syntax check on a Perl file, but the libraries that are C<use>d by the
file are not available to the file.

=head1 SYNOPSIS

    use Syntax::Check;

    my $syn = Syntax::Check->new(%opts, $filename);

    $syn->check;

    # or just...

    Syntax::Check->new(%opts, $filename)->check;

=head1 METHODS

=head2 new(%p, $file)

Instantiates and returns a new C<Syntax::Check> object.

Parameters:

    keep => Bool

Optional, Bool. Delete the temporary library directory structure after the run
finishes.

Default: False

    verbose => Bool

Optional, Bool: Enable verbose output.

Default: False

    ext => 'path/to/ext/package.pm'

Optional, String: When it's set then content of that file will be interpreted as part of main package. 
As perl allows keep many packages in the same file that helps you have a deal with:

=over 4

=item *

constant exported from uninstalled packages

=item *

functions (even with protothypes) exported from uninstalled packages

=item *

custom artifacts

=back

    inc => ['/cust/lib/path/', ...]

Optional, Arrylist of Strings: It defines additional library paths to find installed packages.

    $file

Mandatory, String: The name of the Perl file to operate on.

=head2 check()

Performs the introspection of the Perl file we're operating on, hides away the
fact that we have library includes that aren't available, and performs a
C<perl -c> on the file.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
