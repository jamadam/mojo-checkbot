package Template_Basic;
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use utf8;
use Data::Dumper;
use lib './extlib';
use Mojo::IOLoop;
use Mojolicious::Lite;
use MojoCheckbot;

	use Test::More tests => 2;
	
	my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
	$ua->keep_alive_timeout(1);
	my $port;
	$port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->listen(
		port      => $port,
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			sleep(2);
			$loop->write(
				$id => "HTTP/1.1 200 OK\x0d\x0a"
					. "Content-Type: text/html\x0d\x0a\x0d\x0a",
				sub { shift->drop(shift) }
			);
		},
	);
	
	{
		my ($res, $jobs) = MojoCheckbot::check("http://localhost:$port/", $ua);
		is($res, undef);
	}

1;

__END__

