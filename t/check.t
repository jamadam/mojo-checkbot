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

	use Test::More tests => 2;
	
	my $html = <<EOF;
<html>
<head>
	<link rel="stylesheet" type="text/css" href="css1.css" />
	<link rel="stylesheet" type="text/css" href="css2.css" />
	<script type="text/javascript" src="js1.js"></script>
	<script type="text/javascript" src="js2.js"></script>
</head>
<body>
<a href="index1.html">A</a>
<a href="index1.html#a">A</a>
<a href="index1.html#a">A</a>
<a href="index2.html">B</a>
<a href="mailto:a\@example.com">C</a>
<a href="tel:0000">D</a>
<map name="m_map" id="m_map">
	<area href="index3.html" coords="" title="E" />
</map>
<a href="#a:b">F</a>
</body>
</html>
EOF
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
		my ($res, $jobs) = MojoCheckbot::check("http://localhost:$port/", $ua);
		is($res, 200);
		is(scalar @$jobs, 8);
	}

1;

__END__

