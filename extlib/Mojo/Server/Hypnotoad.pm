package Mojo::Server::Hypnotoad;
use Mojo::Base -base;

# "Bender: I was God once.
#  God: Yes, I saw. You were doing well, until everyone died."
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Mojo::Server::Prefork;
use Mojo::Util 'steady_time';
use Scalar::Util 'weaken';

has prefork => sub { Mojo::Server::Prefork->new };
has upgrade_timeout => 60;

sub configure {
  my ($self, $name) = @_;

  # Hypnotoad settings
  my $prefork = $self->prefork;
  my $c = $prefork->app->config($name) || {};
  $c->{listen} ||= ['http://*:8080'];
  $self->upgrade_timeout($c->{upgrade_timeout}) if $c->{upgrade_timeout};

  # Prefork settings
  $prefork->reverse_proxy($c->{proxy}) if defined $c->{proxy};
  $prefork->max_clients($c->{clients}) if $c->{clients};
  $prefork->max_requests($c->{keep_alive_requests})
    if $c->{keep_alive_requests};
  defined $c->{$_} and $prefork->$_($c->{$_})
    for qw(accept_interval accepts backlog graceful_timeout group),
    qw(heartbeat_interval heartbeat_timeout inactivity_timeout listen),
    qw(lock_file lock_timeout multi_accept pid_file user workers);
}

sub run {
  my ($self, $app) = @_;

  # No Windows support
  _exit('Hypnotoad not available for Windows.') if $^O eq 'MSWin32';

  # Remember executable and application for later
  $ENV{HYPNOTOAD_EXE} ||= $0;
  $0 = $ENV{HYPNOTOAD_APP} ||= abs_path $app;

  # This is a production server
  $ENV{MOJO_MODE} ||= 'production';

  # Clean start (to make sure everything works)
  die "Can't exec: $!" if !$ENV{HYPNOTOAD_REV}++ && !exec $ENV{HYPNOTOAD_EXE};

  # Preload application and configure server
  my $prefork = $self->prefork->cleanup(0);
  {
    my $config = $prefork->load_app($app)->config->{hypnotoad};
    $config->{pid_file} = defined $config->{pid_file} ? $config->{pid_file} : catfile dirname($ENV{HYPNOTOAD_APP}), 'hypnotoad.pid';
  }
  $self->configure('hypnotoad');
  weaken $self;
  $prefork->on(wait   => sub { $self->_manage });
  $prefork->on(reap   => sub { $self->_reap(pop) });
  $prefork->on(finish => sub { $self->{finished} = 1 });

  # Testing
  _exit('Everything looks good!') if $ENV{HYPNOTOAD_TEST};

  # Stop running server
  $self->_stop if $ENV{HYPNOTOAD_STOP};

  # Initiate hot deployment
  $self->_hot_deploy unless $ENV{HYPNOTOAD_PID};

  # Daemonize as early as possible (but not for restarts)
  $prefork->daemonize
    if !$ENV{HYPNOTOAD_FOREGROUND} && $ENV{HYPNOTOAD_REV} < 3;

  # Start accepting connections
  local $SIG{USR2} = sub { $self->{upgrade} ||= steady_time };
  $prefork->cleanup(1)->run;
}

sub _exit { say shift and exit 0 }

sub _hot_deploy {

  # Make sure server is running
  return unless my $pid = shift->prefork->check_pid;

  # Start hot deployment
  kill 'USR2', $pid;
  _exit("Starting hot deployment for Hypnotoad server $pid.");
}

sub _manage {
  my $self = shift;

  # Upgraded
  my $log = $self->prefork->app->log;
  if ($ENV{HYPNOTOAD_PID} && $ENV{HYPNOTOAD_PID} ne $$) {
    $log->info("Upgrade successful, stopping $ENV{HYPNOTOAD_PID}.");
    kill 'QUIT', $ENV{HYPNOTOAD_PID};
  }
  $ENV{HYPNOTOAD_PID} = $$ unless (defined $ENV{HYPNOTOAD_PID} ? $ENV{HYPNOTOAD_PID} : '') eq $$;

  # Upgrade
  if ($self->{upgrade} && !$self->{finished}) {

    # Fresh start
    unless ($self->{new}) {
      $log->info('Starting zero downtime software upgrade.');
      die "Can't fork: $!" unless defined(my $pid = $self->{new} = fork);
      exec($ENV{HYPNOTOAD_EXE}) or die("Can't exec: $!") unless $pid;
    }

    # Timeout
    kill 'KILL', $self->{new}
      if $self->{upgrade} + $self->upgrade_timeout <= steady_time;
  }
}

sub _reap {
  my ($self, $pid) = @_;

  # Clean up failed upgrade
  return unless ($self->{new} || '') eq $pid;
  $self->prefork->app->log->error('Zero downtime software upgrade failed.');
  delete @$self{qw(new upgrade)};
}

sub _stop {
  _exit('Hypnotoad server not running.')
    unless my $pid = shift->prefork->check_pid;
  kill 'QUIT', $pid;
  _exit("Stopping Hypnotoad server $pid gracefully.");
}

1;

=encoding utf8

=head1 NAME

Mojo::Server::Hypnotoad - ALL GLORY TO THE HYPNOTOAD!

=head1 SYNOPSIS

  use Mojo::Server::Hypnotoad;

  my $hypnotoad = Mojo::Server::Hypnotoad->new;
  $hypnotoad->run('/home/sri/myapp.pl');

=head1 DESCRIPTION

L<Mojo::Server::Hypnotoad> is a full featured, UNIX optimized, preforking
non-blocking I/O HTTP and WebSocket server, built around the very well tested
and reliable L<Mojo::Server::Prefork>, with IPv6, TLS, Comet (long polling),
keep-alive, connection pooling, timeout, cookie, multipart, multiple event
loop and hot deployment support that just works. Note that the server uses
signals for process management, so you should avoid modifying signal handlers
in your applications.

To start applications with it you can use the L<hypnotoad> script, for
L<Mojolicious> and L<Mojolicious::Lite> applications it will default to
C<production> mode.

  $ hypnotoad myapp.pl
  Server available at http://127.0.0.1:8080.

You can run the same command again for automatic hot deployment.

  $ hypnotoad myapp.pl
  Starting hot deployment for Hypnotoad server 31841.

This second invocation will load the application again, detect the process id
file with it, and send a L</"USR2"> signal to the already running server.

For better scalability (epoll, kqueue) and to provide IPv6 as well as TLS
support, the optional modules L<EV> (4.0+), L<IO::Socket::IP> (0.20+) and
L<IO::Socket::SSL> (1.84+) will be used automatically by L<Mojo::IOLoop> if
they are installed. Individual features can also be disabled with the
C<MOJO_NO_IPV6> and C<MOJO_NO_TLS> environment variables.

See L<Mojolicious::Guides::Cookbook/"DEPLOYMENT"> for more.

=head1 MANAGER SIGNALS

The L<Mojo::Server::Hypnotoad> manager process can be controlled at runtime
with the following signals.

=head2 INT, TERM

Shutdown server immediately.

=head2 QUIT

Shutdown server gracefully.

=head2 TTIN

Increase worker pool by one.

=head2 TTOU

Decrease worker pool by one.

=head2 USR2

Attempt zero downtime software upgrade (hot deployment) without losing any
incoming connections.

  Manager (old)
  |- Worker [1]
  |- Worker [2]
  |- Worker [3]
  |- Worker [4]
  +- Manager (new)
     |- Worker [1]
     |- Worker [2]
     |- Worker [3]
     +- Worker [4]

The new manager will automatically send a L</"QUIT"> signal to the old manager
and take over serving requests after starting up successfully.

=head1 WORKER SIGNALS

L<Mojo::Server::Hypnotoad> worker processes can be controlled at runtime with
the following signals.

=head2 INT, TERM

Stop worker immediately.

=head2 QUIT

Stop worker gracefully.

=head1 SETTINGS

L<Mojo::Server::Hypnotoad> can be configured with the following settings, see
L<Mojolicious::Guides::Cookbook/"Hypnotoad"> for examples.

=head2 accept_interval

  accept_interval => 0.5

Interval in seconds for trying to reacquire the accept mutex, defaults to the
value of L<Mojo::IOLoop/"accept_interval">. Note that changing this value can
affect performance and idle CPU usage.

=head2 accepts

  accepts => 100

Maximum number of connections a worker is allowed to accept before stopping
gracefully, defaults to the value of L<Mojo::Server::Prefork/"accepts">.
Setting the value to C<0> will allow workers to accept new connections
indefinitely. Note that up to half of this value can be subtracted randomly to
improve load balancing.

=head2 backlog

  backlog => 128

Listen backlog size, defaults to the value of
L<Mojo::Server::Daemon/"backlog">.

=head2 clients

  clients => 100

Maximum number of concurrent client connections per worker process, defaults
to the value of L<Mojo::IOLoop/"max_connections">. Note that high concurrency
works best with applications that perform mostly non-blocking operations, to
optimize for blocking operations you can decrease this value and increase
L</"workers"> instead for better performance.

=head2 graceful_timeout

  graceful_timeout => 15

Maximum amount of time in seconds stopping a worker gracefully may take before
being forced, defaults to the value of
L<Mojo::Server::Prefork/"graceful_timeout">.

=head2 group

  group => 'staff'

Group name for worker processes, defaults to the value of
L<Mojo::Server/"group">.

=head2 heartbeat_interval

  heartbeat_interval => 3

Heartbeat interval in seconds, defaults to the value of
L<Mojo::Server::Prefork/"heartbeat_interval">.

=head2 heartbeat_timeout

  heartbeat_timeout => 2

Maximum amount of time in seconds before a worker without a heartbeat will be
stopped gracefully, defaults to the value of
L<Mojo::Server::Prefork/"heartbeat_timeout">.

=head2 inactivity_timeout

  inactivity_timeout => 10

Maximum amount of time in seconds a connection can be inactive before getting
closed, defaults to the value of L<Mojo::Server::Daemon/"inactivity_timeout">.
Setting the value to C<0> will allow connections to be inactive indefinitely.

=head2 keep_alive_requests

  keep_alive_requests => 50

Number of keep-alive requests per connection, defaults to the value of
L<Mojo::Server::Daemon/"max_requests">.

=head2 listen

  listen => ['http://*:80']

List of one or more locations to listen on, defaults to C<http://*:8080>. See
also L<Mojo::Server::Daemon/"listen"> for more examples.

=head2 lock_file

  lock_file => '/tmp/hypnotoad.lock'

Full path of accept mutex lock file prefix, to which the process id will be
appended, defaults to the value of L<Mojo::Server::Prefork/"lock_file">.

=head2 lock_timeout

  lock_timeout => 0.5

Maximum amount of time in seconds a worker may block when waiting for the
accept mutex, defaults to the value of
L<Mojo::Server::Prefork/"lock_timeout">. Note that changing this value can
affect performance and idle CPU usage.

=head2 multi_accept

  multi_accept => 100

Number of connections to accept at once, defaults to the value of
L<Mojo::IOLoop/"multi_accept">.

=head2 pid_file

  pid_file => '/var/run/hypnotoad.pid'

Full path to process id file, defaults to C<hypnotoad.pid> in the same
directory as the application. Note that this value can only be changed after
the server has been stopped.

=head2 proxy

  proxy => 1

Activate reverse proxy support, which allows for the C<X-Forwarded-For> and
C<X-Forwarded-Proto> headers to be picked up automatically, defaults to the
value of L<Mojo::Server/"reverse_proxy">.

=head2 upgrade_timeout

  upgrade_timeout => 45

Maximum amount of time in seconds a zero downtime software upgrade may take
before getting canceled, defaults to the value of L</"upgrade_timeout">.

=head2 user

  user => 'sri'

Username for worker processes, defaults to the value of
L<Mojo::Server/"user">.

=head2 workers

  workers => 10

Number of worker processes, defaults to the value of
L<Mojo::Server::Prefork/"workers">. A good rule of thumb is two worker
processes per CPU core for applications that perform mostly non-blocking
operations, blocking operations often require more and benefit from decreasing
the number of concurrent L</"clients"> (often as low as C<1>).

=head1 ATTRIBUTES

L<Mojo::Server::Hypnotoad> implements the following attributes.

=head2 prefork

  my $prefork = $hypnotoad->prefork;
  $hypnotoad  = $hypnotoad->prefork(Mojo::Server::Prefork->new);

L<Mojo::Server::Prefork> object this server manages.

=head2 upgrade_timeout

  my $timeout = $hypnotoad->upgrade_timeout;
  $hypnotoad  = $hypnotoad->upgrade_timeout(15);

Maximum amount of time in seconds a zero downtime software upgrade may take
before getting canceled, defaults to C<60>.

=head1 METHODS

L<Mojo::Server::Hypnotoad> inherits all methods from L<Mojo::Base> and
implements the following new ones.

=head2 configure

  $hypnotoad->configure('hypnotoad');

Configure server from application settings.

=head2 run

  $hypnotoad->run('script/myapp');

Run server for application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
