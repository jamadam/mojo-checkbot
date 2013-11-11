package Marquee::SSIHandler::EP;
use strict;
use warnings;
use Mojo::Base 'Marquee::SSIHandler::EPL';
use File::Basename 'dirname';
use Mojo::ByteStream 'b';
use Mojo::Template;
use Mojo::Path;
use Encode 'decode_utf8';
use Carp;
use Data::Dumper;

### --
### Function definitions for inside template
### --
__PACKAGE__->attr(funcs => sub {{}});

### --
### Constructor
### --
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_init;
    return $self;
}

### --
### Add function
### --
sub add_function {
    my ($self, $name, $cb) = @_;
    
    if ($name =~ /\W/) {
        croak "Function name must be consitsts of [a-zA-Z0-9]";
    }
    if ($] >= 5.016 && defined(&{"CORE::". $name})) {
        croak qq{Can't modify built-in function $name};
    }
    if ($self->funcs->{$name}) {
        $self->log->warn("Function $name will be redefined");
    }
    $self->funcs->{$name} = $cb;
    return $self;
}

### --
### ep handler
### --
sub render {
    my ($self, $path) = @_;
    
    my $c = Marquee->c;
    
    my $mt = $self->cache($path);
    
    if (! $mt) {
        $mt = Mojo::Template->new();
        $mt->auto_escape(1);
        
        # Be a bit more relaxed for helpers
        my $prepend = q/no strict 'refs'; no warnings 'redefine';/;

        # Helpers
        $prepend .= 'my $_H = shift; my $_F = $_H->funcs;';
        for my $name (keys %{$self->funcs}) {
            $prepend .= "sub $name; *$name = sub {\$_F->{$name}->(\$_H, \@_)};";
        }
        
        $prepend .= 'use strict;';
        for my $var (keys %{$c->stash}) {
            if ($var =~ /^\w+$/) {
                $prepend .= " my \$$var = stash '$var';";
            }
        }
        $mt->prepend($prepend);
        
        $self->cache($path, $mt, sub {$_[0] < (stat($path))[9]});
    }
    
    my $output = $mt->compiled
            ? $mt->interpret($self, $c) : $mt->render_file($path, $self, $c);
    
    return ref $output ? die $output : $output;
}

### --
### load preset
### --
sub _init {
    my $self = shift;
    
    $self->funcs->{app} = sub {
        shift;
        return Marquee->c->app;
    };
    
    $self->funcs->{param} = sub {
        shift;
        return Marquee->c->req->param($_[0]);
    };
    
    $self->funcs->{session} = sub {
        shift;
        my $sesison = Marquee->c->session;
        if ($_[0] && $_[1]) {
            return $sesison->{$_[0]} = $_[1];
        } elsif (! $_[0]) {
            return $sesison;
        } else {
            return $sesison->{$_[0]};
        }
    };
    
    $self->funcs->{stash} = sub {
        shift;
        my $stash = Marquee->c->stash;
        if ($_[0] && $_[1]) {
            return $stash->set(@_);
        } elsif (! $_[0]) {
            return $stash;
        } else {
            return $stash->{$_[0]};
        }
    };
    
    $self->funcs->{current_template} = sub {
        return shift->current_template(@_);
    };
    
    $self->funcs->{dumper} = sub {
        shift;
        return Data::Dumper->new([@_])->Indent(1)->Terse(1)->Dump;
    };
    
    $self->funcs->{to_abs} = sub {
        return shift->_to_abs(@_);
    };
    
    $self->funcs->{include} = sub {
        my ($self, $path, @args) = @_;
        
        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        if (my $path = $app->static->search($path)) {
            return b(decode_utf8(Mojo::Asset::File->new(path => $path)->slurp));
        }
        
        if (my $path = $app->dynamic->search($path)) {
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(@args);
            return b($app->dynamic->render($path));
        }
        
        die "$path not found";
    };
    
    $self->funcs->{include_as} = sub {
        my ($self, $path, $handler, @args) = @_;
        
        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        if (my $path = $app->static->search($path)) {
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(@args);
            return b($app->dynamic->render($path, $handler));
        }
        
        die "$path not found";
    };
    
    $self->funcs->{iter} = sub {
        my $self    = shift;
        my $block   = pop;
        
        my $ret = '';
        
        if (ref $_[0] eq 'ARRAY') {
            my $idx = 0;
            for my $elem (@{$_[0]}) {
                $ret .= $block->($elem, $idx++);
            }
        } elsif (ref $_[0] eq 'HASH') {
            for my $key (keys %{$_[0]}) {
                $ret .= $block->($key, $_[0]->{$key});
            }
        } else {
            my $idx = 0;
            for my $elem (@_) {
                $ret .= $block->($elem, $idx++);
            }
        }
        
        return b($ret);
    };
    
    $self->funcs->{override} = sub {
        my ($self, $name, $value) = @_;
        my $path = $self->current_template;
        Marquee->c->stash->set(_ph_name($name) => sub {
            $self->traceable($path, $value)
        });
        return;
    };
    
    $self->funcs->{url_for} = sub {
        return shift->url_for(@_);
    };
    
    $self->funcs->{placeholder} = sub {
        my ($self, $name, $defalut) = @_;
        my $block = Marquee->c->stash->{_ph_name($name)} || $defalut;
        return $block->() || '';
    };
    
    $self->funcs->{extends} = sub {
        my ($self, $path, $block) = @_;
        
        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        local $c->{stash} = $c->{stash}->clone;
        
        $block->();
        
        if (my $path = $app->dynamic->search($path)) {
            return b($app->dynamic->render($path, 'ep'));
        }
        
        die "$path not found";
    };
    
    $self->funcs->{extends_as} = sub {
        my ($self, $path, $handler, $block) = @_;

        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        local $c->{stash} = $c->{stash}->clone;
        
        $block->();
        
        if (my $path = $app->static->search($path)) {
            return b($app->dynamic->render($path, $handler));
        }
        
        die "$path not found";
    };
    
    return $self;
}

### --
### Generate portable URL
### --
sub url_for {
    my ($self, $path) = @_;
    
    # base path for CGI environment
    if ($ENV{DOCUMENT_ROOT} && ! defined $ENV{MARQUEE_BASE_PATH}) {
        my $tmp = Marquee->c->app->home->to_string;
        if ($tmp =~ s{^\Q$ENV{DOCUMENT_ROOT}\E}{}) {
            $ENV{MARQUEE_BASE_PATH} = $tmp;
        }
    }
    
    $path =~ s{^\.*/}{};
    my $abs = Mojo::Path->new($ENV{'MARQUEE_BASE_PATH'});
    $abs->trailing_slash(1);
    $abs->merge($path);
    $abs->leading_slash(1);
    
    return $abs;
}

### --
### Generate safe name for placeholder
### --
sub _ph_name {
    return "mrqe.SSIHandler.EP.". shift;
}

### --
### generate file path relative to document root
### --
sub _doc_path {
    my ($self, $path) = @_;
    
    if ($path =~ qr{^/(.+)}) {
        return File::Spec->canonpath($1);
    } else {
        $path = File::Spec->catfile(dirname($self->current_template), $path);
        $path = File::Spec->canonpath($path);
        for my $root (@{Marquee->c->app->roots}) {
            last if ($path =~ s{^\Q$root\E/}{});
        }
        return $path;
    }
}

### --
### abs
### --
sub _to_abs {
    my ($self, $path) = @_;
    
    (my $root, $path) = ($path =~ qr{^/(.+)})
                                ? (Marquee->c->app->home, $1)
                                : (dirname($self->current_template), $path);
    
    return File::Spec->canonpath(File::Spec->catfile($root, $path));
}

1;

__END__

=head1 NAME

Marquee::SSIHandler::EP - EP template handler

=head1 SYNOPSIS

    my $ep = Marquee::SSIHandler::EP->new;
    $ep->render('/path/to/template.html.ep');

=head1 DESCRIPTION

L<Marquee::SSIHandler::EP> is a EP handler.

=head1 ATTRIBUTES

L<Marquee::SSIHandler::EP> inherits all attributes from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

=head2 C<funcs>

A Hash ref that contains template functions.

    $ep->funcs->{some_func} = sub {...};

You can use L</add_function> method to add a function entry instead of the code
above.

=head1 FUNCTIONS

Following template functions are automatically available.

=head2 C<current_template>

Returns current template path.

    <% my $path = current_template(); %>

=head2 C<extends>

L</extends> function cooperates with L</placeholder> and L</override>,
provides template inheritance mechanism.

Base template named C<layout/common.html.ep>.

    <!doctype html>
    <html>
        <head>
            <title><%= placeholder 'title' => begin %>DEFAULT TITLE<% end %></title>
        </head>
        <body>
            <div id="main">
                <%= placeholder 'main' => begin %>
                    DEFAULT MAIN
                <% end %>
            </div>
            <div id="main2">
                <%= placeholder 'main2' => begin %>
                    DEFAULT MAIN2
                <% end %>
            </div>
        </body>
    </html>

A template can extends C<common.html.ep> as follows. The path can be relative to
current template directory or relative to document root if leading slashed.
The handler is auto detected so you don't need to specify the extension.

    <%= extends './layout/common.html' => begin %>
        <% override 'title' => begin %>
            title
        <% end %>
        <% override 'main' => begin %>
            <div>
                main content<%= time %>
            </div>
        <% end %>
    <% end %>

=head2 C<extends_as>

L</extends_as> inherits a template and extends it.
This function is similar to L</extends> but you can specify the handler
the template would be parsed with.

Note that the C<template.html> MUST NOT be name as C<template.html.ep>

    <%= extends_as './path/to/template.html', 'ep' => begin %>
    ...
    <% end %>

=head2 C<iter>

Array iterator with a block.

    <%= iter @array => begin %>
        <% my ($elem, $index) = @_; %>
        No.<%= $index %> is <%= $elem %>
    <% end %>

Array refs and Hash refs are also accepted.

    <%= iter $array_ref => begin %>
        <% my ($elem, $index) = @_; %>
        No.<%= $index %> is <%= $elem %>
    <% end %>

    <%= iter $hash_ref => begin %>
        <% my ($key, $value) = @_; %>
        <%= $key %> is <%= $value %>
    <% end %>

=head2 C<include>

Include a template or a static files into current template. The path can be
relative to current template directory or relative to document root if leading
slashed. 

    <%= include('./path/to/template.html', key => value) %>
    <%= include('/path/to/template.html', key => value) %>

=head2 C<include_as>

Include a template into current template. This function is
similar to include but you can specify the handler the template would be parsed
with.

    <%= include_as('./path/to/template.html', 'ep', key => value) %>

=head2 C<override>

Override placeholder. See L</extends> method.

=head2 C<param>

Returns request parameters for given key.

    <%= param('key') %>

=head2 C<placeholder>

Set placeholder with default block. See L</extends> method.

=head2 C<session>

Sets or get a session value or get all data in hash.

    <%= session('key') %>
    <% session('key', 'value'); %>
    <% $hash = session(); %>

=head2 C<stash>

Returns stash value for given key.

    <%= stash('key') %>

=head2 C<to_abs>

Generates absolute path for server filesystem root with given relative one.
Leading dot-segment indicates current file and the leading slash indicates
Marquee root.

    <%= to_abs('/path.css') %> <!-- /path/to/Marquee/path.css -->

At C</path/to/Marquee/html/category/index.html>

    <%= to_abs('./path.css') %> <!-- /path/to/Marquee/html/category/path.css  -->

=head2 C<url_for>

Generates a portable URL relative to document root.

    <%= url_for('./b.css') %> # current is '/a/.html' then generates '/a/b.css'
    <%= url_for('/b.css') %>  # current is '/a/.html' then generates '/b.css'

=head1 CLASS METHODS

L<Marquee::SSIHandler::EP> inherits all class methods from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

=head2 C<new>

Constructor.

    my $ep = Marquee::SSIHandler::EP->new;

=head1 INSTANCE METHODS

L<Marquee::SSIHandler::EP> inherits all instance methods from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

=head2 C<add_function>

Adds a function to the renderer.

    $ep->add_function(html_to_text => sub {
        my ($ep, $html) = @_;
        return Mojo::DOM->new($html)->all_text;
    });

in templates...

    <%= html_to_text($html) %>

=head2 C<render>

Renders given template and returns the result. If rendering fails, die with
L<Mojo::Exception>.

    $ep->render('/path/to/template.html.ep');

=head2 C<url_for>

Generates a portable URL relative to document root.

    $ep->url_for('./path.css')

=head1 SEE ALSO

L<Marquee::SSIHandler>, L<Marquee>, L<Mojolicious>

=cut
