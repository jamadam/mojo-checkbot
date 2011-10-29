package MojoCheckbot::UserAgent;
use Mojo::Base 'Mojo::UserAgent';
use Time::HiRes qw{sleep time};

    has interval        => 1;
    has last_finish_ts  => 0;
    
    sub start {
        my $self = shift;
        my $now = time;
        my $sleep = $self->interval - (time - $self->last_finish_ts);
        if ($sleep > 0) {
            sleep($sleep);
        }
        my $tx = $self->SUPER::start(@_);
        $self->last_finish_ts(time);
        return $tx;
    }

1;

=head1 NAME

MojoCheckbot::UserAgent - 

