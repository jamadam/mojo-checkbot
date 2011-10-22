package Mojolicious::Command::daemon;
use Mojo::Base 'Mojo::Command';

use Getopt::Long 'GetOptions';
use Mojo::Server::Daemon;

my %description;
$description{'ja_JP.UTF-8'}= <<"EOF";
mojo-checkbot���J�n���܂��B
EOF

if ($description{$ENV{LANG}}) {
  has description => $description{$ENV{LANG}};
} else {
  has description => <<'EOF';
Start mojo-checkbot.
EOF
}

my %usage;
$usage{'ja_JP.UTF-8'}= <<"EOF";
hoge usage: $0 daemon [OPTIONS]

���L�̃I�v�V���������p�\�ł�:
  
  �N���[���[�I�v�V����
  
  --start <URL>           �N���[�����X�^�[�g����URL���w�肵�܂��B
  --match <regexp>        �`�F�b�N�Ώۂ�URL�𐳋K�\���Ŏw�肵�܂��B
  --sleep <seconds>       �N���[���̊Ԋu���w�肵�܂��B
  --ua <string>           �N���[���[��HTTP�w�b�_�ɐݒ肷�郆�[�U�[�G�[�W�F���g���w�肵�܂��B
  --cookie <string>       �N���[���[���T�[�o�[�ɑ��M����N�b�L�[���w�肵�܂��B
  --timeout <seconds>     �N���[���[�̃^�C���A�E�g����b�����w�肵�܂��B�f�t�H���g��15�ł��B
  
  ���|�[�g�T�[�o�[�I�v�V����
  
  --backlog <size>        Set listen backlog size, defaults to SOMAXCONN.
  --clients <number>      Set maximum number of concurrent clients, defaults
                          to 1000.
  --group <name>          Set group name for process.
  --keepalive <seconds>   Set keep-alive timeout, defaults to 15.
  --listen <location>     Set one or more locations you want to listen on,
                          defaults to "http://*:3000".
  --proxy                 Activate reverse proxy support, defaults to the
                          value of MOJO_REVERSE_PROXY.
  --requests <number>     Set maximum number of requests per keep-alive
                          connection, defaults to 25.
  --user <name>           Set username for process.
  --websocket <seconds>   Set WebSocket timeout, defaults to 300.
EOF

if ($usage{$ENV{LANG}}) {
  has usage => $usage{$ENV{LANG}};
} else {
  has usage => <<"EOF";
hoge usage: $0 daemon [OPTIONS]

These options are available:
  
  Crawler options
  
  --start <URL>           Set start URL for crawling.
  --match <regexp>        Set regexp to judge whether or not the URL should be
                          checked.
  --sleep <seconds>       Set interval for crawling.
  --ua <string>           Set user agent name for crawler header
  --cookie <string>       Set cookie string sent to servers
  --timeout <seconds>     Set keep-alive timeout for crawler, defaults to 15.
  
  Report server options
  
  --backlog <size>        Set listen backlog size, defaults to SOMAXCONN.
  --clients <number>      Set maximum number of concurrent clients, defaults
                          to 1000.
  --group <name>          Set group name for process.
  --keepalive <seconds>   Set keep-alive timeout, defaults to 15.
  --listen <location>     Set one or more locations you want to listen on,
                          defaults to "http://*:3000".
  --proxy                 Activate reverse proxy support, defaults to the
                          value of MOJO_REVERSE_PROXY.
  --requests <number>     Set maximum number of requests per keep-alive
                          connection, defaults to 25.
  --user <name>           Set username for process.
  --websocket <seconds>   Set WebSocket timeout, defaults to 300.
EOF
}

# "It's an albino humping worm!
#  Why do they call it that?
#  Cause it has no pigment."
sub run {
  my $self   = shift;
  my $daemon = Mojo::Server::Daemon->new;

  # Options
  local @ARGV = @_;
  my @listen;
  GetOptions(
    'backlog=i'   => sub { $daemon->backlog($_[1]) },
    'clients=i'   => sub { $daemon->max_clients($_[1]) },
    'group=s'     => sub { $daemon->group($_[1]) },
    'keepalive=i' => sub { $daemon->keep_alive_timeout($_[1]) },
    'listen=s'    => \@listen,
    'proxy' => sub { $ENV{MOJO_REVERSE_PROXY} = 1 },
    'requests=i'  => sub { $daemon->max_requests($_[1]) },
    'user=s'      => sub { $daemon->user($_[1]) },
    'websocket=i' => sub { $daemon->websocket_timeout($_[1]) }
  );

  # Start
  $daemon->listen(\@listen) if @listen;
  $daemon->run;
}

1;
__END__

=head1 NAME

Mojolicious::Command::daemon - Daemon command

=head1 SYNOPSIS

  use Mojolicious::Command::daemon;

  my $daemon = Mojolicious::Command::daemon->new;
  $daemon->run(@ARGV);

=head1 DESCRIPTION

L<Mojolicious::Command::daemon> is a command interface to
L<Mojo::Server::Daemon>.

=head1 ATTRIBUTES

L<Mojolicious::Command::daemon> inherits all attributes from L<Mojo::Command>
and implements the following new ones.

=head2 C<description>

  my $description = $daemon->description;
  $daemon         = $daemon->description('Foo!');

Short description of this command, used for the command list.

=head2 C<usage>

  my $usage = $daemon->usage;
  $daemon   = $daemon->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::daemon> inherits all methods from L<Mojo::Command>
and implements the following new ones.

=head2 C<run>

  $daemon->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
