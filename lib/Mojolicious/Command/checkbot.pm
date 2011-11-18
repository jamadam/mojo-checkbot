package Mojolicious::Command::checkbot;
use Mojo::Base 'Mojolicious::Commands';

use Getopt::Long 'GetOptions';
use Mojo::Server::Daemon;

my %description;
$description{'ja_JP'}= <<"EOF";
mojo-checkbotを開始します。
EOF

my $lang = $ENV{LANG} ? ($ENV{LANG} =~ qr{^([^\.]+)})[0] : '';

if ($description{$lang}) {
  has description => $description{$lang};
} else {
  has description => <<'EOF';
Start mojo-checkbot.
EOF
}

my %usage;
$usage{'ja_JP'}= <<"EOF";
hoge usage: $0 daemon [OPTIONS]

下記のオプションが利用可能です:
  
  クローラーオプション
  
  --start <URL>           クロールをスタートするURLを指定します。
  --match <regexp>        [Deprecated]チェック対象のURLを正規表現で指定します。
  --match-for-check <regexp> チェック対象のURLを正規表現で指定します。
  --match-for-crawl <regexp> 再帰的なクロールの対象のURLを正規表現で指定します。
  --depth <integer>       再帰的なクロール深度の上限を指定します。
  --sleep <seconds>       クロールの間隔を指定します。
  --ua <string>           クローラーのHTTPヘッダに設定するユーザーエージェントを指定します。
  --cookie <string>       クローラーがサーバーに送信するクッキーを指定します。
  --timeout <seconds>     クローラーのタイムアウトする秒数を指定します。デフォルトは15です。
  --evacuate <seconds>    [EXPERIMENTAL]レポートをテンポラリーファイルに出力する間隔を指定します。
  --noevacuate            [EXPERIMENTAL]resume用のファイル出力を無効化します。
  --resume                [EXPERIMENTAL]前回の結果を復元し、再開します。
  --html-validate         HTMLの構文エラーを検出します。XML::LibXMLが必要です。
  
  レポートサーバーオプション
  
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

if ($usage{$lang}) {
  has usage => $usage{$lang};
} else {
  has usage => <<"EOF";
hoge usage: $0 daemon [OPTIONS]

These options are available:
  
  Crawler options
  
  --start <URL>           Set start URL for crawling.
  --match <regexp>        [Deprecated]Set regexp to judge whether or not the URL
                          should be checked.
  --match-for-check <regexp> Set regexp to judge whether or not the URL should be
                          checked.
  --match-for-crawl <regexp> Set regexp to judge whether or not the URL should be
                          crawled recursivly.
  --depth <integer>       Set max depth for recursive crawling.
  --sleep <seconds>       Set interval for crawling.
  --ua <string>           Set user agent name for crawler header
  --cookie <string>       Set cookie string sent to servers
  --timeout <seconds>     Set keep-alive timeout for crawler, defaults to 15.
  --evacuate <seconds>    [EXPERIMENTAL]Set interval for temporary file output.
  --noevacuate            [EXPERIMENTAL]Disables file output for resuming.
  --resume                [EXPERIMENTAL]Resume previous jobs and continue it.
  --html-validate         Enable HTML validation. This requires XML::LibXML installed.
  
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
  $ENV{MOJO_APP} ||= 'MojoCheckbot';
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
    'proxy'       => sub { $ENV{MOJO_REVERSE_PROXY} = 1 },
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

Mojolicious::Command::checkbot - checkbot command

=head1 SYNOPSIS

  use Mojolicious::Command::checkbot;

  my $checkbot = Mojolicious::Command::checkbot->new;
  $checkbot->run(@ARGV);

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

=cut
