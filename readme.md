mojo-checkbot beta
---------------

## SYNOPSIS
    
    mojo checkbot [--start start URL] [--match-for-check match string]
        [--match-for-check match string]
        [--match-for-crawlmatch string]
        [--not-match-for-check match string]
        [--not-match-for-crawlmatch string]
        [--sleep seconds]
        [--ua useragent header] [--cookie cookie string] [--timeout seconds]
        [--evacuate second] [--noevacuate] [--resume]

## DESCRIPTION

ウェブサイトのリンクチェッカー兼HTMLバリデーターです。コマンドラインで開始URLを指定してデーモンを起動し、
ブラウザでhttp://127.0.0.1:3000 を開くとチェック状況が逐一報告されます。
リンクの収集とステータスコードの収集は再帰的に延々続きますので、match-for-check等オプションでURLフィルタをかけておくと、
そのうち止まるかもしれません。

Perl v5.10.1以上が必要です。もし古い場合は、アップグレードするか、perlbrewでググってください。

## INSTALLATION

下記の手順でインストールして実行します。

    curl http://get.mrqe.biz/ | sh
    git clone https://github.com/jamadam/mojo-checkbot.git
    cd ./mojo-checkbot
    perl ./Makefile.PL
    make
    make test
    make install
    mojo checkbot --start http://example.com

または、下記の手順でも実行可能です。

    git clone https://github.com/jamadam/mojo-checkbot.git
    ./mojo-checkbot/mojo checkbot --start http://example.com

## OPTIONS

下記のオプションが利用可能です:

    クローラーオプション
    
    --start <URL>           クロールをスタートするURLを指定します。
    --match-for-check <regexp> チェック対象のURLを正規表現で指定します。
    --match-for-crawl <regexp> 再帰的なクロールの対象のURLを正規表現で指定します。
    --not-match-for-check <regexp> チェック対象としないURLの正規表現を指定します。
    --not-match-for-crawl <regexp> 再帰的なクロールの対象としないURLを正規表現で指定します。
    --depth <integer>       再帰的なクロール深度の上限を指定します。
    --sleep <seconds>       クロールの間隔を指定します。
    --limit <number>        クロールするURL数の上限を指定します。
    --ua <string>           クローラーのHTTPヘッダに設定するユーザーエージェントを指定します。
    --cookie <string>       クローラーがサーバーに送信するクッキーを指定します。
    --timeout <seconds>     クローラーのタイムアウトする秒数を指定します。デフォルトは15です。
    --html-validate         HTMLの構文エラーを検出します。XML::LibXMLが必要です。
    --validator-nu          validator.nuのオンラインバリデーションを有効化します
    --validator-nu-url      validator.nuのURLを指定します。
    
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

### EXAMPLE1

    $ mojo checkbot --start http://example.com --match-for-check http://example.com/ --sleep 2
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### EXAMPLE2

本プログラムはMojoliciousをベースにしていますので、そちらのオプションも有効なはずです。

    $ mojo checkbot --listen http://*:3001 --start http://example.com

### EXAMPLE3

クッキーを指定して要認証サイトのチェックもできます。

    $ mojo checkbot --start http://example.com --cookie \
        'key=value; Version=1; Domain=example.com; Path=/; expires=Fri, \
        28 Oct 2011 15:26:47 GMT'

[https://github.com/jamadam/mojo-checkbot]
[https://github.com/jamadam/mojo-checkbot]:https://github.com/jamadam/mojo-checkbot

Copyright (c) 2011 [jamadam]
[jamadam]: http://blog2.jamadam.com/

Dual licensed under the MIT and GPL licenses:

- [http://www.opensource.org/licenses/mit-license.php]
- [http://www.gnu.org/licenses/gpl.html]
[http://www.opensource.org/licenses/mit-license.php]: http://www.opensource.org/licenses/mit-license.php
[http://www.gnu.org/licenses/gpl.html]:http://www.gnu.org/licenses/gpl.html