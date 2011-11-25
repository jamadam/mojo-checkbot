package MojoCheckbot::UserAgent;
use strict;
use warnings;
use Mojo::Base 'Mojo::UserAgent';

    has userinfo        => sub {{}};
    
    sub start {
        my ($self, $tx, $cb) = @_;
        my $url = $tx->req->url;
        if ($url->is_abs) {
            my $scheme_n_host = $url->scheme. '://'. $url->host;
            if ($url->port) {
               $scheme_n_host .= ':'. $url->port;
            }
            my $userinfo;
            if ($userinfo = $url->userinfo) {
                $self->userinfo->{$scheme_n_host} = "$userinfo";
            } elsif ($userinfo = $self->userinfo->{$scheme_n_host}) {
                $url->userinfo($userinfo);
            }
        }
        return $self->SUPER::start($tx, $cb);
    }

1;

=head1 NAME

MojoCheckbot::UserAgent - 

