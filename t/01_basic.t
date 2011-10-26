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

	use Test::More tests => 20;
	
	my $base;
	my $tmp;
	$base = Mojo::URL->new('http://example.com');
	$tmp = MojoCheckbot::resolve_href($base, '/hoge.html');
	is($tmp, 'http://example.com/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, './hoge.html');
	is($tmp, 'http://example.com/hoge.html');

	$base = Mojo::URL->new('http://example.com');
	$tmp = MojoCheckbot::resolve_href($base, 'http://example2.com/hoge.html');
	is($tmp, 'http://example2.com/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, 'http://example2.com//hoge.html');
	is($tmp, 'http://example2.com/hoge.html');
	
	$base = Mojo::URL->new('http://example.com/dir/');
	$tmp = MojoCheckbot::resolve_href($base, './hoge.html');
	is($tmp, 'http://example.com/dir/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, '../hoge.html');
	is($tmp, 'http://example.com/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, '../../hoge.html');
	is($tmp, 'http://example.com/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, '/hoge.html');
	is($tmp, 'http://example.com/hoge.html');

	$base = Mojo::URL->new('http://example.com/dir/');
	$tmp = MojoCheckbot::resolve_href($base, './hoge.html/?a=b');
	is($tmp, 'http://example.com/dir/hoge.html/?a=b');
	$tmp = MojoCheckbot::resolve_href($base, '../hoge.html/?a=b');
	is($tmp, 'http://example.com/hoge.html/?a=b');
	$tmp = MojoCheckbot::resolve_href($base, '../../hoge.html/?a=b');
	is($tmp, 'http://example.com/hoge.html/?a=b');
	$tmp = MojoCheckbot::resolve_href($base, '/hoge.html/?a=b');
	is($tmp, 'http://example.com/hoge.html/?a=b');

	$base = Mojo::URL->new('http://example.com/dir/');
	$tmp = MojoCheckbot::resolve_href($base, './hoge.html#fragment');
	is($tmp, 'http://example.com/dir/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, '../hoge.html#fragment');
	is($tmp, 'http://example.com/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, '../../hoge.html#fragment');
	is($tmp, 'http://example.com/hoge.html');
	$tmp = MojoCheckbot::resolve_href($base, '/hoge.html#fragment');
	is($tmp, 'http://example.com/hoge.html');
	
	$base = Mojo::URL->new('https://example.com/');
	$tmp = MojoCheckbot::resolve_href($base, '//example2.com/hoge.html');
	is($tmp, 'https://example2.com/hoge.html');
	$base = Mojo::URL->new('https://example.com/');
	$tmp = MojoCheckbot::resolve_href($base, '//example2.com:8080/hoge.html');
	is($tmp, 'https://example2.com:8080/hoge.html');
	
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
		my ($res, $jobs) = MojoCheckbot::check("http://localhost:$port/", $ua);
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
		my ($res, $jobs) = MojoCheckbot::check("http://localhost:$port/", $ua);
		is($res, 200);
	}

1;

__END__

