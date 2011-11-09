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

	use Test::More tests => 5;
	
	# Thank you for fixing
	# Now my app works fine with no scheme urls.
	#
	# And fortunately unsupported schemes are now detected as scheme.
	# Although I understand that I can't expect this as long as the tests doesn't include case for this.
	#
	# So I must check beforehand if the scheme is supported or not.
	# necessary and sufficient condition
	
	ok eval {url('http://example.com:3000/')};
	ok eval {url('http://example.com/#foo:bar')};
	ok eval {url('/#foo:bar')};
	ok ! eval {url('tel:11111')};
	ok ! eval {url('mailto:a@example.com')};
	
	sub url {
		my $href = shift;
		if ($href =~ qr{^([^/]+):} && ! ( $1 ~~ [qw(http https ws wss)])) {
			die "Scheme $1 is not supported";
		}
		Mojo::URL->new($href);
	}

1;

__END__

