package Mojo::Content::MultiPart;
use Mojo::Base 'Mojo::Content';

use Mojo::Util 'b64_encode';

has parts => sub { [] };

sub body_contains {
  my ($self, $chunk) = @_;
  for my $part (@{$self->parts}) {
    return 1 if index($part->build_headers, $chunk) >= 0;
    return 1 if $part->body_contains($chunk);
  }
  return;
}

sub body_size {
  my $self = shift;

  # Check for Content-Lenght header
  my $content_length = $self->headers->content_length;
  return $content_length if $content_length;

  # Calculate length of whole body
  my $boundary_length = length($self->build_boundary) + 6;
  my $len             = 0;
  $len += $boundary_length - 2;
  for my $part (@{$self->parts}) {

    # Header
    $len += $part->header_size;

    # Body
    $len += $part->body_size;

    # Boundary
    $len += $boundary_length;
  }

  return $len;
}

sub build_boundary {
  my $self = shift;

  # Check for existing boundary
  my $headers = $self->headers;
  my $type = $headers->content_type || '';
  my $boundary;
  $type =~ /boundary=\"?([^\s\"]+)\"?/i and $boundary = $1;
  return $boundary if $boundary;

  # Generate and check boundary
  my $size = 1;
  while (1) {

    # Mostly taken from LWP
    $boundary = join('', map chr(rand(256)), 1 .. $size * 3);
    b64_encode $boundary;
    $boundary =~ s/\W/X/g;

    # Check parts for boundary
    last unless $self->body_contains($boundary);
    $size++;
  }

  # Add boundary to Content-Type header
  $type =~ /^(.*multipart\/[^;]+)(.*)$/;
  my $before = $1 || 'multipart/mixed';
  my $after  = $2 || '';
  $headers->content_type("$before; boundary=$boundary$after");

  return $boundary;
}

sub clone {
  my $self = shift;
  return unless my $clone = $self->SUPER::clone();
  $clone->parts($self->parts);
  return $clone;
}

sub get_body_chunk {
  my ($self, $offset) = @_;

  # Body generator
  return $self->generate_body_chunk($offset) if $self->{dynamic};

  # First boundary
  my $boundary        = $self->build_boundary;
  my $boundary_length = length($boundary) + 6;
  my $len             = $boundary_length - 2;
  return substr "--$boundary\x0d\x0a", $offset if $len > $offset;

  # Parts
  my $parts = $self->parts;
  for (my $i = 0; $i < @$parts; $i++) {
    my $part = $parts->[$i];

    # Headers
    my $header_length = $part->header_size;
    return $part->get_header_chunk($offset - $len)
      if ($len + $header_length) > $offset;
    $len += $header_length;

    # Content
    my $content_length = $part->body_size;
    return $part->get_body_chunk($offset - $len)
      if ($len + $content_length) > $offset;
    $len += $content_length;

    # Boundary
    if (($len + $boundary_length) > $offset) {

      # Last boundary
      return substr "\x0d\x0a--$boundary--", $offset - $len
        if $#{$parts} == $i;

      # Middle boundary
      return substr "\x0d\x0a--$boundary\x0d\x0a", $offset - $len;
    }
    $len += $boundary_length;
  }
}

sub is_multipart {1}

sub parse {
  my $self = shift;

  # Parse headers and chunked body
  $self->SUPER::parse(@_);

  # Custom body parser
  return $self if $self->has_subscribers('read');

  # Parse multipart content
  $self->_parse_multipart;

  return $self;
}

sub _parse_multipart {
  my $self = shift;

  # Parse
  $self->{multi_state} ||= 'multipart_preamble';
  my $boundary = $self->boundary;
  while (!$self->is_done) {

    # Preamble
    if (($self->{multi_state} || '') eq 'multipart_preamble') {
      last unless $self->_parse_multipart_preamble($boundary);
    }

    # Boundary
    elsif (($self->{multi_state} || '') eq 'multipart_boundary') {
      last unless $self->_parse_multipart_boundary($boundary);
    }

    # Body
    elsif (($self->{multi_state} || '') eq 'multipart_body') {
      last unless $self->_parse_multipart_body($boundary);
    }
  }
}

sub _parse_multipart_body {
  my ($self, $boundary) = @_;

  # Whole part in buffer
  my $pos = index $self->{buffer}, "\x0d\x0a--$boundary";
  if ($pos < 0) {
    my $len = length($self->{buffer}) - (length($boundary) + 8);
    return unless $len > 0;

    # Store chunk
    my $chunk = substr $self->{buffer}, 0, $len, '';
    $self->parts->[-1] = $self->parts->[-1]->parse($chunk);
    return;
  }

  # Store chunk
  my $chunk = substr $self->{buffer}, 0, $pos, '';
  $self->parts->[-1] = $self->parts->[-1]->parse($chunk);
  $self->{multi_state} = 'multipart_boundary';
  return 1;
}

sub _parse_multipart_boundary {
  my ($self, $boundary) = @_;

  # Boundary begins
  if ((index $self->{buffer}, "\x0d\x0a--$boundary\x0d\x0a") == 0) {
    substr $self->{buffer}, 0, length($boundary) + 6, '';

    # New part
    push @{$self->parts}, Mojo::Content::Single->new(relaxed => 1);
    $self->{multi_state} = 'multipart_body';
    return 1;
  }

  # Boundary ends
  my $end = "\x0d\x0a--$boundary--";
  if ((index $self->{buffer}, $end) == 0) {
    substr $self->{buffer}, 0, length $end, '';

    # Done
    $self->{state} = $self->{multi_state} = 'done';
  }

  return;
}

sub _parse_multipart_preamble {
  my ($self, $boundary) = @_;

  # Replace preamble with carriage return and line feed
  my $pos = index $self->{buffer}, "--$boundary";
  unless ($pos < 0) {
    substr $self->{buffer}, 0, $pos, "\x0d\x0a";

    # Parse boundary
    $self->{multi_state} = 'multipart_boundary';
    return 1;
  }

  # No boundary yet
  return;
}

1;
__END__

=head1 NAME

Mojo::Content::MultiPart - HTTP 1.1 multipart content container

=head1 SYNOPSIS

  use Mojo::Content::MultiPart;

  my $content = Mojo::Content::MultiPart->new;
  $content->parse('Content-Type: multipart/mixed; boundary=---foobar');
  my $part = $content->parts->[4];

=head1 DESCRIPTION

L<Mojo::Content::MultiPart> is a container for HTTP 1.1 multipart content as
described in RFC 2616.

=head1 EVENTS

L<Mojo::Content::Multipart> inherits all events from L<Mojo::Content>.

=head1 ATTRIBUTES

L<Mojo::Content::MultiPart> inherits all attributes from L<Mojo::Content>
and implements the following new ones.

=head2 C<parts>

  my $parts = $content->parts;

Content parts embedded in this multipart content, usually
L<Mojo::Content::Single> objects.

=head1 METHODS

L<Mojo::Content::MultiPart> inherits all methods from L<Mojo::Content> and
implements the following new ones.

=head2 C<body_contains>

  my $success = $content->body_contains('foobarbaz');

Check if content parts contain a specific string.

=head2 C<body_size>

  my $size = $content->body_size;

Content size in bytes.

=head2 C<build_boundary>

  my $boundary = $content->build_boundary;

Generate a suitable boundary for content.

=head2 C<clone>

  my $clone = $content->clone;

Clone content if possible.
Note that this method is EXPERIMENTAL and might change without warning!

=head2 C<get_body_chunk>

  my $chunk = $content->get_body_chunk(0);

Get a chunk of content starting from a specfic position.

=head2 C<is_multipart>

  my $true = $content->is_multipart;

True.

=head2 C<parse>

  $content = $content->parse('Content-Type: multipart/mixed');

Parse content chunk.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
