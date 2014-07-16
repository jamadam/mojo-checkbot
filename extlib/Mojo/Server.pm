package Mojo::Server;
use Mojo::Base 'Mojo::EventEmitter';

use Carp 'croak';
use Mojo::Loader;
use Mojo::Util 'md5_sum';
use POSIX;
use Scalar::Util 'blessed';

has app => sub { shift->build_app('Mojo::HelloWorld') };
has [qw(group user)];
has reverse_proxy => sub { $ENV{MOJO_REVERSE_PROXY} };

sub build_app {
  my ($self, $app) = @_;
  local $ENV{MOJO_EXE};
  return $app->new unless my $e = Mojo::Loader->new->load($app);
  die ref $e ? $e : qq{Couldn't find application class "$app".\n};
}

sub build_tx {
  my $self = shift;
  my $tx   = $self->app->build_tx;
  $tx->req->reverse_proxy(1) if $self->reverse_proxy;
  return $tx;
}

sub daemonize {

  # Fork and kill parent
  die "Can't fork: $!" unless defined(my $pid = fork);
  exit 0 if $pid;
  POSIX::setsid or die "Can't start a new session: $!";

  # Close filehandles
  open STDIN,  '</dev/null';
  open STDOUT, '>/dev/null';
  open STDERR, '>&STDOUT';
}

sub load_app {
  my ($self, $path) = @_;

  # Clean environment (reset FindBin defensively)
  {
    local $0 = $path;
    require FindBin;
    FindBin->again;
    local $ENV{MOJO_APP_LOADER} = 1;
    local $ENV{MOJO_EXE};

    # Try to load application from script into sandbox
    my $app = eval sprintf <<'EOF', md5_sum($path . $$);
package Mojo::Server::SandBox::%s;
my $app = do $path;
if (!$app && (my $e = $@ || $!)) { die $e }
$app;
EOF
    die qq{Couldn't load application from file "$path": $@} if !$app && $@;
    die qq{File "$path" did not return an application object.\n}
      unless blessed $app && $app->isa('Mojo');
    $self->app($app);
  };
  FindBin->again;

  return $self->app;
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->on(request => sub { shift->app->handler(shift) });
  return $self;
}

sub run { croak 'Method "run" not implemented by subclass' }

sub setuidgid {
  my $self = shift;

  # Group
  if (my $group = $self->group) {
    return $self->_log(qq{Group "$group" does not exist.})
      unless defined(my $gid = getgrnam $group);
    return $self->_log(qq{Can't switch to group "$group": $!})
      unless POSIX::setgid($gid);
  }

  # User
  return $self unless my $user = $self->user;
  return $self->_log(qq{User "$user" does not exist.})
    unless defined(my $uid = getpwnam $user);
  return $self->_log(qq{Can't switch to user "$user": $!})
    unless POSIX::setuid($uid);

  return $self;
}

sub _log { $_[0]->app->log->error($_[1]) and return $_[0] }

1;

=encoding utf8

=head1 NAME

Mojo::Server - HTTP server base class

=head1 SYNOPSIS

  package Mojo::Server::MyServer;
  use Mojo::Base 'Mojo::Server';

  sub run {
    my $self = shift;

    # Get a transaction
    my $tx = $self->build_tx;

    # Emit "request" event
    $self->emit(request => $tx);
  }

=head1 DESCRIPTION

L<Mojo::Server> is an abstract HTTP server base class.

=head1 EVENTS

L<Mojo::Server> inherits all events from L<Mojo::EventEmitter> and can emit
the following new ones.

=head2 request

  $server->on(request => sub {
    my ($server, $tx) = @_;
    ...
  });

Emitted when a request is ready and needs to be handled.

  $server->unsubscribe('request');
  $server->on(request => sub {
    my ($server, $tx) = @_;
    $tx->res->code(200);
    $tx->res->headers->content_type('text/plain');
    $tx->res->body('Hello World!');
    $tx->resume;
  });

=head1 ATTRIBUTES

L<Mojo::Server> implements the following attributes.

=head2 app

  my $app = $server->app;
  $server = $server->app(MojoSubclass->new);

Application this server handles, defaults to a L<Mojo::HelloWorld> object.

=head2 group

  my $group = $server->group;
  $server   = $server->group('users');

Group for server process.

=head2 reverse_proxy

  my $bool = $server->reverse_proxy;
  $server  = $server->reverse_proxy($bool);

This server operates behind a reverse proxy, defaults to the value of the
C<MOJO_REVERSE_PROXY> environment variable.

=head2 user

  my $user = $server->user;
  $server  = $server->user('web');

User for the server process.

=head1 METHODS

L<Mojo::Server> inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 build_app

  my $app = $server->build_app('Mojo::HelloWorld');

Build application from class.

=head2 build_tx

  my $tx = $server->build_tx;

Let application build a transaction.

=head2 daemonize

  $server->daemonize;

Daemonize server process.

=head2 load_app

  my $app = $server->load_app('/home/sri/myapp.pl');

Load application from script.

  say Mojo::Server->new->load_app('./myapp.pl')->home;

=head2 new

  my $server = Mojo::Server->new;

Construct a new L<Mojo::Server> object and subscribe to L</"request"> event
with default request handling.

=head2 run

  $server->run;

Run server. Meant to be overloaded in a subclass.

=head2 setuidgid

  $server = $server->setuidgid;

Set L</"user"> and L</"group"> for process.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
