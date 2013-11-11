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

use Test::More tests => 13;

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
is_deeply shift @array, {2 => 'css1.css', 1 => '&lt;link href=&quot;css1.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;'}, 'right url';
is_deeply shift @array, {2 => 'css2.css', 1 => '&lt;link href=&quot;css2.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;'}, 'right url';
is_deeply shift @array, {2 => 'js1.js', 1 => '&lt;script src=&quot;js1.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;'}, 'right url';
is_deeply shift @array, {2 => 'js2.js', 1 => '&lt;script src=&quot;js2.js&quot; type=&quot;text/javascript&quot;&gt;&lt;/script&gt;'}, 'right url';
is_deeply shift @array, {2 => 'index1.html', 1 => 'A'}, 'right url';
is_deeply shift @array, {2 => 'index2.html', 1 => 'B'}, 'right url';
is_deeply shift @array, {2 => 'mailto:a@example.com', 1 => 'C'}, 'right url';
is_deeply shift @array, {2 => 'tel:0000', 1 => 'D'}, 'right url';
is_deeply shift @array, {2 => 'index3.html', 1 => 'E'}, 'right url';
is shift @array, undef, 'no more urls';

{
    my $css = <<EOF;
body {
    background-image:url('/image/a.png');
}
div {
    background-image:url('/image/b.png');
}
div {
    background: #fff url('/image/c.png');
}
EOF

    my @array = MojoCheckbot::collect_urls_from_css($css);
    is_deeply shift @array, {1 => '', 2 => '/image/a.png'}, 'right url';
    is_deeply shift @array, {1 => '', 2 => '/image/b.png'}, 'right url';
    is_deeply shift @array, {1 => '', 2 => '/image/c.png'}, 'right url';
}

1;

__END__

