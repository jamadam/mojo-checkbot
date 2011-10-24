mojo-checkbot 0.13 beta
---------------

## SYNOPSIS
    
    mojo-checkbot daemon [--start start URL] [--match match string] [--sleep seconds] [--ua useragent header] [--cookie cookie string] [--timeout seconds]

## DESCRIPTION

ウェブサイトのリンクチェッカーです。コマンドラインで開始URLを指定してデーモンを起動し、
ブラウザでhttp://127.0.0.1:3000 を開くとチェック状況が逐一報告されます。
リンクの収集とステータスコードの収集は再帰的に延々続きますので、matchオプションでURLフィルタをかけておくと、
そのうち止まるかもしれません。

## OPTIONS

下記のオプションが利用可能です:

    クローラーオプション
    
    --start <URL>           クロールをスタートするURLを指定します。
    --match <regexp>        チェック対象のURLを正規表現で指定します。
    --sleep <seconds>       クロールの間隔を指定します。
    --ua <string>           クローラーのHTTPヘッダに設定するユーザーエージェントを指定します。
    --cookie <string>       クローラーがサーバーに送信するクッキーを指定します。
    --timeout <seconds>     クローラーのタイムアウトする秒数を指定します。デフォルトは15です。
    --resume                [EXPERIMENTAL]前回の結果を復元し、再開します。
    
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

    $ mojo-checkbot daemon --start http://example.com --match http://example.com/ --sleep 2
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### EXAMPLE2

本プログラムはMojoliciousをベースにしていますので、そちらのオプションも有効なはずです。

    $ mojo-checkbot daemon --listen http://*:3001 --start http://example.com

### EXAMPLE3

クッキーを指定して要認証サイトのチェックもできます。

    $ mojo-checkbot daemon --start http://example.com --cookie \
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