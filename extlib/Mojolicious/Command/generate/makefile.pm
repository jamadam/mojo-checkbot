package Mojolicious::Command::generate::makefile;
use Mojo::Base 'Mojo::Command';

has description => qq/Generate "Makefile.PL".\n/;
has usage       => "usage: $0 generate makefile\n";

# "If we don't go back there and make that event happen,
#  the entire universe will be destroyed...
#  And as an environmentalist, I'm against that."
sub run { shift->render_to_rel_file('makefile', 'Makefile.PL') }

1;
__DATA__

@@ makefile
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {'Mojolicious' => '2.50'},
  test      => {TESTS => 't/*.t'}
);

__END__
=head1 NAME

Mojolicious::Command::generate::makefile - Makefile generator command

=head1 SYNOPSIS

  use Mojolicious::Command::generate::makefile;

  my $makefile = Mojolicious::Command::generate::makefile->new;
  $makefile->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::generate::makefile> is a makefile generator.

=head1 ATTRIBUTES

L<Mojolicious::Command::generate::makefile> inherits all attributes from
L<Mojo::Command> and implements the following new ones.

=head2 C<description>

  my $description = $makefile->description;
  $makefile       = $makefile->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $makefile->usage;
  $makefile = $makefile->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::makefile> inherits all methods from
L<Mojo::Command> and implements the following new ones.

=head2 C<run>

  $makefile->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
