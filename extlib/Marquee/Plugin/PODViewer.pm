package Marquee::Plugin::PODViewer;
use strict;
use warnings;
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::Util qw'url_escape unindent encode decode';
use Mojo::Base 'Marquee::Plugin';
use Pod::Simple::HTML;
use Pod::Simple::Search;

__PACKAGE__->attr('paths', sub { [map { $_, "$_/pods" } @INC] });
__PACKAGE__->attr('no_see_also');

sub register {
    my ($self, $app, $conf) = @_;
    
    push(@{$app->roots}, __PACKAGE__->Marquee::asset());
    
    $self->paths($conf->{paths}) if $conf->{paths};
    $self->no_see_also($conf->{no_see_also} || 0);
    
    if (! $conf->{no_route}) {
        $app->plugin('Router' => sub {
            my $r = shift;
            $r->route(qr{^/perldoc/(.+)})->to(sub {
                $self->serve_pod_by_name(shift)
            });
            $r->route(qr{^/perldoc/})->to(sub {
                $self->serve_index;
            });
        });
    }
}

sub serve_index {
    my ($self) = @_;

    my $c   = Marquee->c;
    my $app = $c->app;

    my $search = Pod::Simple::Search->new;
    $search->inc(0);
    my $res = $search->limit_glob('*')->survey(@{$self->paths});
    my @found = sort {$a cmp $b} keys %$res;
    
    $c->stash->set(
        static_dir  => 'static',
        modules     => \@found,
    );
    
    $c->res->body(
        encode('UTF-8',
            $app->dynamic->handlers->{ep}->render_traceable(
                __PACKAGE__->Marquee::asset('perldoc_index.html.ep')
            )
        )
    );
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

sub serve_pod {
    my ($self, $source, $podname) = @_;
    
    my $c   = Marquee->c;
    my $app = $c->app;
    
    my $html = _pod_to_html($source);
    
    # Rewrite links
    my $dom = Mojo::DOM->new($html);
    $dom->find('a[href]')->each(sub {
        my $attr = shift->attr;
        if ($attr->{href} =~ s{^http\://search\.cpan\.org/perldoc\?}{
                $app->dynamic->handlers->{ep}->url_for('/perldoc/')
            }e) {
            $attr->{href} =~ s!%3A%3A!/!gi;
        }
    });

    # Rewrite code blocks for syntax highlighting
    for my $e ($dom->find('pre')->each) {
        $e->content(my $str = unindent $e->content);
        next if $str =~ /^\s*(?:\$|Usage:)\s+/m || $str !~ /[\$\@\%]\w|-&gt;\w/m;
        my $attrs = $e->attr;
        my $class = $attrs->{class};
        $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
    }
    
    # Rewrite headers
    my (%anchors, @parts);
    $dom->find('h1, h2, h3')->each(sub {
        my $e = shift;
        my $anchor = my $text = $e->all_text;
        $anchor =~ s/\s+/_/g;
        $anchor = url_escape $anchor, '^A-Za-z0-9_';
        $anchor =~ s/\%//g;
        my $org = $anchor;
        my $i   = 1;
        $anchor = $org . $i++ while $anchors{$anchor}++;
        push @parts, [] if $e->type eq 'h1' || !@parts;
        push @{$parts[-1]}, $text, "#$anchor";
        $e->content(qq{<a name="$anchor">$text</a>});
    });
    
    # Try to find a title
    my $title = 'Perldoc';
    $dom->find('h1 + p')->first(sub {
        $title = shift->text
    });
    
    Marquee->c->stash->set(
        title       => $title,
        parts       => \@parts,
        static_dir  => 'static',
        perldoc     => "$dom",
        see_also    => ! $self->no_see_also
            ? _detect_see_also(
                    $self, (($podname || $title) =~ qr{(^[a-zA-Z0-9:]+)})[0])
            : undef,
    );
    
    $c->res->body(
        encode('UTF-8',
            $app->dynamic->handlers->{ep}->render_traceable(
                __PACKAGE__->Marquee::asset('perldoc.html.ep')
            )
        )
    );
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

sub serve_pod_by_name {
    my ($self, $module) = @_;
    
    $module =~ s!/!\:\:!g;
    
    my $c       = Marquee->c;
    my $app     = $c->app;
    my $search  = Pod::Simple::Search->new;
    $search->inc(0);
    my $path    = $search->find($module, @{$self->paths});
    
    if (! $path || ! -r $path) {
        return $app->serve_redirect("http://metacpan.org/module/$module");
    }
    
    open my $file, '<', $path;
    $self->serve_pod(join('', <$file>), $module);
}

sub _detect_see_also {
    my ($self, $module) = @_;
    
    my $search = Pod::Simple::Search->new;
    $search->inc(0);
    my @relatives;
    
    if (my $parent = ($module =~ qr{(.+)::\w+$})[0]) {
        my $b = $search->limit_glob($parent)->survey(@{$self->paths});
        push(@relatives, keys %$b);
    }
    
    my $a = $search->limit_glob($module. '::*')->survey(@{$self->paths});
    push(@relatives, grep {$_ =~ qr{^$module\::\w+$}} keys %$a);
    
    return \@relatives;
}

sub _pod_to_html {
    return unless defined(my $pod = shift);
  
    # Parser
    my $parser = Pod::Simple::HTML->new;
    $parser->force_title('');
    $parser->html_header_before_title('');
    $parser->html_header_after_title('');
    $parser->html_footer('');
  
    # Parse
    $parser->output_string(\(my $output));
    return $@ unless eval { $parser->parse_string_document($pod); 1 };
  
    # Filter
    $output =~ s!<a name='___top' class='dummyTopAnchor'\s*?></a>\n!!g;
    $output =~ s!<a class='u'.*?name=".*?"\s*>(.*?)</a>!$1!sg;
  
    return $output;
}

1;

__END__

=head1 NAME

Marquee::Plugin::PODRenderer - POD renderer plugin

=head1 SYNOPSIS

    $app->plugin('PODViewer');
    
    # on brower the following url for example will be available.
    #
    # http://localhost:3000/perldoc/LWP

=head1 DESCRIPTION

This is a plugin for POD Viewer server.

=head1 ATTRIBUTES

L<Marquee::Plugin::PODViewer> inherits all attributes from
L<Marquee::Plugin> and implements the following new ones.

=head2 C<no_see_also>

Disables auto detection of relative modules, defaults to undef(enabled).

    $self->no_see_also(1);
    my $bool = $self->no_see_also;
    
=head2 C<paths>

A path to discover modules.

    $plugin->paths([$path1, $path2, $path3]);
    my $paths = $plugin->paths;

=head1 INSTANCE METHODS

L<Marquee::Plugin::PODViewer> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin.

    $self->register($app);

=head2 serve_index

Serves index of modules.

    $plugin->serve_index;

=head2 serve_pod

Parse POD string and generate HTML. optional parameter $mod_name specifies
module name and used for see also detection.

    $plugin->serve_pod($pod, 'Path::To::Mod');

=head2 serve_pod_by_name

Generate HTML by given module name.

    $plugin->serve_pod_by_name('Path::To::Mod');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
