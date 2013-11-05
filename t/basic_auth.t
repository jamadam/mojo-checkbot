package Template_Basic;
use strict;
use warnings;
use lib './lib', './extlib';
use Test::More;
use Test::Mojo;
use utf8;
use Data::Dumper;
use Mojo::IOLoop;
use Mojolicious::Lite;
use MojoCheckbot;

    use Test::More tests => 3;
    
    my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
    my $port;

    $port = Mojo::IOLoop->generate_port;
    Mojo::IOLoop->server(port => $port, sub {
        my ($loop, $stream, $id) = @_;
        $stream->on(read => sub {
            my ($stream, $chunk) = @_;
            $stream->write(
                "HTTP/1.1 401 Authorization Required\x0d\x0a"
                    . q{"WWW-Authenticate: Basic realm="Secret Area"}
                    . q{Content-Type: text/html\x0d\x0a\x0d\x0a},
                sub { shift->close }
            );
        });
    });
    
    {
        my $queue = {
            $MojoCheckbot::QUEUE_KEY_LITERAL_URI 	=> "http://localhost:$port/",
        };
        my $res = MojoCheckbot::check($ua, $queue);
        is $queue->{$MojoCheckbot::QUEUE_KEY_RES}, 401, 'right status';
        is_deeply $res->{queue}, [], 'queue is empty';
        is_deeply $res->{dialog}, [{
            '1' => '*Authentication Required*',
            '7' => {'www-authenticate' => undef},
            '2' => "http://localhost:$port/",
        }], 'deeply right dialog';
    }

1;

__END__

