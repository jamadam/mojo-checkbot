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

	use Test::More tests => 1;
	
	my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
	$ua->keep_alive_timeout(1);
	my $port;
	$port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->server(port => $port, sub {
		my ($loop, $stream) = @_;
		$stream->on(read => sub {
			my ($stream, $chunk) = @_;
			sleep(2);
			$stream->write(
				"HTTP/1.1 200 OK\x0d\x0a"
					. "Content-Type: text/html\x0d\x0a\x0d\x0a",
				sub {shift->drop(shift) }
			);
		});
	});
	
	{
		my ($res, $jobs) = eval {
			MojoCheckbot::check($ua, {
				$MojoCheckbot::QUEUE_KEY_LITERAL_URI 	=> "http://localhost:$port/",
			});
		};
		like $@, qr{^Premature connection close}, 'right error';
	}

1;

__END__

