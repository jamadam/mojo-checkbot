package Marquee::Hooks;
use strict;
use warnings;
use Mojo::Base 'Mojo::EventEmitter';

### --
### Emit events as chained hooks
### --
sub emit_chain {
    my ($self, $name, @args) = @_;
    
    my $wrapper;
    for my $cb (@{$self->subscribers($name)}) {
        my $next = $wrapper;
        $wrapper = sub { $cb->($next, @args) };
    }
    $wrapper->();
    
    return $self;
}

1;

__END__

=head1 NAME

Marquee::Hooks - Hooks manager

=head1 SYNOPSIS

    use Marquee::Hooks;
    
    my $hook = Marquee::Hooks->new;
    
    my $out = '';
    
    $hook->on(myhook => sub {
        my ($next, $open, $close) = @_;
        $out .= $open. 'hook1'. $close;
    });
    
    $hook->on(myhook => sub {
        my ($next, $open, $close) = @_;
        $next->();
        $out .= $open. 'hook2'. $close;
    });
    
    $hook->emit_chain('myhook', '<', '>');
    
    say $out; # $out = '<hook1><hook2>'

=head1 DESCRIPTION

L<Marquee::Hooks> is the Hook manager of L<Marquee>.

=head1 INSTANCE METHODS

L<Marquee::Hooks> inherits all instance methods from L<Mojo::EventEmitter> and
implements the following new ones.

=head2 C<emit_chain>

  $plugins = $plugins->emit_chain('foo');
  $plugins = $plugins->emit_chain(foo => @args);

Emit events as chained hooks.

=head1 SEE ALSO

L<Mojo::EventEmitter>, L<Marquee>, L<Mojolicious>

=cut
