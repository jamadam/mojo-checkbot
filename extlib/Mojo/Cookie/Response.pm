package Mojo::Cookie::Response;
use Mojo::Base 'Mojo::Cookie';

use Mojo::Date;
use Mojo::Util 'quote';

has [qw/comment domain httponly max_age port secure/];

my $FIELD_RE =
  qr/(Comment|Domain|expires|HttpOnly|Max-Age|Path|Port|Secure|Version)/msi;

sub expires {
  my ($self, $expires) = @_;

  # New expires value
  if (defined $expires) {
    $self->{expires} = $expires;
    return $self;
  }

  # Upgrade
  return unless defined $self->{expires};
  $self->{expires} = Mojo::Date->new($self->{expires})
    unless ref $self->{expires};

  return $self->{expires};
}

# "Remember the time he ate my goldfish?
#  And you lied and said I never had goldfish.
#  Then why did I have the bowl Bart? Why did I have the bowl?"
sub parse {
  my ($self, $string) = @_;

  # Walk tree
  my @cookies;
  for my $knot ($self->_tokenize($string)) {
    for my $i (0 .. $#{$knot}) {
      my ($name, $value) = @{$knot->[$i]};

      # This will only run once
      if (not $i) {
        push @cookies, Mojo::Cookie::Response->new;
        $cookies[-1]->name($name);
        $cookies[-1]->value($value //= '');
        next;
      }

      # Field
      if (my @match = $name =~ $FIELD_RE) {

        # Underscore
        (my $id = lc $match[0]) =~ tr/-/_/;

        # Flag
        $cookies[-1]->$id($id =~ /(?:Secure|HttpOnly)/i ? 1 : $value);
      }
    }
  }

  return \@cookies;
}

sub to_string {
  my $self = shift;

  # Version
  return '' unless $self->name;
  my $cookie = $self->name;
  my $value  = $self->value;
  if (defined $value) {
    $cookie .= '=' . ($value =~ /[,;"]/ ? quote($value) : $value);
  }
  else { $cookie .= '=' }
  $cookie .= sprintf "; Version=%d", ($self->version || 1);

  # Domain
  if (my $domain = $self->domain) { $cookie .= "; Domain=$domain" }

  # Path
  if (my $path = $self->path) { $cookie .= "; Path=$path" }

  # Max-Age
  if (defined(my $m = $self->max_age)) { $cookie .= "; Max-Age=$m" }

  # Expires
  if (defined(my $e = $self->expires)) { $cookie .= "; expires=$e" }

  # Port
  if (my $port = $self->port) { $cookie .= qq/; Port="$port"/ }

  # Secure
  if (my $secure = $self->secure) { $cookie .= "; Secure" }

  # HttpOnly
  if (my $httponly = $self->httponly) { $cookie .= "; HttpOnly" }

  # Comment
  if (my $comment = $self->comment) { $cookie .= "; Comment=$comment" }

  return $cookie;
}

1;
__END__

=head1 NAME

Mojo::Cookie::Response - HTTP 1.1 response cookie container

=head1 SYNOPSIS

  use Mojo::Cookie::Response;

  my $cookie = Mojo::Cookie::Response->new;
  $cookie->name('foo');
  $cookie->value('bar');
  say $cookie;

=head1 DESCRIPTION

L<Mojo::Cookie::Response> is a container for HTTP 1.1 response cookies.

=head1 ATTRIBUTES

L<Mojo::Cookie::Response> inherits all attributes from L<Mojo::Cookie> and
implements the followign new ones.

=head2 C<comment>

  my $comment = $cookie->comment;
  $cookie     = $cookie->comment('test 123');

Cookie comment.

=head2 C<domain>

  my $domain = $cookie->domain;
  $cookie    = $cookie->domain('localhost');

Cookie domain.

=head2 C<httponly>

  my $httponly = $cookie->httponly;
  $cookie      = $cookie->httponly(1);

HTTP only flag.

=head2 C<max_age>

  my $max_age = $cookie->max_age;
  $cookie     = $cookie->max_age(60);

Max age for cookie in seconds.

=head2 C<port>

  my $port = $cookie->port;
  $cookie  = $cookie->port('80 8080');

Cookie port.

=head2 C<secure>

  my $secure = $cookie->secure;
  $cookie    = $cookie->secure(1);

Secure flag.

=head1 METHODS

L<Mojo::Cookie::Response> inherits all methods from L<Mojo::Cookie> and
implements the following new ones.

=head2 C<expires>

  my $expires = $cookie->expires;
  $cookie     = $cookie->expires(time + 60);

Expiration for cookie in seconds.

=head2 C<parse>

  my $cookies = $cookie->parse('f=b; Version=1; Path=/');

Parse cookies.

=head2 C<to_string>

  my $string = $cookie->to_string;

Render cookie.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
