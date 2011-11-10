package MojoCheckbot::UserAgent;
use Mojo::Base 'Mojo::UserAgent';
use Time::HiRes qw{sleep time};

    has interval        => 1;
    has last_finish_ts  => 0;
    has userinfo        => sub {{}};
    
    sub start {
        my ($self, $tx) = @_;
        my $url = $tx->req->url;
        my $scheme_n_host = $url->scheme. '://'. $url->host;
        if (my $userinfo = $url->userinfo) {
            $self->userinfo->{$scheme_n_host} = "$userinfo";
        } elsif ($self->userinfo->{$scheme_n_host}) {
            $url->userinfo($self->userinfo->{$scheme_n_host});
        }
        my $now = time;
        my $sleep = $self->interval - (time - $self->last_finish_ts);
        if ($sleep > 0) {
            sleep($sleep);
        }
        $tx = $self->SUPER::start($tx);
        $self->last_finish_ts(time);
        return $tx;
    }

1;

=head1 NAME

MojoCheckbot::UserAgent - 

