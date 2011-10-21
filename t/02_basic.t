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

	use Test::More tests => 8;
	
	my $html = <<EOF;
<html>
<body>
日本
</body>
</html>
EOF
	utf8::encode($html);
	
	my $html2 = <<EOF;
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=cp932" />
</head>
<body>
日本
</body>
</html>
EOF
	utf8::encode($html2);
	
	my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);

	my $port;
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
			my $tx = shift;
			is(MojoCheckbot::guess_encoding($tx->res), undef);
		});
		is($res, 200);
	}
	
	$port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->listen(
		port      => $port,
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			$loop->write(
				$id => "HTTP/1.1 200 OK\x0d\x0a"
					. "Content-Type: text/html\x0d\x0a\x0d\x0a". $html2,
				sub { shift->drop(shift) }
			);
		},
	);
	
	{
		my $res = MojoCheckbot::fetch("http://localhost:$port/", $ua, sub{
			my $tx = shift;
			is(MojoCheckbot::guess_encoding($tx->res), 'cp932');
		});
		is($res, 200);
	}
	
	$port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->listen(
		port      => $port,
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			$loop->write(
				$id => "HTTP/1.1 200 OK\x0d\x0a"
					. "Content-Type: text/html; charset=cp932\x0d\x0a\x0d\x0a". $html,
				sub { shift->drop(shift) }
			);
		},
	);
	
	{
		my $res = MojoCheckbot::fetch("http://localhost:$port/", $ua, sub{
			my $tx = shift;
			is(MojoCheckbot::guess_encoding($tx->res), 'cp932');
		});
		is($res, 200);
	}
	
	$port = Mojo::IOLoop->generate_port;
	Mojo::IOLoop->listen(
		port      => $port,
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			$loop->write(
				$id => "HTTP/1.1 200 OK\x0d\x0a"
					. "Content-Type: text/html; charset=cp932; hoge\x0d\x0a\x0d\x0a". $html,
				sub { shift->drop(shift) }
			);
		},
	);
	
	{
		my $res = MojoCheckbot::fetch("http://localhost:$port/", $ua, sub{
			my $tx = shift;
			is(MojoCheckbot::guess_encoding($tx->res), 'cp932');
		});
		is($res, 200);
	}

1;

__END__

