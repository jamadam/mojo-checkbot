use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use MojoCheckbot::IOLoop;
use Mojo::IOLoop::Client;
use Mojo::IOLoop::Delay;
use Mojo::IOLoop::Server;
use Mojo::IOLoop::Stream;

# Custom reactor
package MyReactor;
use Mojo::Base 'Mojo::Reactor::Poll';

package main;

# Reactor detection
$ENV{MOJO_REACTOR} = 'MyReactorDoesNotExist';
my $loop = MojoCheckbot::IOLoop->new;
is ref $loop->reactor, 'Mojo::Reactor::Poll', 'right class';
$ENV{MOJO_REACTOR} = 'MyReactor';
$loop = MojoCheckbot::IOLoop->new;
is ref $loop->reactor, 'MyReactor', 'right class';

# Double start
my $err;
MojoCheckbot::IOLoop->timer(
  0 => sub {
    eval { MojoCheckbot::IOLoop->start };
    $err = $@;
    MojoCheckbot::IOLoop->stop;
  }
);
MojoCheckbot::IOLoop->start;
like $err, qr/^Mojo::IOLoop already running/, 'right error';

# Basic functionality
my ($ticks, $timer, $hirestimer);
my $id = $loop->recurring(0 => sub { $ticks++ });
$loop->timer(
  1 => sub {
    shift->timer(0 => sub { shift->stop });
    $timer++;
  }
);
$loop->timer(0.25 => sub { $hirestimer++ });
$loop->start;
ok $timer,      'recursive timer works';
ok $hirestimer, 'hires timer works';
$loop->one_tick;
ok $ticks > 2, 'more than two ticks';

# Run again without first tick event handler
my $before = $ticks;
my $after;
my $id2 = $loop->recurring(0 => sub { $after++ });
$loop->remove($id);
$loop->timer(0.5 => sub { shift->stop });
$loop->start;
$loop->one_tick;
$loop->remove($id2);
ok $after > 1, 'more than one tick';
is $ticks, $before, 'no additional ticks';

# Recurring timer
my $count;
$id = $loop->recurring(0.1 => sub { $count++ });
$loop->timer(0.5 => sub { shift->stop });
$loop->start;
$loop->one_tick;
$loop->remove($id);
ok $count > 1, 'more than one recurring event';
ok $count < 10, 'less than ten recurring events';

# Handle
my $port = MojoCheckbot::IOLoop->generate_port;
my ($handle, $handle2);
$id = MojoCheckbot::IOLoop->server(
  (address => '127.0.0.1', port => $port) => sub {
    my ($loop, $stream) = @_;
    $handle = $stream->handle;
    MojoCheckbot::IOLoop->stop;
  }
);
MojoCheckbot::IOLoop->acceptor($id)->on(accept => sub { $handle2 = pop });
$id2
  = MojoCheckbot::IOLoop->client((address => 'localhost', port => $port) => sub { });
MojoCheckbot::IOLoop->start;
MojoCheckbot::IOLoop->remove($id);
MojoCheckbot::IOLoop->remove($id2);
is $handle, $handle2, 'handles are equal';
isa_ok $handle, 'IO::Socket', 'right reference';

# The poll reactor stops when there are no events being watched anymore
my $time = time;
MojoCheckbot::IOLoop->start;
MojoCheckbot::IOLoop->one_tick;
ok time < ($time + 10), 'stopped automatically';

# Stream
$port = MojoCheckbot::IOLoop->generate_port;
my $buffer = '';
MojoCheckbot::IOLoop->server(
  (address => '127.0.0.1', port => $port) => sub {
    my ($loop, $stream, $id) = @_;
    $buffer .= 'accepted';
    $stream->on(
      read => sub {
        my ($stream, $chunk) = @_;
        $buffer .= $chunk;
        return unless $buffer eq 'acceptedhello';
        $stream->write('wo')->write('')->write('rld' => sub { shift->close });
      }
    );
  }
);
my $delay = MojoCheckbot::IOLoop->delay;
my $end   = $delay->begin(0);
MojoCheckbot::IOLoop->client(
  {port => $port} => sub {
    my ($loop, $err, $stream) = @_;
    $end->($stream);
    $stream->on(close => sub { $buffer .= 'should not happen' });
    $stream->on(error => sub { $buffer .= 'should not happen either' });
  }
);
$handle = $delay->wait->steal_handle;
my $stream = Mojo::IOLoop::Stream->new($handle);
is $stream->timeout, 15, 'right default';
is $stream->timeout(16)->timeout, 16, 'right timeout';
$id = MojoCheckbot::IOLoop->stream($stream);
$stream->on(close => sub { MojoCheckbot::IOLoop->stop });
$stream->on(read => sub { $buffer .= pop });
$stream->write('hello');
ok !!MojoCheckbot::IOLoop->stream($id), 'stream exists';
is $stream->timeout, 16, 'right timeout';
MojoCheckbot::IOLoop->start;
MojoCheckbot::IOLoop->timer(0.25 => sub { MojoCheckbot::IOLoop->stop });
MojoCheckbot::IOLoop->start;
ok !MojoCheckbot::IOLoop->stream($id), 'stream does not exist anymore';
is $buffer, 'acceptedhelloworld', 'right result';

# Removed listen socket
$port = MojoCheckbot::IOLoop->generate_port;
$id = $loop->server({address => '127.0.0.1', port => $port} => sub { });
my $connected;
$loop->client(
  {port => $port} => sub {
    my ($loop, $err, $stream) = @_;
    $loop->remove($id);
    $loop->stop;
    $connected = 1;
  }
);
like $ENV{MOJO_REUSE}, qr/(?:^|\,)${port}:/, 'file descriptor can be reused';
$loop->start;
unlike $ENV{MOJO_REUSE}, qr/(?:^|\,)${port}:/, 'environment is clean';
ok $connected, 'connected';
$err = undef;
$loop->client(
  (port => $port) => sub {
    shift->stop;
    $err = shift;
  }
);
$loop->start;
ok $err, 'has error';

# Removed connection (with delay)
my $removed;
$delay = MojoCheckbot::IOLoop->delay(sub { $removed++ });
$port  = MojoCheckbot::IOLoop->generate_port;
$end   = $delay->begin;
MojoCheckbot::IOLoop->server(
  (address => '127.0.0.1', port => $port) => sub {
    my ($loop, $stream) = @_;
    $stream->on(close => $end);
  }
);
my $end2 = $delay->begin;
$id = MojoCheckbot::IOLoop->client(
  (port => $port) => sub {
    my ($loop, $err, $stream) = @_;
    $stream->on(close => $end2);
    $loop->remove($id);
  }
);
$delay->wait;
is $removed, 1, 'connection has been removed';

# Stream throttling
$port = MojoCheckbot::IOLoop->generate_port;
my ($client, $server, $client_after, $server_before, $server_after);
MojoCheckbot::IOLoop->server(
  {address => '127.0.0.1', port => $port} => sub {
    my ($loop, $stream) = @_;
    $stream->timeout(0)->on(
      read => sub {
        my ($stream, $chunk) = @_;
        MojoCheckbot::IOLoop->timer(
          0.5 => sub {
            $server_before = $server;
            $stream->stop;
            $stream->write('works!');
            MojoCheckbot::IOLoop->timer(
              0.5 => sub {
                $server_after = $server;
                $client_after = $client;
                $stream->start;
                MojoCheckbot::IOLoop->timer(0.5 => sub { MojoCheckbot::IOLoop->stop });
              }
            );
          }
        ) unless $server;
        $server .= $chunk;
      }
    );
  }
);
MojoCheckbot::IOLoop->client(
  {port => $port} => sub {
    my ($loop, $err, $stream) = @_;
    my $drain;
    $drain = sub { shift->write('1', $drain) };
    $stream->$drain();
    $stream->on(read => sub { $client .= pop });
  }
);
MojoCheckbot::IOLoop->start;
is $server_before, $server_after, 'stream has been paused';
ok length($server) > length($server_after), 'stream has been resumed';
is $client, $client_after, 'stream was writable while paused';
is $client, 'works!', 'full message has been written';

# Graceful shutdown (max_connections)
$err = '';
$loop = MojoCheckbot::IOLoop->new(max_connections => 0);
$loop->remove($loop->client({port => $loop->generate_port} => sub { }));
$loop->timer(3 => sub { shift->stop; $err = 'failed' });
$loop->start;
ok !$err, 'no error';
is $loop->max_connections, 0, 'right value';

# Graceful shutdown (max_accepts)
$err  = '';
$loop = MojoCheckbot::IOLoop->new(max_accepts => 1);
$port = $loop->generate_port;
$loop->server(
  {address => '127.0.0.1', port => $port} => sub { shift; shift->close });
$loop->client({port => $port} => sub { });
$loop->timer(3 => sub { shift->stop; $err = 'failed' });
$loop->start;
ok !$err, 'no error';
is $loop->max_accepts, 1, 'right value';

# Exception in timer
{
  local *STDERR;
  open STDERR, '>', \my $err;
  my $loop = MojoCheckbot::IOLoop->new;
  $loop->timer(0 => sub { die 'Bye!' });
  $loop->start;
  like $err, qr/^MyReactor:.*Bye!/, 'right error';
}

# Defaults
is(
  Mojo::IOLoop::Client->new->reactor,
  MojoCheckbot::IOLoop->singleton->reactor,
  'right default'
);
is(Mojo::IOLoop::Delay->new->ioloop, MojoCheckbot::IOLoop->singleton, 'right default');
is(
  Mojo::IOLoop::Server->new->reactor,
  MojoCheckbot::IOLoop->singleton->reactor,
  'right default'
);
is(
  Mojo::IOLoop::Stream->new->reactor,
  MojoCheckbot::IOLoop->singleton->reactor,
  'right default'
);

done_testing();
