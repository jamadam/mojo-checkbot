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
	$base = Mojo::URL->new('https://example.com/');
	$tmp = MojoCheckbot::resolve_href($base, '//example2.com/hoge.html');
	is($tmp, 'https://example2.com/hoge.html');
	#$base = Mojo::URL->new('https://example.com/');
	#$tmp = MojoCheckbot::resolve_href($base, '//example2.com:8080/hoge.html');
	#is($tmp, 'https://example2.com:8080/hoge.html');

1;

__END__

