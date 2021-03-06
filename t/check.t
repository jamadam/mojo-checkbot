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

use Test::More tests => 65;

my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
my $daemon = Mojo::Server::Daemon->new(
    ioloop => Mojo::IOLoop->singleton,
    silent => 1
);
my $port = Mojo::IOLoop::Server->generate_port;
$daemon->listen(["http://127.0.0.1:$port"])->start;

{
    $daemon->on(request => sub {
        my ($daemon, $tx) = @_;
        $tx->res->code(404);
        $tx->res->headers->content_type('text/html');
        $tx->res->body('Not Found');
        $tx->resume;
    });
    my $queue = {
        $MojoCheckbot::QUEUE_KEY_RESOLVED_URI => "http://localhost:$port/",
    };
    my $res = MojoCheckbot::check($ua, $queue);
    is $queue->{$MojoCheckbot::QUEUE_KEY_RES}, 404, 'right status code';
}

{
    my $html = <<EOF;
<html>
<body>
<a href="http://example.com">example.com</a>
<a href="/foo.html">foo.html</a>
</body>
</html>
EOF
    $daemon->on(request => sub {
        my ($daemon, $tx) = @_;
        $tx->res->code(200);
        $tx->res->headers->content_type('text/html');
        $tx->res->body($html);
        $tx->resume;
    });
    my $queue = {
        $MojoCheckbot::QUEUE_KEY_RESOLVED_URI => "http://localhost:$port/",
    };
    my $res = MojoCheckbot::check($ua, $queue);
    is $queue->{$MojoCheckbot::QUEUE_KEY_RES}, 200, 'right status code';
}

{
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
<form action="form2.html" method="post"><!-- same action url twice -->
    <input type="hidden" name="key5" value="val3" />
    <input type="hidden" name="key6" value="val4" />
</form>
<form action="form2.html" method="post"><!-- same action & same form parts -->
    <input type="hidden" name="key5" value="val3" />
    <input type="hidden" name="key6" value="val4" />
</form>
<form action="form2.html" method="post"><!-- same action & same form parts -->
    <input type="hidden" name="key6" value="val4" />
    <input type="hidden" name="key5" value="val3" />
</form>
<form action="form.html" method="get">
    <input type="hidden" name="key1" value="val1" />
    <input type="hidden" name="key2" value="val2" />
</form>
<form action="form2.html" method="get">
    <input type="hidden" name="key3" value="val3" />
    <input type="hidden" name="key4" value="val4" />
</form>
<form action="form2.html" method="get"><!-- same action url twice -->
    <input type="hidden" name="key5" value="val3" />
    <input type="hidden" name="key6" value="val4" />
</form>
<form action="form2.html" method="get"><!-- same action & same form parts -->
    <input type="hidden" name="key5" value="val3" />
    <input type="hidden" name="key6" value="val4" />
</form>
<a href="#a:b">F</a>
<a href="javascript:void(0)">D</a>
<form action="javascript:void(0)" method="post">
</form>
<embed src="../images/embed1.swf">
<frame src="frame1.html"></frame>
<iframe src="iframe1.html"></iframe>
<form>
    <input src="input.gif" />
</form>
</body>
</html>
EOF
    
    $daemon->on(request => sub {
        my ($daemon, $tx) = @_;
        $tx->res->code(200);
        $tx->res->headers->content_type('text/html');
        $tx->res->body($html);
        $tx->resume;
    });
    my $queue = {
        $MojoCheckbot::QUEUE_KEY_RESOLVED_URI=> "http://a:b\@localhost:$port/",
    };
    my $res = MojoCheckbot::check($ua, $queue);
    is $queue->{$MojoCheckbot::QUEUE_KEY_RES}, 200, 'right status code';
    is scalar @{$res->{queue}}, 12, 'right queue number';
    is keys %{$res->{queue}->[0]}, 3, 'right key number';
    is $res->{queue}->[0]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;link href=&quot;css1.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot;&gt;', 'right context';
    is $res->{queue}->[0]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/css1.css", 'right resolved uri';
    is $res->{queue}->[0]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'css1.css', 'right literal uri';
    is $res->{queue}->[1]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;link href=&quot;css2.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot;&gt;', 'right context';
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
    is $res->{queue}->[8]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;embed src=&quot;../images/embed1.swf&quot;&gt;', 'right context';
    is $res->{queue}->[8]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/images/embed1.swf", 'right resolved uri';
    is $res->{queue}->[8]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, '../images/embed1.swf', 'right literal uri';
    is $res->{queue}->[9]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;frame src=&quot;frame1.html&quot;&gt;&lt;/frame&gt;', 'right context';
    is $res->{queue}->[9]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/frame1.html", 'right resolved uri';
    is $res->{queue}->[9]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'frame1.html', 'right literal uri';
    is $res->{queue}->[10]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;iframe src=&quot;iframe1.html&quot;&gt;&lt;/iframe&gt;', 'right context';
    is $res->{queue}->[10]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/iframe1.html", 'right resolved uri';
    is $res->{queue}->[10]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'iframe1.html', 'right literal uri';
    is $res->{queue}->[11]->{$MojoCheckbot::QUEUE_KEY_CONTEXT}, '&lt;input src=&quot;input.gif&quot;&gt;', 'right context';
    is $res->{queue}->[11]->{$MojoCheckbot::QUEUE_KEY_RESOLVED_URI}, "http://localhost:$port/input.gif", 'right resolved uri';
    is $res->{queue}->[11]->{$MojoCheckbot::QUEUE_KEY_LITERAL_URI}, 'input.gif', 'right literal uri';

    is scalar @{$res->{dialog}}, 6, 'right dialog number';
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
    $daemon->on(request => sub {
        my ($daemon, $tx) = @_;
        is $tx->req->params, 'a=b&c=d', 'right request';
        $tx->res->code(200);
        $tx->res->headers->content_type('text/html');
        $tx->res->body('');
        $tx->resume;
    });
    
    my $queue = {
        $MojoCheckbot::QUEUE_KEY_RESOLVED_URI   => "http://localhost:$port/",
        $MojoCheckbot::QUEUE_KEY_METHOD         => 'get',
        $MojoCheckbot::QUEUE_KEY_PARAM          => 'a=b&c=d'
    };
    my $res = MojoCheckbot::check($ua, $queue);
}

1;

__END__

