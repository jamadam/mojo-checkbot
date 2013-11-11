package Marquee::Plugin::ETag;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
use Mojo::ByteStream;

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app, $generator) = @_;
    
    $app->hook(around_dispatch => sub {
        my ($next) = @_;
        
        $next->();
        
        my $req = Marquee->c->req;
        my $res = Marquee->c->res;
        
        if ($res->code && $res->code == 200
                        && $req->method eq 'GET' && (my $body = $res->body)) {
            
            my $new_etag = Mojo::ByteStream->new($body)->md5_sum;
            $res->headers->header('ETag' => $new_etag);
            
            my $old_etag = $req->headers->header('If-None-Match');
            
            if ($old_etag && $old_etag eq $new_etag) {
                $res->code(304);
                $res->body('');
            }
        }
    });
}

1;

__END__

=head1 NAME

Marquee::Plugin::ETag - ETag

=head1 SYNOPSIS
    
    $app->plugin('ETag');

=head1 DESCRIPTION

L<Marquee::Plugin::ETag> plugin generates ETag to reduce http traffic.

=head1 INSTANCE METHODS

L<Marquee::Plugin::ETag> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin.

    $self->register($app, $generator);

=head1 SEE ALSO

L<Marquee::Plugin>, L<Marquee>, L<Mojolicious>

=cut
