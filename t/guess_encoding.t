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

use Test::More tests => 4;

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
Mojo::IOLoop->server(port => $port, sub {
	my ($loop, $stream) = @_;
	$stream->on(read => sub {
		my ($stream, $chunk) = @_;
		$stream->write(
			"HTTP/1.1 200 OK\x0d\x0a"
				. "Content-Type: text/html\x0d\x0a\x0d\x0a". $html,
			sub {shift->close }
		);
	});
});

{
	my $tx = $ua->get("http://localhost:$port/");
	is MojoCheckbot::guess_encoding($tx->res), undef, 'right encoding';
}

$port = Mojo::IOLoop->generate_port;
Mojo::IOLoop->server(port => $port, sub {
	my ($loop, $stream) = @_;
	$stream->on(read => sub {
		my ($stream, $chunk) = @_;
		$stream->write(
			"HTTP/1.1 200 OK\x0d\x0a"
				. "Content-Type: text/html\x0d\x0a\x0d\x0a". $html2,
			sub {shift->close }
		);
	});
});

{
	my $tx = $ua->get("http://localhost:$port/");
	is MojoCheckbot::guess_encoding($tx->res), 'cp932', 'right encoding';
}

$port = Mojo::IOLoop->generate_port;
Mojo::IOLoop->server(port => $port, sub {
	my ($loop, $stream) = @_;
	$stream->on(read => sub {
		my ($stream, $chunk) = @_;
		$stream->write(
			"HTTP/1.1 200 OK\x0d\x0a"
				. "Content-Type: text/html; charset=cp932\x0d\x0a\x0d\x0a". $html,
			sub {shift->close }
		);
	});
});

{
	my $tx = $ua->get("http://localhost:$port/");
	is MojoCheckbot::guess_encoding($tx->res), 'cp932', 'right encoding';
}

$port = Mojo::IOLoop->generate_port;
Mojo::IOLoop->server(port => $port, sub {
	my ($loop, $stream) = @_;
	$stream->on(read => sub {
		my ($stream, $chunk) = @_;
		$stream->write(
			"HTTP/1.1 200 OK\x0d\x0a"
				. "Content-Type: text/html; charset=cp932; hoge\x0d\x0a\x0d\x0a". $html,
			sub {shift->close }
		);
	});
});

{
	my $tx = $ua->get("http://localhost:$port/");
	is MojoCheckbot::guess_encoding($tx->res), 'cp932', 'right encoding';
}

1;

__END__

