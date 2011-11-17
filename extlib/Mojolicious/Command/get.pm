package Mojolicious::Command::get;
use Mojo::Base 'Mojo::Command';

use Getopt::Long 'GetOptions';
use Mojo::DOM;
use Mojo::IOLoop;
use Mojo::Transaction::HTTP;
use Mojo::UserAgent;
use Mojo::Util qw/decode encode/;

has description => <<'EOF';
Perform HTTP 1.1 request.
EOF
has usage => <<"EOF";
usage: $0 get [OPTIONS] URL [SELECTOR] [COMMANDS]

  mojo get /
  mojo get mojolicio.us
  mojo get -v -r google.com
  mojo get --method POST --content 'trololo' mojolicio.us
  mojo get --header 'X-Bender: Bite my shiny metal ass!' mojolicio.us
  mojo get mojolicio.us 'head > title' text
  mojo get mojolicio.us .footer all
  mojo get mojolicio.us a attr href
  mojo get mojolicio.us '*' attr id
  mojo get mojolicio.us 'h1, h2, h3' 3 text

These options are available:
  --charset <charset>     Charset of HTML5/XML content, defaults to auto
                          detection or "UTF-8".
  --content <content>     Content to send with request.
  --header <name:value>   Additional HTTP header.
  --method <method>       HTTP method to use, defaults to "GET".
  --redirect              Follow up to 5 redirects.
  --verbose               Print verbose debug information to STDERR.
EOF

# "Objection.
#  In the absence of pants, defense's suspenders serve no purpose.
#  I'm going to allow them... for now."
sub run {
  my $self = shift;

  # Options
  local @ARGV = @_;
  my $method = 'GET';
  my @headers;
  my $content = '';
  my ($charset, $redirect, $verbose) = 0;
  GetOptions(
    'charset=s' => sub { $charset  = $_[1] },
    'content=s' => sub { $content  = $_[1] },
    'header=s'  => \@headers,
    'method=s'  => sub { $method   = $_[1] },
    redirect    => sub { $redirect = 1 },
    verbose     => sub { $verbose  = 1 }
  );

  # Headers
  my $headers = {};
  for my $header (@headers) {
    next unless $header =~ /^\s*([^\:]+)\s*:\s*([^\:]+)\s*$/;
    $headers->{$1} = $2;
  }

  # URL and selector
  my $url = shift @ARGV;
  die $self->usage unless $url;
  $url = decode 'UTF-8', $url;
  my $selector = shift @ARGV;

  # Fresh user agent
  my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
  $ua->log->level('fatal');
  $ua->max_redirects(5) if $redirect;

  # Absolute URL
  if ($url =~ m#^\w+://#) { $ua->detect_proxy }

  # Application
  else { $ua->app($ENV{MOJO_APP} || 'Mojo::HelloWorld') }

  # Start
  my $v;
  my $buffer = '';
  $ua->on(
    start => sub {
      my $tx = pop;

      # Prepare request information
      my $req       = $tx->req;
      my $startline = $req->build_start_line;
      my $headers   = $req->build_headers;

      # Verbose callback
      my $v  = $verbose;
      my $cb = sub {
        my $res = shift;

        # Wait for headers
        return unless $v && $res->headers->is_finished;

        # Request
        warn "$startline$headers";

        # Response
        my $version = $res->version;
        my $code    = $res->code;
        my $message = $res->message;
        warn "HTTP/$version $code $message\n",
          $res->headers->to_string, "\n\n";

        # Finished
        $v = 0;
      };

      # Progress
      $tx->res->on(progress => sub { $cb->(shift) });

      # Stream content
      $tx->res->body(
        sub {
          $cb->(my $res = shift);

          # Ignore intermediate content
          return if $redirect && $res->is_status_class(300);

          # Chunk
          $selector ? ($buffer .= pop) : print(pop);
        }
      );
    }
  );

  # Get
  my $tx = $ua->build_tx($method, $url, $headers, $content);
  STDOUT->autoflush(1);
  $tx = $ua->start($tx);

  # Error
  my ($message, $code) = $tx->error;
  $url = encode 'UTF-8', $url;
  warn qq/Problem loading URL "$url". ($message)\n/ if $message && !$code;

  # Select
  $charset //= $tx->res->content->charset;
  $self->_select($buffer, $charset, $selector) if $selector;
}

sub _say {
  return unless length(my $value = shift);
  say encode('UTF-8', $value);
}

sub _select {
  my ($self, $buffer, $charset, $selector) = @_;

  # Find
  my $dom     = Mojo::DOM->new->charset($charset)->parse($buffer);
  my $results = $dom->find($selector);

  # Commands
  my $finished = 0;
  while (defined(my $command = shift @ARGV)) {

    # Number
    if ($command =~ /^\d+$/) {
      return unless ($results = [$results->[$command]])->[0];
      next;
    }

    # Text
    elsif ($command eq 'text') { _say($_->text) for @$results }

    # All text
    elsif ($command eq 'all') { _say($_->all_text) for @$results }

    # Attribute
    elsif ($command eq 'attr') {
      next unless my $name = shift @ARGV;
      _say($_->attrs->{$name}) for @$results;
    }

    # Unknown
    else { die qq/Unknown command "$command".\n/ }
    $finished++;
  }

  # Render
  unless ($finished) { _say($_) for @$results }
}

1;
__END__

=head1 NAME

Mojolicious::Command::get - Get command

=head1 SYNOPSIS

  use Mojolicious::Command::get;

  my $get = Mojolicious::Command::get->new;
  $get->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::get> is a command interface to L<Mojo::UserAgent>.

=head1 ATTRIBUTES

L<Mojolicious::Command::get> inherits all attributes from L<Mojo::Command>
and implements the following new ones.

=head2 C<description>

  my $description = $get->description;
  $get            = $get->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $get->usage;
  $get      = $get->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::get> inherits all methods from L<Mojo::Command> and
implements the following new ones.

=head2 C<run>

  $get->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
