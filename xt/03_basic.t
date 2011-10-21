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

	use Test::More tests => 18;
	
	my $ua = Mojo::UserAgent->new;
	
	my $res = MojoCheckbot::fetch("http://example.com/", $ua, sub{
		my $tx = shift;
		my $url = $tx->req->url;
		warn Dumper("$url");
	});
	is($res, 200);
	

1;

__END__

