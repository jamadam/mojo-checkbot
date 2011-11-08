package Mojo::Content::Single;
use Mojo::Base 'Mojo::Content';

use Mojo::Asset::Memory;
use Mojo::Content::MultiPart;

has asset => sub { Mojo::Asset::Memory->new };
has auto_upgrade => 1;

sub body_contains {
  return 1 if shift->asset->contains(shift) >= 0;
  return;
}

sub body_size {
  my $self = shift;
  return ($self->headers->content_length || 0) if $self->{dynamic};
  return $self->asset->size;
}

sub clone {
  my $self = shift;
  return unless my $clone = $self->SUPER::clone();
  $clone->asset($self->asset);
  return $clone;
}

sub get_body_chunk {
  my ($self, $offset) = @_;

  # Body generator
  return $self->generate_body_chunk($offset) if $self->{dynamic};

  # Normal content
  return $self->asset->get_chunk($offset);
}

sub parse {
  my $self = shift;

  # Parse headers and chunked body
  $self->SUPER::parse(@_);

  # Still parsing headers or using a custom body parser
  return $self
    if ($self->{state} || '') eq 'headers' || $self->has_subscribers('read');

  # Content needs to be upgraded to multipart
  if ($self->auto_upgrade && defined($self->boundary)) {
    $self->emit(upgrade => my $multi = Mojo::Content::MultiPart->new($self));
    return $multi->parse;
  }

  # Chunked body or relaxed content
  my $asset = $self->asset;
  if ($self->is_chunked || $self->relaxed) {
    $self->asset($asset->add_chunk($self->{buffer}));
    $self->{buffer} = '';
  }

  # Normal body
  else {
    my $len = $self->headers->content_length || 0;
    my $need = $len - $asset->size;
    $self->asset($asset->add_chunk(substr $self->{buffer}, 0, $need, ''))
      if $need > 0;

    # Finished
    $self->{state} = 'finished' if $len <= $self->progress;
  }

  return $self;
}

1;
__END__

=head1 NAME

Mojo::Content::Single - HTTP 1.1 content container

=head1 SYNOPSIS

  use Mojo::Content::Single;

  my $single = Mojo::Content::Single->new;
  $single->parse("Content-Length: 12\r\n\r\nHello World!");

=head1 DESCRIPTION

L<Mojo::Content::Single> is a container for HTTP 1.1 content as described in
RFC 2616.

=head1 EVENTS

L<Mojo::Content::Single> inherits all events from L<Mojo::Content> and can
emit the following new ones.

=head2 C<upgrade>

  $single->on(upgrade => sub {
    my ($single, $multi) = @_;
  });

Emitted when content gets upgraded to a L<Mojo::Content::MultiPart> object.
Note that this event is EXPERIMENTAL and might change without warning!

  $single->on(upgrade => sub {
    my ($single, $multi) = @_;
    return unless $multi->headers->content_type =~ /multipart\/([^;]+)/i;
    say "Multipart: $1";
  });

=head1 ATTRIBUTES

L<Mojo::Content::Single> inherits all attributes from L<Mojo::Content> and
implements the following new ones.

=head2 C<asset>

  my $asset = $single->asset;
  $single   = $single->asset(Mojo::Asset::Memory->new);

The actual content, defaults to a L<Mojo::Asset::Memory> object.

=head2 C<auto_upgrade>

  my $upgrade = $single->auto_upgrade;
  $single     = $single->auto_upgrade(0);

Try to detect multipart content and automatically upgrade to a
L<Mojo::Content::MultiPart> object, defaults to C<1>.
Note that this attribute is EXPERIMENTAL and might change without warning!

=head1 METHODS

L<Mojo::Content::Single> inherits all methods from L<Mojo::Content> and
implements the following new ones.

=head2 C<body_contains>

  my $success = $single->body_contains('1234567');

Check if content contains a specific string.

=head2 C<body_size>

  my $size = $single->body_size;

Content size in bytes.

=head2 C<clone>

  my $clone = $single->clone;

Clone content if possible.
Note that this method is EXPERIMENTAL and might change without warning!

=head2 C<get_body_chunk>

  my $chunk = $single->get_body_chunk(0);

Get a chunk of content starting from a specfic position.

=head2 C<parse>

  $single   = $single->parse("Content-Length: 12\r\n\r\nHello World!");
  my $multi = $single->parse("Content-Type: multipart/form-data\r\n\r\n");

Parse content chunk and upgrade to L<Mojo::Content::MultiPart> object if
possible.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
