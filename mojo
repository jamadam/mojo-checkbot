#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir(dirname(__FILE__)), './extlib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), './lib';

require Mojolicious::Commands;
Mojolicious::Commands->start_app('Mojo::HelloWorld');

=encoding utf8

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
