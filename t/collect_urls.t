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

	use Test::More tests => 10;
	
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
<a href="index2.html">B</a>
<a href="mailto:a\@example.com">C</a>
<a href="tel:0000">D</a>
<map name="m_map" id="m_map">
	<area href="index3.html" coords="" title="E" />
</map>
</body>
</html>
EOF

	my $dom = Mojo::DOM->new($html);
	my @array = MojoCheckbot::collect_urls($dom);
	is_deeply(shift @array, {literalURI => 'css1.css', context => '&lt;link href=&quot;css1.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;'});
	is_deeply(shift @array, {literalURI => 'css2.css', context => '&lt;link href=&quot;css2.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;'});
	is_deeply(shift @array, {literalURI => 'js1.js', context => '&lt;script src=&quot;js1.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;'});
	is_deeply(shift @array, {literalURI => 'js2.js', context => '&lt;script src=&quot;js2.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;'});
	is_deeply(shift @array, {literalURI => 'index1.html', context => 'A'});
	is_deeply(shift @array, {literalURI => 'index2.html', context => 'B'});
	is_deeply(shift @array, {literalURI => 'mailto:a@example.com', context => 'C'});
	is_deeply(shift @array, {literalURI => 'tel:0000', context => 'D'});
	is_deeply(shift @array, {literalURI => 'index3.html', context => 'E'});
	is(shift @array, undef);

1;

__END__

