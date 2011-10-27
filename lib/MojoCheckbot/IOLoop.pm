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

=head1 NAME

MojoCheckbot::IOLoop - 

=head1 SYNOPSIS

=head1 DESCRIPTION

This class inherits Mojo::IOLoop and extends a method blocked_recurring
which is replacement of recurring for blocking next loop

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
