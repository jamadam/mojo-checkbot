mojo-checkbot 0.06 beta
---------------

## SYNOPSIS
    
    mojo-checkbot daemon [--start start URL] [--match match string] [--sleep seconds] [--ua useragent header] [--cookie cookie string]

## DESCRIPTION

ウェブサイトのリンクチェッカーです。コマンドラインでデーモンを起動して、ブラウザでhttp://127.0.0.1:3000 を
開くとチェック状況が逐一報告されます。
開始URLを指定してデーモンを起動するとHTMLページ内のリンク先に次々とアクセスし、ステータスコードを記録していきます。
リンクの収集とステータスコードの収集は再帰的に延々続きますので、matchオプションでURLフィルタをかけておくと、
そのうち止まるかもしれません。

### EXAMPLE1

    $ mojo-checkbot daemon --start http://example.com --match http://example.com/ --sleep 2
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### EXAMPLE2

本プログラムはMojolicious::Liteをベースにしていますので、そちらのオプションも有効なはずです。

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