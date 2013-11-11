package Marquee::Static;
use strict;
use warnings;
use Mojo::Base -base;
use File::Spec::Functions;

__PACKAGE__->attr('maxage' => 0);
__PACKAGE__->attr('roots');

### --
### search static file
### --
sub search {
    my ($self, $path) = @_;
    
    for my $root (file_name_is_absolute($path) ? undef : @{$self->roots}) {
        if (-f (my $path = $root ? catdir($root, $path) : $path)) {
            return $path;
        }
    }
}

### --
### serve static content
### --
sub serve {
    my ($self, $path) = @_;
    
    my $c = Marquee->c;
    my $asset = Mojo::Asset::File->new(path => $path);
    my $modified = (stat $path)[9];
    
    # If modified since
    my $req_headers = $c->req->headers;
    my $res_headers = $c->res->headers;
    if (my $date = $req_headers->if_modified_since) {
        my $since = Mojo::Date->new($date)->epoch;
        if (defined $since && $since == $modified) {
            $res_headers->remove('Content-Type')
                ->remove('Content-Length')
                ->remove('Content-Disposition');
            return $c->res->code(304);
        }
    }
    
    $c->res->content->asset($asset);
    $c->res->code(200);
    
    if (my $type = $c->app->types->type_by_path($path)) {
        $c->res->headers->content_type($type);
    }
    
    $res_headers->last_modified(Mojo::Date->new($modified));
    
    # maxage
    if ($self->maxage) {
        $res_headers->add('Cache-Control', 'max-age='. $self->maxage);
    }
}

1;

__END__

=head1 NAME

Marquee::Static - Static server

=head1 SYNOPSIS

    my $static = Maruqee::Static->new;
    $static->maxage(3600);
    $static->serve('/path/to/file.png');

=head1 DESCRIPTION

L<Marquee::Static> represents static file server.

=head1 ATTRIBUTES

L<Marquee::Static> implements the following attributes.

=head2 C<maxage>

    $static->maxage(3600);

=head2 C<roots>

Root array for searching static files.

    $dynamic->roots(['path/to/dir1', 'path/to/dir1']);
    my $roots = $dynamic->roots;

=head1 INSTANCE METHODS

L<Marquee::Static> implements the following instance methods.

=head2 C<search>

Searches for static files for given path and returns the path if exists.
The search is made within the directories out of L</roots> attribute.

    my $path = $static->search('./a.html'); # /path/to/document_root/a.html
    my $path = $static->search('/path/to/a.html'); # /path/to/a.html

=head2 C<serve>

Serves static file.

    $static->serve('/path/to/static.png');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
