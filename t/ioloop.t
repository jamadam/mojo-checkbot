#!/usr/bin/env perl
use Mojo::Base -strict;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '../extlib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '../lib';

# Disable Bonjour, IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_IOWATCHER} = 'Mojo::IOWatcher';
}

use Test::More tests => 36;

# "Marge, you being a cop makes you the man!
#  Which makes me the woman, and I have no interest in that,
#  besides occasionally wearing the underwear,
#  which as we discussed, is strictly a comfort thing."
use_ok 'MojoCheckbot::IOLoop';
use_ok 'Mojo::IOLoop';
use_ok 'Mojo::IOLoop::Client';
use_ok 'Mojo::IOLoop::Delay';
use_ok 'Mojo::IOLoop::Server';
use_ok 'Mojo::IOLoop::Stream';

# Custom watcher
package MyWatcher;
use Mojo::Base 'Mojo::IOWatcher';

package main;

# Watcher detection
$ENV{MOJO_IOWATCHER} = 'MyWatcherDoesNotExist';
my $loop = MojoCheckbot::IOLoop->new;
is ref $loop->iowatcher, 'Mojo::IOWatcher', 'right class';
$ENV{MOJO_IOWATCHER} = 'MyWatcher';
$loop = MojoCheckbot::IOLoop->new;
is ref $loop->iowatcher, 'MyWatcher', 'right class';

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

# Ticks
my $ticks = 0;
my $id = $loop->recurring(0 => sub { $ticks++ });

# Timer
my $flag = 0;
my $flag2;
$loop->timer(
  1 => sub {
    my $self = shift;
    $self->timer(
      1 => sub {
        shift->stop;
        $flag2 = $flag;
      }
    );
    $flag = 23;
  }
);

# HiRes timer
my $hiresflag = 0;
$loop->timer(0.25 => sub { $hiresflag = 42 });

# Start
$loop->start;

# Timer
is $flag, 23, 'recursive timer works';

# HiRes timer
is $hiresflag, 42, 'hires timer';

# Another tick
$loop->one_tick;

# Ticks
ok $ticks > 2, 'more than two ticks';

# Run again without first tick event handler
my $before = $ticks;
my $after  = 0;
$loop->recurring(0 => sub { $after++ });
$loop->drop($id);
$loop->timer(1 => sub { shift->stop });
$loop->start;
$loop->one_tick;
ok $after > 1, 'more than one tick';
is $ticks, $before, 'no additional ticks';

# Recurring timer
my $count = 0;
$loop->recurring(0.5 => sub { $count++ });
$loop->timer(3 => sub { shift->stop });
$loop->start;
$loop->one_tick;
ok $count > 1, 'more than one recurring event';
ok $count < 10, 'less than ten recurring events';

# Handle
my $port = MojoCheckbot::IOLoop->generate_port;
my $handle;
$loop->server(
  port => $port,
  sub {
    my ($loop, $stream) = @_;
    $handle = $stream->handle;
    $loop->stop;
  }
);
$loop->client((address => 'localhost', port => $port) => sub { });
$loop->start;
isa_ok $handle, 'IO::Socket', 'right reference';

# Stream
$port = MojoCheckbot::IOLoop->generate_port;
my $buffer = '';
MojoCheckbot::IOLoop->server(
  port => $port,
  sub {
    my ($loop, $stream, $id) = @_;
    $buffer .= 'accepted';
    $stream->on(
      read => sub {
        my ($stream, $chunk) = @_;
        $buffer .= $chunk;
        return unless $buffer eq 'acceptedhello';
        $stream->write('world', sub { shift->close });
      }
    );
  }
);
my $delay = MojoCheckbot::IOLoop->delay;
$delay->begin;
MojoCheckbot::IOLoop->client(
  {port => $port} => sub {
    my ($loop, $err, $stream) = @_;
    $delay->end($stream);
    $stream->on(close => sub { $buffer .= 'should not happen' });
    $stream->on(error => sub { $buffer .= 'should not happen either' });
  }
);
$handle = $delay->wait->steal_handle;
my $stream = MojoCheckbot::IOLoop->singleton->stream_class->new($handle);
$id = MojoCheckbot::IOLoop->stream($stream);
$stream->on(close => sub { MojoCheckbot::IOLoop->stop });
$stream->on(read => sub { $buffer .= pop });
$stream->write('hello');
ok MojoCheckbot::IOLoop->stream($id), 'stream exists';
MojoCheckbot::IOLoop->start;
MojoCheckbot::IOLoop->timer('0.25' => sub { MojoCheckbot::IOLoop->stop });
MojoCheckbot::IOLoop->start;
ok !MojoCheckbot::IOLoop->stream($id), 'stream does not exist anymore';
is $buffer, 'acceptedhelloworld', 'right result';

# Dropped listen socket
$port = MojoCheckbot::IOLoop->generate_port;
$id = $loop->server({port => $port} => sub { });
my $connected;
$loop->client(
  {port => $port} => sub {
    my ($loop, $err, $stream) = @_;
    $loop->drop($id);
    $loop->stop;
    $connected = 1;
  }
);
like $ENV{MOJO_REUSE}, qr/(?:^|\,)$port\:/, 'file descriptor can be reused';
$loop->start;
unlike $ENV{MOJO_REUSE}, qr/(?:^|\,)$port\:/, 'environment is clean';
ok $connected, 'connected';
$err = undef;
$loop->client(
  (port => $port) => sub {
    shift->stop;
    pop;
    $err = pop;
  }
);
$loop->start;
ok $err, 'has error';

# Dropped connection
$port = MojoCheckbot::IOLoop->generate_port;
my ($server_close, $client_close);
MojoCheckbot::IOLoop->server(
  (port => $port) => sub {
    my ($loop, $stream) = @_;
    $stream->on(close => sub { $server_close++ });
  }
);
$id = MojoCheckbot::IOLoop->client(
  (port => $port) => sub {
    my ($loop, $err, $stream) = @_;
    $stream->on(close => sub { $client_close++ });
    $loop->drop($id);
  }
);
MojoCheckbot::IOLoop->timer('0.5' => sub { shift->stop });
MojoCheckbot::IOLoop->start;
is $server_close, 1, 'server emitted close event once';
is $client_close, 1, 'client emitted close event once';

# Stream throttling
$port = MojoCheckbot::IOLoop->generate_port;
my ($client, $server, $client_after, $server_before, $server_after) = '';
MojoCheckbot::IOLoop->server(
  {port => $port} => sub {
    my ($loop, $stream) = @_;
    $stream->timeout(0)->on(
      read => sub {
        my ($stream, $chunk) = @_;
        MojoCheckbot::IOLoop->timer(
          '0.5' => sub {
            $server_before = $server;
            $stream->stop;
            $stream->write('works!');
            MojoCheckbot::IOLoop->timer(
              '0.5' => sub {
                $server_after = $server;
                $client_after = $client;
                $stream->start;
                MojoCheckbot::IOLoop->timer('0.5' => sub { MojoCheckbot::IOLoop->stop });
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

# Graceful shutdown
$err = '';
$loop = MojoCheckbot::IOLoop->new(max_connections => 0);
$loop->drop($loop->client({port => $loop->generate_port}));
$loop->timer(
  1 => sub {
    shift->stop;
    $err = 'failed!';
  }
);
$loop->start;
ok !$err, 'no error';
is $loop->max_connections, 0, 'right value';

# Defaults
is Mojo::IOLoop::Client->new->iowatcher, MojoCheckbot::IOLoop->singleton->iowatcher,
  'right default';
is Mojo::IOLoop::Delay->new->ioloop, MojoCheckbot::IOLoop->singleton, 'right default';
is Mojo::IOLoop::Server->new->iowatcher,
  MojoCheckbot::IOLoop->singleton->iowatcher, 'right default';
is Mojo::IOLoop::Stream->new->iowatcher, MojoCheckbot::IOLoop->singleton->iowatcher,
  'right default';
