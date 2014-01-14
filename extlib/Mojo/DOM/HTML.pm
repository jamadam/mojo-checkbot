package Mojo::DOM::HTML;
use Mojo::Base -base;

use Mojo::Util qw(html_unescape xml_escape);
use Scalar::Util 'weaken';

has 'xml';
has tree => sub { ['root'] };

my $ATTR_RE = qr/
  ([^<>=\s]+)      # Key
  (?:
    \s*=\s*
    (?:
      "([^"]*?)"   # Quotation marks
    |
      '([^']*?)'   # Apostrophes
    |
      ([^>\s]*)    # Unquoted
    )
  )?
  \s*
/x;
my $END_RE   = qr!^\s*/\s*(.+)\s*!;
my $TOKEN_RE = qr/
  ([^<]+)?                                          # Text
  (?:
    <\?(.*?)\?>                                     # Processing Instruction
  |
    <!--(.*?)--\s*>                                 # Comment
  |
    <!\[CDATA\[(.*?)\]\]>                           # CDATA
  |
    <!DOCTYPE(
      \s+\w+
      (?:(?:\s+\w+)?(?:\s+(?:"[^"]*"|'[^']*'))+)?   # External ID
      (?:\s+\[.+?\])?                               # Int Subset
      \s*
    )>
  |
    <(
      \s*
      [^<>\s]+                                      # Tag
      \s*
      (?:$ATTR_RE)*                                 # Attributes
    )>
  |
    (<)                                             # Runaway "<"
  )??
/xis;

# HTML elements that break paragraphs
my @PARAGRAPH = (
  qw(address article aside blockquote dir div dl fieldset footer form h1 h2),
  qw(h3 h4 h5 h6 header hr main menu nav ol p pre section table ul)
);

# HTML elements with optional end tags
my %END = (
  body => ['head'],
  dd   => [qw(dt dd)],
  dt   => [qw(dt dd)],
  rp   => [qw(rt rp)],
  rt   => [qw(rt rp)]
);
$END{$_} = [$_]  for qw(optgroup option);
$END{$_} = ['p'] for @PARAGRAPH;

# HTML table elements with optional end tags
my %TABLE = map { $_ => 1 } qw(colgroup tbody td tfoot th thead tr);

# HTML elements without end tags
my %VOID = map { $_ => 1 } (
  qw(area base br col embed hr img input keygen link menuitem meta param),
  qw(source track wbr)
);

# HTML elements categorized as phrasing content (and obsolete inline elements)
my @PHRASING = (
  qw(a abbr area audio b bdi bdo br button canvas cite code data datalist),
  qw(del dfn em embed i iframe img input ins kbd keygen label link map mark),
  qw(math meta meter noscript object output progress q ruby s samp script),
  qw(select small span strong sub sup svg template textarea time u var video),
  qw(wbr)
);
my @OBSOLETE = qw(acronym applet basefont big font strike tt);
my %PHRASING = map { $_ => 1 } @OBSOLETE, @PHRASING;

sub parse {
  my ($self, $html) = @_;

  my $current = my $tree = ['root'];
  while ($html =~ m/\G$TOKEN_RE/gcs) {
    my ($text, $pi, $comment, $cdata, $doctype, $tag, $runaway)
      = ($1, $2, $3, $4, $5, $6, $11);

    # Text (and runaway "<")
    $text .= '<' if defined $runaway;
    push @$current, ['text', html_unescape $text] if defined $text;

    # Tag
    if (defined $tag) {

      # End
      my $xml = $self->xml;
      if ($tag =~ $END_RE) { _end($xml ? $1 : lc($1), $xml, \$current) }

      # Start
      elsif ($tag =~ m!([^\s/]+)([\s\S]*)!) {
        my ($start, $attr) = ($xml ? $1 : lc($1), $2);

        # Attributes
        my %attrs;
        while ($attr =~ /$ATTR_RE/g) {
          my ($key, $value) = ($xml ? $1 : lc($1), defined $2 ? $2 : defined $3 ? $3 : $4);

          # Empty tag
          next if $key eq '/';

          $attrs{$key} = defined $value ? html_unescape($value) : $value;
        }

        _start($start, \%attrs, $xml, \$current);

        # Element without end tag
        _end($start, $xml, \$current)
          if (!$xml && $VOID{$start}) || $attr =~ m!/\s*$!;

        # Relaxed "script" or "style"
        next unless $start eq 'script' || $start eq 'style';
        next unless $html =~ m!\G(.*?)<\s*/\s*$start\s*>!gcsi;
        push @$current, ['raw', $1];
        _end($start, $xml, \$current);
      }
    }

    # DOCTYPE
    elsif (defined $doctype) { push @$current, ['doctype', $doctype] }

    # Comment
    elsif (defined $comment) { push @$current, ['comment', $comment] }

    # CDATA
    elsif (defined $cdata) { push @$current, ['cdata', $cdata] }

    # Processing instruction (try to detect XML)
    elsif (defined $pi) {
      $self->xml(1) if !exists $self->{xml} && $pi =~ /xml/i;
      push @$current, ['pi', $pi];
    }
  }

  return $self->tree($tree);
}

sub render { _render($_[0]->tree, $_[0]->xml) }

sub _close {
  my ($xml, $current, $allowed, $scope) = @_;

  # Close allowed parent elements in scope
  my $parent = $$current;
  while ($parent->[0] ne 'root' && $parent->[1] ne $scope) {
    _end($parent->[1], $xml, $current) if $allowed->{$parent->[1]};
    $parent = $parent->[3];
  }
}

sub _end {
  my ($end, $xml, $current) = @_;

  # Search stack for start tag
  my $found = 0;
  my $next  = $$current;
  while ($next->[0] ne 'root') {

    # Right tag
    ++$found and last if $next->[1] eq $end;

    # Phrasing content can only cross phrasing content
    return if !$xml && $PHRASING{$end} && !$PHRASING{$next->[1]};

    $next = $next->[3];
  }

  # Ignore useless end tag
  return unless $found;

  # Walk backwards
  $next = $$current;
  while (($$current = $next) && $$current->[0] ne 'root') {
    $next = $$current->[3];

    # Match
    if ($end eq $$current->[1]) { return $$current = $$current->[3] }

    # Table
    elsif ($end eq 'table') { _close($xml, $current, \%TABLE, $end) }

    # Missing end tag
    _end($$current->[1], $xml, $current);
  }
}

sub _render {
  my ($tree, $xml) = @_;

  # Text (escaped)
  my $type = $tree->[0];
  return xml_escape $tree->[1] if $type eq 'text';

  # Raw text
  return $tree->[1] if $type eq 'raw';

  # DOCTYPE
  return '<!DOCTYPE' . $tree->[1] . '>' if $type eq 'doctype';

  # Comment
  return '<!--' . $tree->[1] . '-->' if $type eq 'comment';

  # CDATA
  return '<![CDATA[' . $tree->[1] . ']]>' if $type eq 'cdata';

  # Processing instruction
  return '<?' . $tree->[1] . '?>' if $type eq 'pi';

  # Start tag
  my $start   = 1;
  my $content = '';
  if ($type eq 'tag') {
    $start = 4;

    # Open tag
    my $tag = $tree->[1];
    $content .= "<$tag";

    # Attributes
    my @attrs;
    for my $key (sort keys %{$tree->[2]}) {
      my $value = $tree->[2]{$key};

      # No value
      push @attrs, $key and next unless defined $value;

      # Key and value
      push @attrs, qq{$key="} . xml_escape($value) . '"';
    }
    $content .= join ' ', '', @attrs if @attrs;

    # Element without end tag
    return $xml || $VOID{$tag} ? "$content />" : "$content></$tag>"
      unless $tree->[4];

    # Close tag
    $content .= '>';
  }

  # Render whole tree
  $content .= _render($tree->[$_], $xml) for $start .. $#$tree;

  # End tag
  $content .= '</' . $tree->[1] . '>' if $type eq 'tag';

  return $content;
}

sub _start {
  my ($start, $attrs, $xml, $current) = @_;

  # Autoclose optional HTML elements
  if (!$xml && $$current->[0] ne 'root') {
    if (my $end = $END{$start}) { _end($_, 0, $current) for @$end }

    # "li"
    elsif ($start eq 'li') { _close(0, $current, {li => 1}, 'ul') }

    # "colgroup", "thead", "tbody" and "tfoot"
    elsif (grep { $_ eq $start } qw(colgroup thead tbody tfoot)) {
      _close(0, $current, \%TABLE, 'table');
    }

    # "tr"
    elsif ($start eq 'tr') { _close(0, $current, {tr => 1}, 'table') }

    # "th" and "td"
    elsif ($start eq 'th' || $start eq 'td') {
      _close(0, $current, {$_ => 1}, 'table') for qw(th td);
    }
  }

  # New tag
  my $new = ['tag', $start, $attrs, $$current];
  weaken $new->[3];
  push @$$current, $new;
  $$current = $new;
}

1;

=encoding utf8

=head1 NAME

Mojo::DOM::HTML - HTML/XML engine

=head1 SYNOPSIS

  use Mojo::DOM::HTML;

  # Turn HTML into DOM tree
  my $html = Mojo::DOM::HTML->new;
  $html->parse('<div><p id="a">A</p><p id="b">B</p></div>');
  my $tree = $html->tree;

=head1 DESCRIPTION

L<Mojo::DOM::HTML> is the HTML/XML engine used by L<Mojo::DOM>.

=head1 ATTRIBUTES

L<Mojo::DOM::HTML> implements the following attributes.

=head2 tree

  my $tree = $html->tree;
  $html    = $html->tree(['root', ['text', 'foo']]);

Document Object Model. Note that this structure should only be used very
carefully since it is very dynamic.

=head2 xml

  my $bool = $html->xml;
  $html    = $html->xml($bool);

Disable HTML semantics in parser and activate case sensitivity, defaults to
auto detection based on processing instructions.

=head1 METHODS

L<Mojo::DOM::HTML> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 parse

  $html = $html->parse('<foo bar="baz">test</foo>');

Parse HTML/XML fragment.

=head2 render

  my $xml = $html->render;

Render DOM to XML.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
