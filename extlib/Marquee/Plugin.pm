package Marquee::Plugin;
use strict;
use warnings;
use Mojo::Base -base;

sub register {
    die "Class ". (ref $_[0]) . " must implements register method";
}

1;

__END__

=head1 NAME

Marquee::Plugin - Plugin base class

=head1 SYNOPSIS

    package Marquee::Plugin::SomePlugin;
    use Mojo::Base 'Marquee::Plugin';

    sub register {
        my ($self, $app, @args) = @_;
        ...
        return $self;
    }

=head1 DESCRIPTION

L<Marquee::Plugin> is the plugin base class of L<Marquee> plugins.

L<Marquee> provides some hook points to extend the behavior of applications.
With the hooks, you can develop reusable plugins under C<Marquee::Plugin::*>
namespace.

A plugin looks like as follows.

    package Marquee::Plugin::SomePlugin;
    use Mojo::Base 'Marquee::Plugin';
    
    sub register {
        my ($self, $app, $params) = @_;
        
        $app->hook(around_dispatch => sub {
            my ($next) = @_;
            
            my $c = Marquee->c;
            
            if (! $c->served) {
                $next->();
            }
        });
    }

There is some hook points available. See L<Marquee/"hook">.

=head1 CLASS METHODS

L<Marquee::Plugin> implements the following class methods.

=head2 C<register>

This must be overridden by sub classes.

    sub register {
        my ($self, $app, @conf) = @_;
        ...
        return;
    }

The method should be available as follows

    $plugin->register($app, ...);

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
