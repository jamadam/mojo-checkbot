#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir(dirname(__FILE__)), './extlib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), './lib';

# Check if Mojolicious is installed
die <<EOF unless eval 'use Mojolicious::Commands; 1';
It looks like you don't have the Mojolicious framework installed.
Please visit http://mojolicio.us for detailed installation instructions.

EOF

# "My eyes! The goggles do nothing!"
Mojolicious::Commands->start;

__END__

=head1 NAME

mojo - The Mojolicious command system

=head1 SYNOPSIS

  $ mojo --help

=head1 DESCRIPTION

List and run L<Mojolicious> commands as described in
L<Mojolicious::Commands>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
