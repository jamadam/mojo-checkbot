package MojoCheckbot::UserAgent;
use strict;
use warnings;
use Mojo::Base 'Mojo::UserAgent';

has credentials => sub {{}};
has keep_credentials => 1;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->on(start => sub {
        my ($self, $tx) = @_;
        my $url = $tx->req->url;
        if ($self->keep_credentials && $url->is_abs) {
            my $key = $url->scheme. '://'. $url->host. ':'. ($url->port || 80);
            if ($url->userinfo) {
                $self->credentials->{$key} = $url->userinfo;
            } else {
                $url->userinfo($self->credentials->{$key});
            }
        }
    });
    return $self;
}

1;

=head1 NAME

MojoCheckbot::UserAgent - 

=head1 SYNOPSIS

=head1 DESCRIPTION

This class inherits Mojo::UserAgentand override start method for storing user
info

=head1 METHODS

=head2 start

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
