package MojoCheckbot::IOLoop;
use strict;
use warnings;
use Mojo::Base 'Mojo::IOLoop';

my %ids = ();

sub blocked_recurring {
    my ($self, $after, $cb) = @_;
    $self = $self->singleton unless ref $self;
    weaken $self;
    my $wrap;
    my $id;
    $wrap = sub {
        $self->$cb(pop);
        if (exists $ids{$id}) {
            $ids{$id} = $self->iowatcher->timer($after => $wrap);
        }
    };
    $id = $self->iowatcher->timer($after => $wrap);
    $ids{$id} = $id;
    return $id;
}

sub drop {
    my ($self, $id) = @_;
    if ($ids{$id}) {
        my $map_to = $ids{$id};
        delete $ids{$id};
        $id = $map_to;
    }
    return $self->SUPER::drop($id);
}

1;

=head1 NAME

MojoCheckbot::IOLoop - 

=head1 SYNOPSIS

=head1 DESCRIPTION

This class inherits Mojo::IOLoop and extends a method blocked_recurring
which is replacement of recurring for blocking next loop

=head1 METHODS

=head2 $self->blocked_recurring

=head2 $self->drop

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
