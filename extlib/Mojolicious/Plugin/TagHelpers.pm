package Mojolicious::Plugin::TagHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use List::Util 'first';
use Mojo::ByteStream 'b';
use Mojo::Util 'xml_escape';

# "Is today's hectic lifestyle making you tense and impatient?
#  Shut up and get to the point!"
sub register {
  my ($self, $app) = @_;

  # Add "base_tag" helper
  $app->helper(
    base_tag => sub { $self->_tag('base', href => shift->req->url->base, @_) }
  );

  # Add "checkbox" helper
  $app->helper(
    check_box => sub {
      $self->_input(shift, shift, value => shift, @_, type => 'checkbox');
    }
  );

  # Add "file_field" helper
  $app->helper(file_field =>
      sub { shift; $self->_tag('input', name => shift, type => 'file', @_) });

  # Add "form_for" helper
  $app->helper(
    form_for => sub {
      my ($c, @url) = (shift, shift);
      push @url, shift if ref $_[0] eq 'HASH';

      # POST detection
      my @post;
      if (my $r = $c->app->routes->find($url[0])) {
        my %methods = (GET => 1, POST => 1);
        do {
          my @via = @{$r->via || []};
          %methods = map { $_ => 1 } grep { $methods{$_} } @via if @via;
        } while $r = $r->parent;
        @post = (method => 'POST') if $methods{POST} && !$methods{GET};
      }

      return $self->_tag('form', action => $c->url_for(@url), @post, @_);
    }
  );

  # Add "hidden_field" helper
  $app->helper(
    hidden_field => sub {
      shift;
      my %attrs = (type => 'hidden', name => shift, value => shift, @_);
      return $self->_tag('input', %attrs);
    }
  );

  # Add "image" helper
  $app->helper(
    image => sub { $self->_tag('img', src => shift->url_for(shift), @_) });

  # Add "input_tag" helper
  $app->helper(input_tag => sub { $self->_input(@_) });

  # Add "javascript" helper
  $app->helper(
    javascript => sub {
      my $c = shift;

      # CDATA
      my $cb = sub {''};
      if (ref $_[-1] eq 'CODE') {
        my $old = pop;
        $cb = sub { "//<![CDATA[\n" . $old->() . "\n//]]>" }
      }

      # URL
      my $src = @_ % 2 ? $c->url_for(shift) : undef;

      # Attributes
      my %attrs = (@_, $src ? (src => $src) : ());

      return $self->_tag('script', type => 'text/javascript', %attrs, $cb);
    }
  );

  # Add "link_to" helper
  $app->helper(
    link_to => sub {
      my ($c, $content) = (shift, shift);
      my @url = ($content);

      # Content
      unless (defined $_[-1] && ref $_[-1] eq 'CODE') {
        @url = (shift);
        push @_, $content;
      }

      # Captures
      push @url, shift if ref $_[0] eq 'HASH';

      return $self->_tag('a', href => $c->url_for(@url), @_);
    }
  );

  # Add "password_field" helper
  $app->helper(
    password_field => sub {
      shift;
      $self->_tag('input', name => shift, type => 'password', @_);
    }
  );

  # Add "radio_button" helper
  $app->helper(
    radio_button => sub {
      $self->_input(shift, shift, value => shift, @_, type => 'radio');
    }
  );

  # Add "select_field" helper
  $app->helper(
    select_field => sub {
      my ($c, $name, $options, %attrs) = (shift, shift, shift, @_);

      # "option" callback
      my %values = map { $_ => 1 } $c->param($name);
      my $option = sub {

        # Pair
        my $pair = shift;
        $pair = [$pair => $pair] unless ref $pair eq 'ARRAY';

        # Attributes
        my %attrs = (value => $pair->[1]);
        $attrs{selected} = 'selected' if exists $values{$pair->[1]};
        %attrs = (%attrs, @$pair[2 .. $#$pair]);

        return $self->_tag('option', %attrs, sub { xml_escape $pair->[0] });
      };

      # "optgroup" callback
      my $optgroup = sub {

        # Parts
        my $parts = '';
        for my $group (@$options) {

          # "optgroup" tag
          if (ref $group eq 'HASH') {
            my ($label, $values) = each %$group;
            my $content = join '', map { $option->($_) } @$values;
            $parts
              .= $self->_tag('optgroup', label => $label, sub {$content});
          }

          # "option" tag
          else { $parts .= $option->($group) }
        }

        return $parts;
      };

      return $self->_tag('select', name => $name, %attrs, $optgroup);
    }
  );

  # Add "stylesheet" helper
  $app->helper(
    stylesheet => sub {
      my $c = shift;

      # CDATA
      my $cb;
      if (ref $_[-1] eq 'CODE') {
        my $old = pop;
        $cb = sub { "/*<![CDATA[*/\n" . $old->() . "\n/*]]>*/" }
      }

      # URL
      my $href = @_ % 2 ? $c->url_for(shift) : undef;

      # "style" tag
      return $self->_tag('style', type => 'text/css', @_, $cb) unless $href;

      # "link" tag
      my %attrs = (href => $href, type => 'text/css', media => 'screen', @_);
      return $self->_tag('link', rel => 'stylesheet', %attrs);
    }
  );

  # Add "submit_button" helper
  $app->helper(
    submit_button => sub {
      shift;
      $self->_tag('input', value => shift // 'Ok', type => 'submit', @_);
    }
  );

  # Add "t" helper
  $app->helper(t => sub { shift; $self->_tag(@_) });

  # Add "tag" helper
  $app->helper(tag => sub { shift; $self->_tag(@_) });

  # Add "text_area" helper
  $app->helper(
    text_area => sub {
      my ($c, $name) = (shift, shift);

      # Content
      my $cb = ref $_[-1] eq 'CODE' ? pop @_ : sub {''};
      my $content = @_ % 2 ? shift : undef;

      # Make sure content is wrapped
      if (defined($content = $c->param($name) // $content)) {
        $cb = sub { xml_escape $content }
      }

      return $self->_tag('textarea', name => $name, @_, $cb);
    }
  );

  # Add "text_field" helper
  $app->helper(text_field => sub { $self->_input(@_) });
}

sub _input {
  my ($self, $c, $name) = (shift, shift, shift);

  # Attributes
  my %attrs = @_ % 2 ? (value => shift, @_) : @_;

  # Values
  my @values = $c->param($name);

  # Special selection value
  my $type = $attrs{type} || '';
  if (@values && $type ne 'submit') {

    # Checkbox or radiobutton
    my $value = $attrs{value} // '';
    if ($type eq 'checkbox' || $type eq 'radio') {
      $attrs{value} = $value;
      $attrs{checked} = 'checked' if defined first { $value eq $_ } @values;
    }

    # Others
    else { $attrs{value} = $values[0] }

    return $self->_tag('input', name => $name, %attrs);
  }

  # Empty tag
  return $self->_tag('input', name => $name, %attrs);
}

# "We’ve lost power of the forward Gameboy! Mario not responding!"
sub _tag {
  my ($self, $name) = (shift, shift);

  # Content
  my $cb = ref $_[-1] eq 'CODE' ? pop @_ : undef;
  my $content = @_ % 2 ? pop : undef;

  # Start tag
  my $tag = "<$name";

  # Attributes
  my %attrs = @_;
  for my $key (sort keys %attrs) {
    $tag .= qq/ $key="/ . xml_escape($attrs{$key} // '') . '"';
  }

  # End tag
  if ($cb || defined $content) {
    $tag .= '>' . ($cb ? $cb->() : xml_escape($content)) . "</$name>";
  }

  # Empty element
  else { $tag .= ' />' }

  # Prevent escaping
  return b($tag);
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::TagHelpers - Tag helpers plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('TagHelpers');

  # Mojolicious::Lite
  plugin 'TagHelpers';

=head1 DESCRIPTION

L<Mojolicious::Plugin::TagHelpers> is a collection of HTML5 tag helpers for
L<Mojolicious>. This is a core plugin, that means it is always enabled and
its code a good example for learning how to build new plugins.

Most form helpers can automatically pick up previous input values and will
show them as default. You can also use
L<Mojolicious::Plugin::DefaultHelpers/"param"> to set them manually and let
necessary attributes always be generated automatically.

  % param country => 'germany' unless param 'country';
  <%= radio_button country => 'germany' %> Germany
  <%= radio_button country => 'france'  %> France
  <%= radio_button country => 'uk'      %> UK

=head1 HELPERS

L<Mojolicious::Plugin::TagHelpers> implements the following helpers.

=head2 C<base_tag>

  %= base_tag

Generate portable C<base> tag refering to the current base URL.

  <base href="http://localhost/cgi-bin/myapp.pl" />

=head2 C<check_box>

  %= check_box employed => 1
  %= check_box employed => 1, id => 'foo'

Generate checkbox input element. Previous input values will automatically get
picked up and shown as default.

  <input name="employed" type="checkbox" value="1" />
  <input id="foo" name="employed" type="checkbox" value="1" />

=head2 C<file_field>

  %= file_field 'avatar'
  %= file_field 'avatar', id => 'foo'

Generate file input element.

  <input name="avatar" type="file" />
  <input id="foo" name="avatar" type="file" />

=head2 C<form_for>

  %= form_for login => (method => 'POST') => begin
    %= text_field 'first_name'
    %= submit_button
  % end
  %= form_for login => {foo => 'bar'} => (method => 'POST') => begin
    %= text_field 'first_name'
    %= submit_button
  % end
  %= form_for '/login' => (method => 'POST') => begin
    %= text_field 'first_name'
    %= submit_button
  % end
  %= form_for 'http://kraih.com/login' => (method => 'POST') => begin
    %= text_field 'first_name'
    %= submit_button
  % end

Generate portable form for route, path or URL. For routes that allow C<POST>
but not C<GET>, a C<method> attribute will be automatically added.

  <form action="/path/to/login" method="POST">
    <input name="first_name" />
    <input value="Ok" type="submit" />
  </form>
  <form action="/path/to/login/bar" method="POST">
    <input name="first_name" />
    <input value="Ok" type="submit" />
  </form>
  <form action="/login" method="POST">
    <input name="first_name" />
    <input value="Ok" type="submit" />
  </form>
  <form action="http://kraih.com/login" method="POST">
    <input name="first_name" />
    <input value="Ok" type="submit" />
  </form>

=head2 C<hidden_field>

  %= hidden_field foo => 'bar'
  %= hidden_field foo => 'bar', id => 'bar'

Generate hidden input element.

  <input name="foo" type="hidden" value="bar" />
  <input id="bar" name="foo" type="hidden" value="bar" />

=head2 C<image>

  %= image '/images/foo.png'
  %= image '/images/foo.png', alt => 'Foo'

Generate image tag.

  <img src="/images/foo.png" />
  <img alt="Foo" src="/images/foo.png" />

=head2 C<input_tag>

  %= input_tag 'first_name'
  %= input_tag first_name => 'Default name'
  %= input_tag 'employed', type => 'checkbox'

Generate form input element. Previous input values will automatically get
picked up and shown as default.

  <input name="first_name" />
  <input name="first_name" value="Default name" />
  <input name="employed" type="checkbox" />

=head2 C<javascript>

  %= javascript '/script.js'
  %= javascript begin
    var a = 'b';
  % end

Generate portable script tag for C<Javascript> asset.

  <script src="/script.js" type="text/javascript" />
  <script type="text/javascript"><![CDATA[
    var a = 'b';
  ]]></script>

=head2 C<link_to>

  %= link_to Home => 'index'
  %= link_to index => {foo => 'bar'} => (class => 'links') => begin
    Home
  % end
  <%= link_to index => begin %>Home<% end %>
  <%= link_to '/path/to/file' => begin %>File<% end %>
  <%= link_to 'http://mojolicio.us' => begin %>Mojolicious<% end %>
  <%= link_to url_for->query(foo => 'bar')->to_abs => begin %>Retry<% end %>

Generate portable link to route, path or URL, defaults to using the
capitalized link target as content.

  <a href="/path/to/index">Home</a>
  <a class="links" href="/path/to/index/bar">Home</a>
  <a href="/path/to/index">Home</a>
  <a href="/path/to/file">File</a>
  <a href="http://mojolicio.us">Mojolicious</a>
  <a href="http://127.0.0.1:3000/current/path?foo=bar">Retry</a>

=head2 C<password_field>

  %= password_field 'pass'
  %= password_field 'pass', id => 'foo'

Generate password input element.

  <input name="pass" type="password" />
  <input id="foo" name="pass" type="password" />

=head2 C<radio_button>

  %= radio_button country => 'germany'
  %= radio_button country => 'germany', id => 'foo'

Generate radio input element. Previous input values will automatically get
picked up and shown as default.

  <input name="country" type="radio" value="germany" />
  <input id="foo" name="country" type="radio" value="germany" />

=head2 C<select_field>

  %= select_field language => [qw/de en/]
  %= select_field language => [qw/de en/], id => 'lang'
  %= select_field country => [[Germany => 'de'], 'en']
  %= select_field country => [{Europe => [[Germany => 'de'], 'en']}]
  %= select_field country => [[Germany => 'de', class => 'europe'], 'en']

Generate select, option and optgroup elements. Previous input values will
automatically get picked up and shown as default.

  <select name="language">
    <option value="de">de</option>
    <option value="en">en</option>
  </select>
  <select id="lang" name="language">
    <option value="de">de</option>
    <option value="en">en</option>
  </select>
  <select name="country">
    <option value="de">Germany</option>
    <option value="en">en</option>
  </select>
  <select id="lang" name="language">
    <optgroup label="Europe">
      <option value="de">Germany</option>
      <option value="en">en</option>
    </optgroup>
  </select>
  <select name="country">
    <option class="europe" value="de">Germany</option>
    <option value="en">en</option>
  </select>

=head2 C<stylesheet>

  %= stylesheet '/foo.css'
  %= stylesheet begin
    body {color: #000}
  % end

Generate portable style or link tag for C<CSS> asset.

  <link href="/foo.css" media="screen" rel="stylesheet" type="text/css" />
  <style type="text/css"><![CDATA[
    body {color: #000}
  ]]></style>

=head2 C<submit_button>

  %= submit_button
  %= submit_button 'Ok!', id => 'foo'

Generate submit input element.

  <input type="submit" value="Ok" />
  <input id="foo" type="submit" value="Ok!" />

=head2 C<t>

  %=t div => 'some & content'

Alias for C<tag>.

  <div>some &amp; content</div>

=head2 C<tag>

  %= tag 'div'
  %= tag 'div', id => 'foo'
  %= tag div => 'some & content'
  <%= tag div => begin %>some & content<% end %>

HTML5 tag generator.

  <div />
  <div id="foo" />
  <div>some &amp; content</div>
  <div>some & content</div>

Very useful for reuse in more specific tag helpers.

  $self->tag('div');
  $self->tag('div', id => 'foo');
  $self->tag(div => sub { 'Content' });

Results are automatically wrapped in L<Mojo::ByteStream> objects to prevent
accidental double escaping.

=head2 C<text_field>

  %= text_field 'first_name'
  %= text_field first_name => 'Default name'
  %= text_field first_name => 'Default name', class => 'user'

Generate text input element. Previous input values will automatically get
picked up and shown as default.

  <input name="first_name" />
  <input name="first_name" value="Default name" />
  <input class="user" name="first_name" value="Default name" />

=head2 C<text_area>

  %= text_area 'foo'
  %= text_area foo => 'Default!', cols => 40
  %= text_area foo => begin
    Default!
  % end

Generate textarea element. Previous input values will automatically get
picked up and shown as default.

  <textarea name="foo"></textarea>
  <textarea cols="40" name="foo">Default!</textarea>
  <textarea name="foo">
    Default!
  </textarea>

=head1 METHODS

L<Mojolicious::Plugin::TagHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
