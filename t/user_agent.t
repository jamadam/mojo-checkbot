#!/usr/bin/env perl
use Mojo::Base -strict;
use lib './extlib';
use Test::More tests => 68;
use_ok 'Mojo::UserAgent';
use Mojo::IOLoop;
use Mojolicious::Lite;

my $port2   = Mojo::IOLoop->generate_port;
Mojo::IOLoop->listen(
  port      => $port2,
  on_read => sub {
    my ($loop, $id, $chunk) = @_;
    warn $id;
    $loop->write(
      $id => "HTTP/1.1 200 OK\x0d\x0a"
        . "Content-Type: text/plain\x0d\x0a\x0d\x0aworks too!",
      sub { shift->drop(shift) }
    );
  },
);

my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton)->app(app);
my $tx = $ua->get("http://localhost:$port2/");
ok $tx->success, 'successful';
ok !$tx->error, 'no error';
is $tx->kept_alive, undef, 'kept connection not alive';
is $tx->keep_alive, 1,     'keep connection alive';
is $tx->res->code, 200,          'right status';
is $tx->res->body, 'works too!', 'right content';
