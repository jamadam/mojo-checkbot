package Marquee::ErrorDocument;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Util qw'encode decode';

my %catalog = (
    404 => 'File Not Found',
    500 => 'Internal Server Error',
    403 => 'Forbidden',
);

__PACKAGE__->attr('template', sub {Marquee->asset('error_document.html.ep')});
__PACKAGE__->attr('status_template' => sub {{}});

### --
### Serve error document
### --
sub serve {
    my ($self, $code, $message) = @_;
    
    my $c           = Marquee->c;
    my $stash       = $c->stash;
    my $template    = ($self->status_template)->{$code} || $self->template;
    my $ep          = $c->app->dynamic->handlers->{ep};
    
    if ($c->app->under_development) {
        my $snapshot = $stash->clone;
        $ep->add_function(snapshot => sub {$snapshot});
        $template = Marquee->asset('debug_screen.html.ep');
        $message = ref $message
                ? $message
                : Mojo::Exception->new($message || $catalog{$code});
    }
    
    $stash->set(
        static_dir  => 'static',
        code        => $code,
        message     => $message || $catalog{$code},
    );
    
    $c->res->code($code);
    $c->res->body(encode('UTF-8', $ep->render_traceable($template)));
    $c->res->headers->content_type('text/html;charset=UTF-8');
}

1;

__END__

=head1 NAME

Marquee::ErrorDocument - ErrorDocument

=head1 SYNOPSIS

    my $error_doc = Marquee::ErrorDocument->new;
    $error_doc->render(404, 'File not found');

=head1 DESCRIPTION

L<Marquee::ErrorDocument> represents error document.

=head1 ATTRIBUTES

L<Marquee::ErrorDocument> implements the following attributes.

=head2 C<template>

    $error_doc->template('/path/to/template.html.ep');

=head2 C<status_template>

    $error_doc->status_template->{404} = '/path/to/template.html.ep';

=head1 INSTANCE METHODS

L<Marquee::ErrorDocument> implements the following instance methods.

=head2 C<serve>

Serves error document.

    $error_doc->serve(404);
    $error_doc->serve(404, 'File not found');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
