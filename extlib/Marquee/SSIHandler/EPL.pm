package Marquee::SSIHandler::EPL;
use strict;
use warnings;
use Mojo::Base 'Marquee::SSIHandler';
use Marquee::Cache;
use Mojo::Util qw{encode md5_sum};
use Mojo::Template;

__PACKAGE__->attr('template_cache' => sub {Marquee::Cache->new});

### --
### Accessor to template cache
### --
sub cache {
    my ($self, $path, $mt, $expire) = @_;
    
    my $cache = $self->template_cache;
    my $key = md5_sum(encode('UTF-8', $path));
    if ($mt) {
        $cache->set($key, $mt, $expire);
    } else {
        $cache->get($key);
    }
}

### --
### EPL handler
### --
sub render {
    my ($self, $path) = @_;
    
    my $c = Marquee->c;
    
    my $mt = $self->cache($path);
    
    if (! $mt) {
        $mt = Mojo::Template->new;
        $self->cache($path, $mt, sub {$_[0] < (stat($path))[9]});
    }
    
    my $output = $mt->compiled
            ? $mt->interpret($self, $c) : $mt->render_file($path, $self, $c);
    
    return ref $output ? die $output : $output;
}

1;

__END__

=head1 NAME

Marquee::SSIHandler::EPL - EPL template handler

=head1 SYNOPSIS

    my $epl = Marquee::SSIHandler::EPL->new;
    $epl->render('/path/to/template.html.ep');

=head1 DESCRIPTION

EPL handler.

=head1 ATTRIBUTES

L<Marquee::SSIHandler::EPL> inherits all attributes from
L<Marquee::SSIHandler> and implements the following new ones.

=head2 C<template_cache>

    my $cache = $epl->template_cache;

=head1 INSTANCE METHODS

L<Marquee::SSIHandler::EPL> inherits all instance methods from
L<Marquee::SSIHandler> and implements the following new ones.

=head2 C<cache>

Get or set cache.

    $epl->cache('/path/to/template.html.ep', $mt);
    my $mt = $epl->cache('/path/to/template.html.ep');

=head2 C<render>

Renders given template and returns the result. If rendering fails, die with
L<Mojo::Exception>.

    $epl->render('/path/to/template.html.epl');

=head1 SEE ALSO

L<Marquee::SSIHandler>, L<Marquee>, L<Mojolicious>

=cut
