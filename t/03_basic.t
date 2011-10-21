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
	is_deeply(shift @array, {href => 'js1.js', context => ''});
	is_deeply(shift @array, {href => 'js2.js', context => ''});
	is_deeply(shift @array, {href => 'css1.css', context => ''});
	is_deeply(shift @array, {href => 'css2.css', context => ''});
	is_deeply(shift @array, {href => 'index1.html', context => 'A'});
	is_deeply(shift @array, {href => 'index2.html', context => 'B'});
	is_deeply(shift @array, {href => 'mailto:a@example.com', context => 'C'});
	is_deeply(shift @array, {href => 'tel:0000', context => 'D'});
	is_deeply(shift @array, {href => 'index3.html', context => 'E'});
	is(shift @array, undef);

1;

__END__

