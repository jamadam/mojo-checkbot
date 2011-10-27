package MojoCheckbot::IOLoop;
use Mojo::Base 'Mojo::IOLoop';

sub blocked_recurring {
    my ($self, $after, $cb) = @_;
    $self = $self->singleton unless ref $self;
    weaken $self;
    my $wrap;
    $wrap = sub {
        $self->$cb(pop);
        $self->iowatcher->timer($after => $wrap);
    };
    return $self->iowatcher->timer($after => $wrap);
}

1;
