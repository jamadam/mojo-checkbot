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

use Test::More tests => 22;

# "Marge, you being a cop makes you the man!
#  Which makes me the woman, and I have no interest in that,
#  besides occasionally wearing the underwear,
#  which as we discussed, is strictly a comfort thing."
use_ok 'MojoCheckbot::IOLoop';

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
my $error;
MojoCheckbot::IOLoop->defer(
  sub {
    eval { MojoCheckbot::IOLoop->start };
    $error = $@;
    MojoCheckbot::IOLoop->stop;
  }
);
MojoCheckbot::IOLoop->start;
like $error, qr/^Mojo::IOLoop already running/, 'right error';

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
ok $count > 3, 'more than three recurring events';

# Handle
my $port = MojoCheckbot::IOLoop->generate_port;
my $handle;
$loop->listen(
  port      => $port,
  on_accept => sub {
    my $self = shift;
    $handle = $self->stream(pop)->handle;
    $self->stop;
  },
  on_read  => sub { },
  on_error => sub { }
);
$loop->connect(
  address  => 'localhost',
  port     => $port,
  on_read  => sub { },
  on_error => sub { }
);
$loop->start;
isa_ok $handle, 'IO::Socket', 'right reference';

# Stream
$port = MojoCheckbot::IOLoop->generate_port;
my $buffer = '';
MojoCheckbot::IOLoop->listen(
  port      => $port,
  on_accept => sub { $buffer .= 'accepted' },
  on_read   => sub {
    my ($loop, $id, $chunk) = @_;
    $buffer .= $chunk;
    return unless $buffer eq 'acceptedhello';
    $loop->write($id => 'world');
    $loop->drop($id);
  }
);
my $t = MojoCheckbot::IOLoop->trigger;
MojoCheckbot::IOLoop->connect(
  address    => 'localhost',
  port       => $port,
  on_connect => $t->begin,
  on_close   => sub { $buffer .= 'should not happen' },
  on_error   => sub { $buffer .= 'should not happen either' },
);
$handle = MojoCheckbot::IOLoop->stream($t->start)->steal_handle;
my $stream = MojoCheckbot::IOLoop->singleton->stream_class->new($handle);
$id = MojoCheckbot::IOLoop->stream(
  $stream => {
    on_close => sub { MojoCheckbot::IOLoop->stop },
    on_read  => sub { $buffer .= pop }
  }
);
$stream->write('hello');
ok MojoCheckbot::IOLoop->stream($id), 'stream exists';
MojoCheckbot::IOLoop->start;
ok !MojoCheckbot::IOLoop->stream($id), 'stream does not exist anymore';
is $buffer, 'acceptedhelloworld', 'right result';

# Dropped listen socket
$port  = MojoCheckbot::IOLoop->generate_port;
$id    = $loop->listen({port => $port});
$error = undef;
my $connected;
my %args = (
  address    => 'localhost',
  port       => $port,
  on_connect => sub {
    my $loop = shift;
    $loop->drop($id);
    $loop->stop;
    $connected = 1;
  },
  on_error => sub {
    shift->stop;
    $error = pop;
  }
);
$loop->connect(\%args);
like $ENV{MOJO_REUSE}, qr/(?:^|\,)$port\:/, 'file descriptor can be reused';
$loop->start;
unlike $ENV{MOJO_REUSE}, qr/(?:^|\,)$port\:/, 'environment is clean';
ok $connected, 'connected';
ok !$error, 'no error';
$connected = $error = undef;
$loop->connect(
  address    => 'localhost',
  port       => $port,
  on_connect => sub {
    shift->stop;
    $connected = 1;
  },
  on_error => sub {
    shift->stop;
    $error = pop;
  }
);
$loop->start;
ok !$connected, 'not connected';
ok $error, 'has error';

# Dropped connection
$port = MojoCheckbot::IOLoop->generate_port;
my ($server_close, $client_close);
MojoCheckbot::IOLoop->listen(
  address  => 'localhost',
  port     => $port,
  on_close => sub { $server_close++ }
);
MojoCheckbot::IOLoop->connect(
  address    => 'localhost',
  port       => $port,
  on_close   => sub { $client_close++ },
  on_connect => sub { shift->drop(shift) }
);
MojoCheckbot::IOLoop->timer('0.5' => sub { shift->stop });
MojoCheckbot::IOLoop->start;
is $server_close, 1, 'server emitted close event once';
is $client_close, 1, 'client emitted close event once';
