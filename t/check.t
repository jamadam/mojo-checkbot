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

	use Test::More tests => 51;
	
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
<form action="form.html" method="post">
	<input type="hidden" name="key1" value="val1" />
	<input type="hidden" name="key2" value="val2" />
</form>
<form action="form2.html" method="post">
	<input type="hidden" name="key3" value="val3" />
	<input type="hidden" name="key4" value="val4" />
</form>
<a href="#a:b">F</a>
<a href="javascript:void(0)">D</a>
<form action="javascript:void(0)" method="post">
</form>
</body>
</html>
EOF
	my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
	my $port;
	
	{
		$port = Mojo::IOLoop->generate_port;
		Mojo::IOLoop->listen(
			port      => $port,
			on_read => sub {
				my ($loop, $id, $chunk) = @_;
				$loop->write(
					$id => "HTTP/1.1 200 OK\x0d\x0a"
						. "Content-Type: text/html\x0d\x0a\x0d\x0a". $html,
					sub {shift->drop(shift) }
				);
			},
		);
		
		my $res = MojoCheckbot::check("http://localhost:$port/", $ua);
		is $res->{code}, 200, 'right status code';
		is scalar @{$res->{queue}}, 8, 'right queue number';
		is keys %{$res->{queue}->[0]}, 3, 'right key number';
		is $res->{queue}->[0]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;link href=&quot;css1.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;', 'right context';
		is $res->{queue}->[0]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/css1.css", 'right resolved uri';
		is $res->{queue}->[0]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'css1.css', 'right literal uri';
		is $res->{queue}->[1]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;link href=&quot;css2.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;', 'right context';
		is $res->{queue}->[1]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/css2.css", 'right resolved uri';
		is $res->{queue}->[1]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'css2.css', 'right literal uri';
		is $res->{queue}->[2]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;script src=&quot;js1.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;', 'right context';
		is $res->{queue}->[2]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/js1.js", 'right resolved uri';
		is $res->{queue}->[2]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'js1.js', 'right literal uri';
		is $res->{queue}->[3]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;script src=&quot;js2.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;', 'right context';
		is $res->{queue}->[3]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/js2.js", 'right resolved uri';
		is $res->{queue}->[3]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'js2.js', 'right literal uri';
		is $res->{queue}->[4]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, 'A', 'right context';
		is $res->{queue}->[4]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/index1.html", 'right resolved uri';
		is $res->{queue}->[4]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'index1.html', 'right literal uri';
		is $res->{queue}->[5]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, 'B', 'right context';
		is $res->{queue}->[5]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/index2.html", 'right resolved uri';
		is $res->{queue}->[5]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'index2.html', 'right literal uri';
		is $res->{queue}->[6]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, 'E', 'right context';
		is $res->{queue}->[6]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/index3.html", 'right resolved uri';
		is $res->{queue}->[6]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'index3.html', 'right literal uri';
		is $res->{queue}->[7]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, 'F', 'right context';
		is $res->{queue}->[7]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/", 'right resolved uri';
		is $res->{queue}->[7]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, '#a:b', 'right literal uri';
		is scalar @{$res->{dialog}}, 2, 'right dialog number';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '*FORM*', 'right context';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'form.html', 'right uri';
		like scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, qr{.+/form.html}, 'right abs uri';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_METHOD}, 'post', 'right method';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[0]->{name}, 'key1', 'right key';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[0]->{value}, 'val1', 'right value';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[1]->{name}, 'key2', 'right key';
		is scalar $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[1]->{value}, 'val2', 'right value';
		is scalar $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[0]->{name}, 'key3', 'right key';
		is scalar $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[0]->{value}, 'val3', 'right value';
		is scalar $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[1]->{name}, 'key4', 'right key';
		is scalar $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_DIALOG}->{names}->[1]->{value}, 'val4', 'right value';
		
		is $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_METHOD}, 'post', 'right method';
		is $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, "*FORM*", 'right resolved uri';
		is $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/form.html", 'right literal uri';
		is_deeply $res->{dialog}->[0]->{$MojoCheckbot::QUEUE_KEY_DIALOG}, {
                     'names' => [
                                  {
                                    'value' => 'val1',
                                    'name' => 'key1'
                                  },
                                  {
                                    'value' => 'val2',
                                    'name' => 'key2'
                                  }
                                ]
                   }, 'right dialog';
		is $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'form2.html', 'right literal uri';
		is $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_METHOD}, 'post', 'right method';
		is $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, "*FORM*", 'right resolved uri';
		is $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/form2.html", 'right literal uri';
		is_deeply $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_DIALOG}, {
                     'names' => [
                                  {
                                    'value' => 'val3',
                                    'name' => 'key3'
                                  },
                                  {
                                    'value' => 'val4',
                                    'name' => 'key4'
                                  }
                                ]
                   }, 'right dialog';
		is $res->{dialog}->[1]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'form2.html', 'right literal uri';
	}
	
	{
		$port = Mojo::IOLoop->generate_port;
		Mojo::IOLoop->listen(
			port      => $port,
			on_read => sub {
				my ($loop, $id, $chunk) = @_;
				like $chunk, qr{^GET /\?a=b&c=d}, 'right request';
				$loop->write(
					$id => "HTTP/1.1 200 OK\x0d\x0a"
						. "Content-Type: text/html\x0d\x0a\x0d\x0a". $html,
					sub { shift->drop(shift) }
				);
			},
		);
		
		my $res = MojoCheckbot::check("http://localhost:$port/", $ua, 'get', 'a=b&c=d');
	}

1;

__END__

