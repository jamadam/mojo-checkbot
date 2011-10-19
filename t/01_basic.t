package Template_Basic;
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use utf8;
use Test::More tests => 68;
use Mojolicious::Lite;
use MojoCheckbot::Util;
use Data::Dumper;
	
	get '/' => {text => 'works'};
	
	my $ua = Mojo::UserAgent->new;
	$ua = Mojo::UserAgent->new->app(app);
	my $tx = $ua->get('/');
	ok $tx->success, 'successful';
	is $tx->res->code, 200,     'right status';
	is $tx->res->body, 'works', 'right content';
	
	my $port2     = Mojo::IOLoop->generate_port;
	warn $port2;
	my $buffer2 = {};
	Mojo::IOLoop->listen(
		port            => $port2,
		on_accept => sub {
			my ($loop, $id) = @_;
			$buffer2->{$id} = '';
		},
		on_read => sub {
			my ($loop, $id, $chunk) = @_;
			$buffer2->{$id} .= $chunk;
			if (index($buffer2->{$id}, "\x0d\x0a\x0d\x0a") >= 0) {
				delete $buffer2->{$id};
				$loop->write(
					$id => "HTTP/1.1 200 OK\x0d\x0a"
						. "Content-Type: text/plain\x0d\x0a\x0d\x0aworks too!",
					sub { shift->drop(shift) }
				);
			}
		},
		on_error => sub {
			my ($self, $id) = @_;
			delete $buffer2->{$id};
		}
	);
	
	#MojoCheckbot::Util::fetch("http://localhost:$port2/", $ua, sub{
	#	warn Dumper $_[0]->res->body;
	#});
	warn $port2;
	$tx = $ua->get("http://127.0.0.1:$port2");

1;

__END__
