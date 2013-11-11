#!/usr/bin/env perl
use Mojo::Base -strict;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '../extlib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '../lib';
use Mojo::IOLoop;
use MojoCheckbot::UserAgent;
use Test::More;
use Test::Mojo;

use Test::More tests => 5;

my $ua = MojoCheckbot::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
my $port;
my $port2;
my $port3;

{
    $port = Mojo::IOLoop->generate_port;
    Mojo::IOLoop->server(port => $port, sub {
        my ($loop, $stream) = @_;
        $stream->on(read => sub {
            my ($stream, $chunk) = @_;
            like $chunk, qr{Authorization: Basic YTpi}, 'right Authorization header';
            $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
                    . "Content-Type: text/html\x0d\x0a\x0d\x0a",
            );
            $stream->close
        });
    });
    
    $ua->userinfo->{"http://localhost:$port"} = "a:b";
    $ua->get("http://localhost:$port/file1");

    $port2 = Mojo::IOLoop->generate_port;
    Mojo::IOLoop->server(port => $port2, sub {
        my ($loop, $stream) = @_;
        $stream->on(read => sub {
            my ($stream, $chunk) = @_;
            unlike $chunk, qr{Authorization: Basic YTpi}, 'right Authorization header';
            $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
                    . "Content-Type: text/html\x0d\x0a\x0d\x0a",
            );
            $stream->close;
        });
    });
    $ua->get("http://localhost:$port2/file2");
    $ua->get("http://localhost:$port/file3");

    $port3 = Mojo::IOLoop->generate_port;
    Mojo::IOLoop->server(port => $port3, sub {
        my ($loop, $stream) = @_;
        $stream->on(read => sub {
            my ($stream, $chunk) = @_;
            like $chunk, qr{Authorization: Basic YTpi}, 'right Authorization header';
            $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
                    . "Content-Type: text/html\x0d\x0a\x0d\x0a",
            );
            $stream->close;
        });
    });
    my $url = Mojo::URL->new("http://localhost:$port3/file2")->userinfo('a:b');
    $ua->get($url);
    $ua->get($url);
}
