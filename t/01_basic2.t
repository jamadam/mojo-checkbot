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
	
	my $html = <<EOF;
<html>
<body>
<a href="http://example.com">example.com</a>
<a href="/foo.html">foo.html</a>
</body>
</html>
EOF
	
	my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);

	my $port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->listen(
		port      => $port,
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			$loop->write(
				$id => "HTTP/1.1 404 OK\x0d\x0a"
					. "Content-Type: text/html\x0d\x0a\x0d\x0aNot Found",
				sub { shift->drop(shift) }
			);
		},
	);
	
	{
		my $res = MojoCheckbot::fetch("http://localhost:$port/hoge", $ua, sub{
			my $http_res = shift;
			ok(0, 'must not be do this');
		});
		is($res, 404);
	}

	$port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->listen(
		port      => $port,
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			$loop->write(
				$id => "HTTP/1.1 200 OK\x0d\x0a"
					. "Content-Type: text/html\x0d\x0a\x0d\x0a". $html,
				sub { shift->drop(shift) }
			);
		},
	);
	
	{
		my $res = MojoCheckbot::fetch("http://localhost:$port/", $ua, sub{
			my $http_res = shift;
			is(ref $http_res, 'Mojo::Transaction::HTTP');
			like($http_res->res->body, qr{foo.html});
		});
		is($res, 200);
	}

1;

__END__

