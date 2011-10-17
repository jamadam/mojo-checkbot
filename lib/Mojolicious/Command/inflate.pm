package Mojolicious::Command::inflate;
use Mojo::Base 'Mojo::Command';

use Getopt::Long 'GetOptions';
use Mojo::Loader;

has description => <<'EOF';
Inflate embedded files to real files.
EOF
has usage => <<"EOF";
usage: $0 inflate [OPTIONS]

These options are available:
  --class <class>      Class to inflate.
  --public <path>      Path prefix for generated static files, defaults to
                       "public".
  --templates <path>   Path prefix for generated template files, defaults to
                       "templates".
EOF

# "Come on stem cells! Work your astounding scientific nonsense!"
sub run {
  my $self = shift;

  # Options
  local @ARGV = @_;
  my $class     = 'main';
  my $public    = 'public';
  my $templates = 'templates';
  GetOptions(
    'class=s'     => sub { $class     = $_[1] },
    'public=s'    => sub { $public    = $_[1] },
    'templates=s' => sub { $templates = $_[1] },
  );

  # Load class
  my $e = Mojo::Loader->load($class);
  die $e if ref $e;

  # Generate
  my $all = $self->get_all_data($class);
  for my $file (keys %$all) {
    my $prefix  = $file =~ /\.\w+\.\w+$/ ? $templates : $public;
    my $path    = $self->rel_file("$prefix/$file");
    my $content = $all->{$file};
    utf8::encode $content;
    $self->write_file($path, $content);
  }
}

1;
__END__

=head1 NAME

Mojolicious::Command::inflate - Inflate command

=head1 SYNOPSIS

  use Mojolicious::Command::inflate;

  my $inflate = Mojolicious::Command::inflate->new;
  $inflate->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::inflate> turns all your embedded templates into real
ones.

=head1 ATTRIBUTES

L<Mojolicious::Command::inflate> inherits all attributes from
L<Mojo::Command> and implements the following new ones.

=head2 C<description>

  my $description = $inflate->description;
  $inflate        = $inflate->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $inflate->usage;
  $inflate  = $inflate->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::inflate> inherits all methods from L<Mojo::Command>
and implements the following new ones.

=head2 C<run>

  $inflate->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
