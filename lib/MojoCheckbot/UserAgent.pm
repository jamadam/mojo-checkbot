package MojoCheckbot::UserAgent;
use Mojo::Base 'Mojo::UserAgent';
use Time::HiRes qw{sleep time};

    has userinfo        => sub {{}};
    
    sub start {
        my ($self, $tx, $cb) = @_;
        my $url = $tx->req->url;
        if ($url->is_abs) {
            my $scheme_n_host = $url->scheme. '://'. $url->host;
            if ($url->port) {
               $scheme_n_host .= ':'. $url->port;
            }
            if (my $userinfo = $url->userinfo) {
                $self->userinfo->{$scheme_n_host} = "$userinfo";
            } elsif ($self->userinfo->{$scheme_n_host}) {
                $url->userinfo($self->userinfo->{$scheme_n_host});
            }
        }
        return $self->SUPER::start($tx, $cb);
    }

1;

=head1 NAME

MojoCheckbot::UserAgent - 

