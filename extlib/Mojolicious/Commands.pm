package Mojolicious::Commands;
use Mojo::Base 'Mojo::Command';

use Getopt::Long
  qw/GetOptions :config no_auto_abbrev no_ignore_case pass_through/;
use Mojo::Loader;

# "One day a man has everything, the next day he blows up a $400 billion
#  space station, and the next day he has nothing. It makes you think."
has hint => <<"EOF";

These options are available for all commands:
    -h, --help          Get more information on a specific command.
        --home <path>   Path to your applications home directory, defaults to
                        the value of MOJO_HOME or auto detection.
    -m, --mode <name>   Run mode of your application, defaults to the value
                        of MOJO_MODE or "development".

See '$0 help COMMAND' for more information on a specific command.
EOF
has message => <<"EOF";
usage: $0 COMMAND [OPTIONS]

Tip: CGI and PSGI environments can be automatically detected very often and
     work without commands.

These commands are currently available:
EOF
has namespaces => sub { [qw/Mojolicious::Command Mojo::Command/] };

sub detect {
  my ($self, $guess) = @_;

  # PSGI (Plack only for now)
  return 'psgi' if defined $ENV{PLACK_ENV};

  # CGI
  return 'cgi'
    if defined $ENV{PATH_INFO} || defined $ENV{GATEWAY_INTERFACE};

  # Nothing
  return $guess;
}

# Command line options for MOJO_HELP, MOJO_HOME and MOJO_MODE
BEGIN {
  GetOptions(
    'h|help'   => sub { $ENV{MOJO_HELP} = 1 },
    'home=s'   => sub { $ENV{MOJO_HOME} = $_[1] },
    'm|mode=s' => sub { $ENV{MOJO_MODE} = $_[1] }
  ) unless __PACKAGE__->detect;
}

sub run {
  my ($self, $name, @args) = @_;

  # Application loader
  return $self->app if defined $ENV{MOJO_APP_LOADER};

  # Try to detect environment
  $name = $self->detect($name) unless $ENV{MOJO_NO_DETECT};

  # Run command
  if ($name && $name =~ /^\w+$/ && ($name ne 'help' || $args[0])) {

    # Help
    my $help = $name eq 'help';
    $name = shift @args if $help;
    $help = 1           if $ENV{MOJO_HELP};

    # Try all namespaces
    my $module;
    $module = _command("${_}::$name") and last for @{$self->namespaces};

    # Command missing
    die qq/Command "$name" missing, maybe you need to install it?\n/
      unless $module;

    # Run
    return $help ? $module->new->help : $module->new->run(@args);
  }

  # Test
  return 1 if $ENV{HARNESS_ACTIVE};

  # Try all namespaces
  my $commands = [];
  my $seen     = {};
  for my $namespace (@{$self->namespaces}) {
    for my $module (@{Mojo::Loader->search($namespace)}) {
      next unless my $command = _command($module);
      $command =~ s/^$namespace\:\://;
      push @$commands, [$command => $module] unless $seen->{$command}++;
    }
  }

  # Print overview
  print $self->message;

  # Make list
  my $list = [];
  my $max  = 0;
  for my $command (@$commands) {
    my $len = length $command->[0];
    $max = $len if $len > $max;
    push @$list, [$command->[0], $command->[1]->new->description];
  }

  # Print list
  for my $command (@$list) {
    my ($name, $description) = @$command;
    print "  $name" . (' ' x ($max - length $name)) . "   $description";
  }
  return print $self->hint;
}

sub start {
  my $self = shift;

  # Executable
  $ENV{MOJO_EXE} ||= (caller)[1] if $ENV{MOJO_APP};

  # Run
  my @args = @_ ? @_ : @ARGV;
  ref $self ? $self->run(@args) : $self->new->run(@args);
}

sub start_app {
  my $self = shift;
  $ENV{MOJO_APP} = shift;
  $self->start(@_);
}

sub _command {
  my $module = shift;
  if (my $e = Mojo::Loader->load($module)) {
    return unless ref $e;
    die $e;
  }
  return $module->isa('Mojo::Command') ? $module : undef;
}

1;
__END__

=head1 NAME

Mojolicious::Commands - Commands

=head1 SYNOPSIS

  use Mojolicious::Commands;

  # Command line interface
  my $commands = Mojolicious::Commands->new;
  $commands->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Commands> is the interactive command line interface to the
L<Mojolicious> framework. It will automatically detect available commands in
the C<Mojolicious::Command> namespace.

=head1 COMMANDS

These commands are available by default.

=head2 C<help>

  $ mojo
  $ mojo help
  $ ./myapp.pl help

List available commands with short descriptions.

  $ mojo help <command>
  $ ./myapp.pl help <command>

List available options for the command with short descriptions.

=head2 C<cgi>

  $ ./myapp.pl cgi

Start application with CGI backend.

=head2 C<cpanify>

  $ mojo cpanify -u sri -p secr3t Mojolicious-Plugin-Fun-0.1.tar.gz

Upload files to CPAN.

=head2 C<daemon>

  $ ./myapp.pl daemon

Start application with standalone HTTP 1.1 server backend.

=head2 C<eval>

  $ ./myapp.pl eval 'say app->home'

Run code against application.

=head2 C<generate>

  $ mojo generate
  $ mojo generate help
  $ ./myapp.pl generate help

List available generator commands with short descriptions.

  $ mojo generate help <generator>
  $ ./myapp.pl generate help <generator>

List available options for generator command with short descriptions.

=head2 C<generate app>

  $ mojo generate app <AppName>

Generate application directory structure for a fully functional
L<Mojolicious> application.

=head2 C<generate lite_app>

  $ mojo generate lite_app

Generate a fully functional L<Mojolicious::Lite> application.

=head2 C<generate makefile>

  $ mojo generate makefile
  $ ./myapp.pl generate makefile

Generate C<Makefile.PL> file for application.

=head2 C<generate plugin>

  $ mojo generate plugin <PluginName>

Generate directory structure for a fully functional L<Mojolicious> plugin.

=head2 C<get>

  $ mojo get http://mojolicio.us
  $ ./myapp.pl get /foo

Perform requests to remote host or local application.

=head2 C<inflate>

  $ ./myapp.pl inflate

Turn templates and static files embedded in the C<DATA> sections of your
application into real files.

=head2 C<psgi>

  $ ./myapp.pl psgi

Start application with PSGI backend.

=head2 C<routes>

  $ ./myapp.pl routes

List application routes.

=head2 C<test>

  $ mojo test
  $ ./myapp.pl test
  $ ./myapp.pl test t/fun.t

Runs application tests from the C<t> directory.

=head2 C<version>

  $ mojo version
  $ ./myapp.pl version

Show version information for installed core and optional modules, very useful
for debugging.

=head1 ATTRIBUTES

L<Mojolicious::Commands> inherits all attributes from L<Mojo::Command> and
implements the following new ones.

=head2 C<hint>

  my $hint  = $commands->hint;
  $commands = $commands->hint('Foo!');

Short hint shown after listing available commands.

=head2 C<message>

  my $message = $commands->message;
  $commands   = $commands->message('Hello World!');

Short usage message shown before listing available commands.

=head2 C<namespaces>

  my $namespaces = $commands->namespaces;
  $commands      = $commands->namespaces(['Mojolicious::Commands']);

Namespaces to search for available commands, defaults to
C<Mojolicious::Command> and C<Mojo::Command>.

=head1 METHODS

L<Mojolicious::Commands> inherits all methods from L<Mojo::Command> and
implements the following new ones.

=head2 C<detect>

  my $env = $commands->detect;
  my $env = $commands->detect($guess);

Try to detect environment.

=head2 C<run>

  $commands->run;
  $commands->run(@ARGV);

Load and run commands. Automatic deployment environment detection can be
disabled with the C<MOJO_NO_DETECT> environment variable.

=head2 C<start>

  Mojolicious::Commands->start;
  Mojolicious::Commands->start(@ARGV);

Start the command line interface.

  # Always start daemon and ignore @ARGV
  Mojolicious::Commands->start('daemon', '-l', 'http://*:8080');

=head2 C<start_app>

  Mojolicious::Commands->start_app('MyApp');
  Mojolicious::Commands->start_app(MyApp => @ARGV);

Load application and start the command line interface for it.

  # Always start daemon for application and ignore @ARGV
  Mojolicious::Commands->start_app('MyApp', 'daemon', '-l', 'http://*:8080');

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
