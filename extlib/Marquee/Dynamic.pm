package Marquee::Dynamic;
use strict;
use warnings;
use Mojo::Base -base;
use File::Spec::Functions;
use Mojo::Util qw'encode';

__PACKAGE__->attr(handlers => sub {{}});
__PACKAGE__->attr('roots');
__PACKAGE__->attr('handler_re' => sub {
    '\.(?:'. join('|', keys %{shift->handlers}). ')$'
});

### --
### Add SSI handler
### --
sub add_handler {
    my ($self, $name, $handler) = @_;
    $self->handlers->{$name} = $handler;
    return $self;
}

### --
### search template
### --
sub search {
    my ($self, $path) = @_;
    
    for my $root (file_name_is_absolute($path) ? undef : @{$self->roots}) {
        my $base = $root ? catdir($root, $path) : $path;
        for my $ext (keys %{$self->handlers}) {
            if (-f (my $path = "$base.$ext")) {
                return $path;
            }
        }
    }
}

### --
### serve dynamic content
### --
sub serve {
    my ($self, $path) = @_;
    
    my $c = Marquee->c;
    
    my $ret = $self->render($path);
    
    if (defined $ret && ! $c->served) {
        $c->res->body(encode('UTF-8', $ret));
        $c->res->code(200);
        my $ext = ($path =~ qr{\.(\w+)(?:\.\w+)?$})[0];
        if (my $type = $c->app->types->type($ext)) {
            $c->res->headers->content_type($type);
        }
    }
}

### --
### detect and render
### --
sub render {
    my ($self, $path, $handler_ext) = @_;
    my $ext = $handler_ext || ($path =~ qr{\.\w+\.(\w+)$})[0];
    if (my $handler = $self->handlers->{$ext}) {
        return $handler->render_traceable($path);
    } else {
        die "SSI handler not detected for $path";
    }
}

1;

__END__

=head1 NAME

Marquee::Dynamic - Dynamic server

=head1 SYNOPSIS

    my $dynamic = Maruqee::dynamic->new;
    $dynamic->add_handler(ep => Marquee::SSIHandler::EP->new());
    $dynamic->serve('/path/to/template.html.ep');

=head1 DESCRIPTION

L<Marquee::Dynamic> represents dynamic page server.

=head1 ATTRIBUTES

L<Marquee::Dynamic> implements the following attributes.

=head2 C<handlers>

An hash ref that contains Server side include handlers. The hash keys
corresponds to the last extensions of templates.

    $dynamic->handlers->{myhandler} = Marquee::SSIHandler::MyHandler->new;

=head2 C<handler_re>

A regex pattern to detect handler extensions. This is automatically generated.

    my $regex = $dynamic->handler_re;

=head2 C<roots>

Root array for searching templates.

    $dynamic->roots(['path/to/dir1', 'path/to/dir1']);
    my $roots = $dynamic->roots;

=head1 INSTANCE METHODS

L<Marquee::Dynamic> implements the following instance methods.

=head2 C<add_handler>

Adds L</handlers> entry. The first argument is corresponds to
the last extensions of templates. Second argument must be a
L<Marquee::SSIHandler> sub class instance. See L<Marquee::SSIHandler::EPL> as an
example.

    $dynamic->add_handler(myhandler => Marquee::SSIHandler::MyHandler->new);

Following file will be available.

    template.html.myhandler

=head2 C<render>

Render given file of path as SSI template and returns the result.
This method auto detect the handler with the file name unless second argument is
given. Note that the renderer extension is NOT to be suffixed automatically.

    # render /path/to/template.html.ep by ep handler
    my $result = $dynamic->render('/path/to/template.html.ep');
    
    # render /path/to/template.html.ep by epl handler
    my $result = $dynamic->render('/path/to/template.html.ep', 'epl');
    
    # render /path/to/template.html by ep handler
    my $result = $dynamic->render('/path/to/template2.html', 'ep');

=head2 C<search>

Searches for SSI template for given path and returns the path with SSI
extension if exists. The search is made within the directories out of C</roots>
attribute.

    my $path = $dynamic->search('./tmpl.html'); # /path/to/document_root/tmpl.html.ep
    my $path = $dynamic->search('/path/to/tmpl.html'); # /path/to/tmpl.html.ep

=head2 C<serve>

Serves dynamic page.

    $dynamic->serve('/path/to/template.html.ep');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
