package Marquee::Plugin::AutoIndex;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
use Mojo::Util qw'url_unescape encode decode';
use File::Basename 'basename';

__PACKAGE__->attr(max_per_dir => 50);
__PACKAGE__->attr(tree_depth => 4);

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app, $args) = @_;
    
    push(@{$app->roots}, __PACKAGE__->Marquee::asset());
    
    $app->hook(around_dispatch => sub {
        my ($next) = @_;
        
        $next->();
        
        my $c = Marquee->c;
        
        if (! $c->served) {
            my $app = $c->app;
            my $path = $c->req->url->path->clone->canonicalize;
            if (@{$path->parts}[0] && @{$path->parts}[0] eq '..') {
                return;
            }
            if (-d File::Spec->catdir($app->document_root, $path)) {
                my $mode = $c->req->param('mode');
                if ($mode && $mode eq 'tree') {
                    $self->serve_tree($path);
                } else {
                    $self->serve_index($path);
                }
            }
        }
    });
}

### ---
### Server directory tree
### ---
sub serve_tree {
    my ($self, $path) = @_;
    
    my $c   = Marquee->c;
    my $app = Marquee->c->app;
    my $maxdepth = 3;
    
    $c->stash->set(
        dir         => $path,
        static_dir  => 'static',
        tree_depth  => $self->tree_depth,
    );
    
    my $ep = Marquee::SSIHandler::EP->new;
    $ep->add_function(filelist => sub {
        return _file_list($self, $_[1], $path);
    });
    
    $c->res->body(
        encode('UTF-8', $ep->render_traceable(
            __PACKAGE__->Marquee::asset('auto_index_tree.html.ep')
        ))
    );
    
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

### ---
### Render file list
### ---
sub serve_index {
    my ($self, $path) = @_;
    
    my $c = Marquee->c;
    my $app = $c->app;
    
    $c->stash->set(
        dir         => decode('UTF-8', url_unescape($path)),
        dataset     => _file_list($self, '', $path),
        static_dir  => 'static'
    );
    
    $c->res->body(
        encode('UTF-8',
            Marquee::SSIHandler::EP->new->render_traceable(
                __PACKAGE__->Marquee::asset('auto_index.html.ep')
            )
        )
    );
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

### ---
### File list
### ---
sub _file_list {
    my ($self, $cpath, $path) = @_;
    my $app = Marquee->c->app;
    
    $cpath ||= $path;
    $cpath =~ s{/$}{};
    $cpath = decode('UTF-8', url_unescape($cpath));
    my $fixed_path = File::Spec->catfile($app->document_root, $cpath);
    opendir(my $dh, $fixed_path);
    
    my @files = grep {
        $_ !~ qr{^\.$} && ($path eq '/' ? $_ !~ qr{^\.\.$} : 1)
    } readdir($dh);
    
    @files = map {
        my $name = decode('UTF-8', url_unescape($_));
        my $pub_name = $name;
        my $handler_regex = $app->dynamic->handler_re;
        $pub_name =~ s{(\.\w+)$handler_regex}{$1};
        my $real_abs = File::Spec->catfile($fixed_path, $name);
        {
            type        => -d $real_abs
                ? 'dir'
                : (($app->types->type_by_path($pub_name) || 'text') =~ /^(\w+)/)[0],
            name        => "$cpath/$pub_name",
            timestamp   => _file_timestamp($real_abs),
            size        => _file_size($real_abs),
        }
    } @files;
    
    @files = sort {
        ($a->{type} ne 'dir') <=> ($b->{type} ne 'dir')
        ||
        basename($a->{name}) cmp basename($b->{name})
    } @files;
    
    closedir($dh);
    
    if (@files > $self->max_per_dir) {
        splice(@files, $self->max_per_dir);
    }
    
    return \@files;
}

### ---
### Get file utime
### ---
sub _file_timestamp {
    my $path = shift;
    my @dt = localtime((stat($path))[9]);
    return sprintf('%d-%02d-%02d %02d:%02d',
                        1900 + $dt[5], $dt[4] + 1, $dt[3], $dt[2], $dt[1]);
}

### ---
### Get file size
### ---
sub _file_size {
    my $path = shift;
    return ((stat($path))[7] > 1024)
        ? sprintf("%.1f",(stat($path))[7] / 1024) . 'KB'
        : (stat($path))[7]. 'B';
}

1;

__END__

=head1 NAME

Marquee::Plugin::AutoIndex - Auto index

=head1 SYNOPSIS

    $app->plugin('AutoIndex');

On your browser following forms of URL are available.

    http://localhost:3000/path/to/directory/
    http://localhost:3000/path/to/directory/?mode=tree

=head1 DESCRIPTION

This is a plugin for auto index. When app attribute default_file is undefined
or the file is not found, the directory access causes the auto index to be
served.

=head1 ATTRIBUTES

L<Marquee::Plugin::AutoIndex> inherits all attributes from
L<Marquee::Plugin> and implements the following new ones.

=head2 C<max_per_dir>

Max file amount to display in each directory, defaults to 50.

    $plugin->max_per_dir(100);
    my $num = $plugin->max_per_dir;

=head2 C<tree_depth>

Max depth for directory recursion, defaults to 4.

    $plugin->tree_depth(2);
    my $num = $plugin->tree_depth;

=head1 INSTANCE METHODS

L<Marquee::Plugin::AutoIndex> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin.

    $self->register($app);

=head2 serve_index

Serves auto directory index.

    $plugin->serve_index($path);

=head2 serve_tree

Serves auto directory tree.

    $plugin->serve_tree($path);

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
