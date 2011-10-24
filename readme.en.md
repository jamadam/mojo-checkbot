mojo-checkbot 0.12 beta
---------------

## SYNOPSIS
    
    mojo-checkbot daemon [--start start URL] [--match match string] [--sleep seconds] [--ua useragent header] [--cookie cookie string] [--timeout seconds]

## DESCRIPTION

mojo-checkbot is a Link checker for website. Once you start the daemon with
a URL option, the crawler automatically collects the status codes for links and
makes the report view available at http://127.0.0.1:3000. The report will
automatically be updated until the jobs queue is empty.

## OPTIONS

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

### EXAMPLE1

    $ mojo-checkbot daemon --start http://example.com --match http://example.com/ --sleep 2
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### EXAMPLE2

Since this program is based on Mojolicious::Lite, the options provided by it is
also available.

    $ mojo-checkbot daemon --listen http://*:3001 --start http://example.com

### EXAMPLE3

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