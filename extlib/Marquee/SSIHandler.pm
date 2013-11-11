package Marquee::SSIHandler;
use strict;
use warnings;
use Mojo::Base -base;

__PACKAGE__->attr(log => sub {
    if (my $c = Marquee->c) {
        $c->app->log;
    }
});

### --
### Get current template name recursively
### --
sub current_template {
    my ($self, $index) = @_;
    
    $index ||= 0;
    
    my $route = Marquee->c->stash->{'mrqe.template_path'};
    
    while ($index-- > 0) {
        $route = $route->[1] || return;
    }
    
    return $route->[0];
}

### --
### render
### --
sub render {
    die "Class ". (ref $_[0]) . " must implements render method";
}

### --
### traceable render
### --
sub render_traceable {
    my ($self, $path) = @_;
    
    return $self->traceable($path, sub {$self->render($path)});
}

### --
### Make method calls traceable
### --
sub traceable {
    my ($self, $path, $cb) = @_;
    
    my $stash = Marquee->c->stash;
    
    local $stash->{'mrqe.template_path'} =
                                    [$path, $stash->{'mrqe.template_path'}];
    
    return $cb->();
}

1;

__END__

=head1 NAME

Marquee::SSIHandler - SSI handler base class

=head1 SYNOPSIS

    package Marquee::SSIHandler::EPL;
    use Mojo::Base 'Marquee::SSIHandler';
    
    sub render {
        my ($self, $path) = @_;
        
        ...;
        
        return $out;
    }

=head1 DESCRIPTION

This is a SSI handler base class to be inherited by handler classes. The sub
class is MUST implement L</render> method.

=head1 ATTRIBUTES

L<Marquee::SSIHandler> implements the following attributes.

=head2 C<log>

L<Mojo::Log> instance. Defaults to C<$app-E<gt>log> if exists.

    $handler->log('/path/to/handler.log');
    $path = $handler->log;

=head1 CLASS METHODS

L<Marquee::SSIHandler> implements the following class methods.

=head2 C<current_template>

Detects current template recursively.

    my $current_template = Marquee::SSIHandler->current_template;
    my $parent_template = Marquee::SSIHandler->current_template(1);

=head1 INSTANCE METHODS

L<Marquee::SSIHandler> implements the following instance methods.

=head2 C<render>

Renders templates. The sub classes MUST override(implement) the method.
    
    sub render {
        my ($self, $path) = @_;
        
        ...;
        
        return $out;
    }

Somewhere..

    $handler->render($path);

=head2 C<render_traceable>

Traceably renders templates by stacking template names recursively.

    $handler->render_traceable($path);

=head2 C<traceable>

Invokes the callback traceable.

    $handler->traceable($path, sub {...});

=head1 SEE ALSO

L<Marquee::SSIHandler::EPL>,
L<Marquee::SSIHandler::EP>, L<Marquee>, L<Mojolicious>

=cut
