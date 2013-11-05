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

    use Test::More tests => 48;
    
    my $base;
    my $tmp;
    $base = Mojo::URL->new('http://example.com');
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';

    $base = Mojo::URL->new('http://example.com');
    $tmp = MojoCheckbot::resolve_href($base, 'http://example2.com/hoge.html');
    is $tmp, 'http://example2.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, 'http://example2.com//hoge.html');
    is $tmp, 'http://example2.com//hoge.html', 'right url';
    
    $base = Mojo::URL->new('http://example.com/dir/');
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html');
    is $tmp, 'http://example.com/dir/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../../hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/');
    is $tmp, 'http://example.com/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '');
    is $tmp, 'http://example.com/dir/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, 'foo');
    is $tmp, 'http://example.com/dir/foo', 'right url';

    $base = Mojo::URL->new('http://example.com/dir/');
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html/?a=b');
    is $tmp, 'http://example.com/dir/hoge.html/?a=b', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../hoge.html/?a=b');
    is $tmp, 'http://example.com/hoge.html/?a=b', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../../hoge.html/?a=b');
    is $tmp, 'http://example.com/hoge.html/?a=b', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html/?a=b');
    is $tmp, 'http://example.com/hoge.html/?a=b', 'right url';

    $base = Mojo::URL->new('http://example.com/dir/');
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html#fragment');
    is $tmp, 'http://example.com/dir/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../hoge.html#fragment');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../../hoge.html#fragment');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html#fragment');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/#fragment');
    is $tmp, 'http://example.com/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, './#fragment');
    is $tmp, 'http://example.com/dir/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '#fragment');
    is $tmp, 'http://example.com/dir/', 'right url';
    
    $base = Mojo::URL->new('https://example.com/');
    $tmp = MojoCheckbot::resolve_href($base, '//example2.com/hoge.html');
    is $tmp, 'https://example2.com/hoge.html', 'right url';
    $base = Mojo::URL->new('https://example.com/');
    $tmp = MojoCheckbot::resolve_href($base, '//example2.com:8080/hoge.html');
    is $tmp, 'https://example2.com:8080/hoge.html', 'right url';
    
    $base = Mojo::URL->new('http://example.com/org');
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';

    $base = Mojo::URL->new('http://example.com/org');
    $tmp = MojoCheckbot::resolve_href($base, 'http://example2.com/hoge.html');
    is $tmp, 'http://example2.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, 'http://example2.com//hoge.html');
    is $tmp, 'http://example2.com//hoge.html', 'right url';
    
    $base = Mojo::URL->new('http://example.com/dir/org');
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html');
    is $tmp, 'http://example.com/dir/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../../hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/');
    is $tmp, 'http://example.com/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '');
    is $tmp, 'http://example.com/dir/org', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, 'foo');
    is $tmp, 'http://example.com/dir/foo', 'right url';

    $base = Mojo::URL->new('http://example.com/dir/org');
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html/?a=b');
    is $tmp, 'http://example.com/dir/hoge.html/?a=b', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../hoge.html/?a=b');
    is $tmp, 'http://example.com/hoge.html/?a=b', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../../hoge.html/?a=b');
    is $tmp, 'http://example.com/hoge.html/?a=b', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html/?a=b');
    is $tmp, 'http://example.com/hoge.html/?a=b', 'right url';

    $base = Mojo::URL->new('http://example.com/dir/org');
    $tmp = MojoCheckbot::resolve_href($base, './hoge.html#fragment');
    is $tmp, 'http://example.com/dir/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../hoge.html#fragment');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '../../hoge.html#fragment');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/hoge.html#fragment');
    is $tmp, 'http://example.com/hoge.html', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '/#fragment');
    is $tmp, 'http://example.com/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, './#fragment');
    is $tmp, 'http://example.com/dir/', 'right url';
    $tmp = MojoCheckbot::resolve_href($base, '#fragment');
    is $tmp, 'http://example.com/dir/org', 'right url';
    
    $base = Mojo::URL->new('https://example.com/org');
    $tmp = MojoCheckbot::resolve_href($base, '//example2.com/hoge.html');
    is $tmp, 'https://example2.com/hoge.html', 'right url';
    $base = Mojo::URL->new('https://example.com/org');
    $tmp = MojoCheckbot::resolve_href($base, '//example2.com:8080/hoge.html');
    is $tmp, 'https://example2.com:8080/hoge.html', 'right url';

1;

__END__

