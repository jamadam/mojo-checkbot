package MojoCheckbot;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;
use Getopt::Long 'GetOptionsFromArray';
use Mojo::DOM;
use Mojo::URL;
use Mojo::UserAgent::CookieJar;
use Mojo::Cookie::Response;
use Mojo::Util qw{md5_sum xml_escape};
use Mojo::Base 'Mojolicious';
use Mojo::Parameters;
use Mojo::JSON;
use Encode;
use utf8;
use MojoCheckbot::FileCache;
use MojoCheckbot::IOLoop;
use MojoCheckbot::UserAgent;
use Clone::PP qw(clone);
our $VERSION = '0.37';
    
    our $QUEUE_KEY_CONTEXT       = 1;
    our $QUEUE_KEY_LITERAL_URI   = 2;
    our $QUEUE_KEY_RESOLVED_URI  = 3;
    our $QUEUE_KEY_REFERER       = 4;
    our $QUEUE_KEY_RES           = 5;
    our $QUEUE_KEY_ERROR         = 6;
    our $QUEUE_KEY_DIALOG        = 7;
    our $QUEUE_KEY_METHOD        = 8;
    our $QUEUE_KEY_PARAM         = 9;
    our $QUEUE_KEY_PARENT        = 10;
    our $QUEUE_KEY_DEPTH         = 11;
    our $QUEUE_KEY_HTML_ERROR    = 12;
    our $QUEUE_KEY_MIMETYPE      = 13;
    our $QUEUE_KEY_SIZE          = 14;
    
    my @QUEUE_KEYS = (
        $QUEUE_KEY_CONTEXT,
        $QUEUE_KEY_LITERAL_URI,
        $QUEUE_KEY_RESOLVED_URI,
        $QUEUE_KEY_REFERER,
        $QUEUE_KEY_RES,
        $QUEUE_KEY_ERROR,
        $QUEUE_KEY_DIALOG,
        $QUEUE_KEY_METHOD,
        $QUEUE_KEY_PARAM,
        $QUEUE_KEY_PARENT,
        $QUEUE_KEY_DEPTH,
        $QUEUE_KEY_HTML_ERROR,
        $QUEUE_KEY_MIMETYPE,
        $QUEUE_KEY_SIZE,
    );
    
    my %options = (
        sleep               => 1,
        ua                  =>
            "mojo-checkbot/$VERSION (+https://github.com/jamadam/mojo-checkbot)",
        timeout             => 15,
        evacuate            => 30,
        'validator-nu-url'  => 'http://html5.validator.nu/',
    );
    
    my $fix;
    my $xml_parser;
    my $ua = Mojo::UserAgent->new;
    my $json_parser = Mojo::JSON->new;

    ### ---
    ### generate id for regume file name
    ### ---
    sub cache_id {
        return md5_sum($json_parser->encode([
            $options{start},
            $options{match},
            $options{ua},
            $options{cookie},
            $options{timeout},
            $options{'match-for-check'},
            $options{'match-for-crawl'},
            $options{'not-match-for-check'},
            $options{'not-match-for-crawl'},
            $options{'depth'},
            $options{'html-validate'},
            $options{'validator-nu'},
            $options{'validator-nu-url'},
        ]));
    }
    
    ### ---
    ### generate hash key for detecting fixed URLs
    ### ---
    sub fix_key {
        my ($queue) = @_;
        my $context = $queue->{$QUEUE_KEY_CONTEXT};
        my $method  = $queue->{$QUEUE_KEY_METHOD} || '';
        my $url     =   $queue->{$QUEUE_KEY_RESOLVED_URI} ||
                        $queue->{$QUEUE_KEY_LITERAL_URI};
        if ($context eq '*FORM*') {
            my @names =
                sort {$a cmp $b}
                map {$_->{name}} @{$queue->{$QUEUE_KEY_DIALOG}->{names}};
            return md5_sum(join("\t", $method, $url, @names));
        } else {
            return md5_sum(join("\t", $method, $url));
        }
    }

    ### ---
    ### startup for Mojolicious app
    ### ---
    sub startup {
        my $self = shift;
        
        $self->app->secret(time());
        $self->plugin(Config => {file => $self->home->rel_file('myapp.conf')});
        
        $self->home->parse(File::Spec->catdir(dirname(__FILE__), 'MojoCheckbot'));
        $self->static->paths([$self->home->rel_dir('public')]);
        $self->renderer->paths([$self->home->rel_dir('templates')]);
        
        GetOptionsFromArray(\@ARGV, \%options,
            'match=s@',
            'match-for-check=s@',
            'match-for-crawl=s@',
            'not-match-for-check=s@',
            'not-match-for-crawl=s@',
            'start=s',
            'sleep=i',
            'ua=s',
            'cookie=s',
            'timeout=s',
            'resume',
            'noevacuate',
            'evacuate=i',
            'depth=i',
            'html-validate',
            'validator-nu',
            'validator-nu-url',
        );
        
        if ($options{'html-validate'}) {
            eval {
                require 'XML/LibXML.pm' ## no critic;
            };
            if (! $@) {
                $xml_parser = XML::LibXML->new();
                my $catalog = join '/',
                                        File::Spec->splitdir(dirname(__FILE__)),
                                        "MojoCheckbot/dtds/catalog.xml";
                $xml_parser->load_catalog($catalog);
            } else {
                $self->log->error('XML::LibXML is required to activate HTML validation');
                $options{'html-validate'} = undef;
            }
        }
        
        my $queues = [];
        my $dialog = [];
        my $result = [];
        
        my $cache = MojoCheckbot::FileCache->new(cache_id());
        
        if ($options{resume} && $cache->exists) {
            my $resume = $cache->slurp;
            $queues = $resume->{queues};
            $result = $resume->{result};
            $dialog = $resume->{dialog};
            for my $entry (@$queues, @$result) {
                $fix->{fix_key($entry)} = undef;
            }
        }
        
        $queues->[0] ||= {
            $QUEUE_KEY_REFERER      => 'N/A',
            $QUEUE_KEY_CONTEXT      => 'N/A',
            $QUEUE_KEY_LITERAL_URI  => $options{start},
            $QUEUE_KEY_DEPTH        => 1,
            $QUEUE_KEY_PARENT       => undef,
        };
        
        my $ua = MojoCheckbot::UserAgent->new->name($options{ua});
        $ua->inactivity_timeout($options{timeout});
        
        if ($options{cookie}) {
            my $cookies = Mojo::Cookie::Response->parse($options{cookie});
            $ua->cookie_jar(Mojo::UserAgent::CookieJar->new->add(@$cookies));
        }
        
        my $loop_id;
        $loop_id = MojoCheckbot::IOLoop->blocked_recurring($options{sleep} => sub {
            if (my $queue = shift @$queues) {
                my $res = eval {check($ua, $queue)};
                if ($@) {
                    $queue->{$QUEUE_KEY_ERROR} = $@;
                } else {
                    my $referer =   $queue->{$QUEUE_KEY_RESOLVED_URI} ||
                                    $queue->{$QUEUE_KEY_LITERAL_URI};
                    for (@{$res->{queue}}, @{$res->{dialog}}) {
                        $_->{$QUEUE_KEY_REFERER} = $referer;
                        $_->{$QUEUE_KEY_PARENT} = scalar @$result;
                        $_->{$QUEUE_KEY_DEPTH} = ($queue->{$QUEUE_KEY_DEPTH} || 0) + 1;
                    }
                    push(@$queues, @{$res->{queue}});
                    push(@$dialog, @{$res->{dialog}});
                }
                push(@$result, $queue);
            }
        });
        
        if (! $options{noevacuate}) {
            my $loop_id2;
            my $interval = $options{evacuate};
            $loop_id2 = MojoCheckbot::IOLoop->recurring($interval => sub {
                $cache->store({
                    queues  => $queues,
                    result  => $result,
                    dialog => $dialog,
                });
                if (! scalar @$queues) {
                    MojoCheckbot::IOLoop->remove($loop_id2);
                }
            });
        }
        
        my $r = $self->routes;
        $r->route('/diff')->to(cb => sub {
            my $c           = shift;
            my $offset      = $c->req->param('offset');
            my $offset_d    = $c->req->param('offset_d');
            my $last        = scalar @$result;
            my $last_d      = scalar @$dialog;
            if ($last - $offset > 100) {
                $last = $offset + 100;
            }
            if ($last_d - $offset_d > 100) {
                $last_d = $offset_d + 100;
            }
            my @diff    = @$result[$offset .. $last - 1];
            my @diff_d  = @$dialog[$offset_d .. $last_d - 1];
            $c->render(json => {
                queues  => scalar @$queues,
                fixed   => scalar @$result,
                result  => \@diff,
                dialog  => \@diff_d,
            });
        });
        $r->route('/html_validator')->to(cb => sub {
            my $c = shift;
            my $res = $ua->get($c->req->param('url'))->res;
            my $encode = guess_encoding($res) || 'utf-8';
            my $body    = Encode::decode($encode, $res->body);
            my $error = Encode::decode($encode, validate_html($body));
            $c->render(json => {result => xml_escape($error)});
        });
        $r->route('/auth')->to(cb => sub {
            my $c = shift;
            my $url = Mojo::URL->new($c->req->param('url'));
            my $un  = $c->req->param('username');
            my $pw  = $c->req->param('password');
            $ua->userinfo->{$url->scheme. '://'. $url->host} = "$un:$pw";
            push(@$queues, {
                $QUEUE_KEY_RESOLVED_URI => "$url"
            });
            $c->render(json => {result => 'success'});
        });
        $r->route('/form')->to(cb => sub {
            my $c = shift;
            my $url = Mojo::URL->new($c->req->param($QUEUE_KEY_RESOLVED_URI));
            my $queue = {};
            for my $key (@QUEUE_KEYS) {
                $queue->{$key} = $c->req->param('key_'. $key);
            }
            append_queues($queue->{$QUEUE_KEY_REFERER}, $queues, [$queue]);
            $c->render(json => {result => 'success'});
        });
        $r->route('/')->to(cb => sub {
            my $c = shift;
            $c->render('index');
        });
    }
    
    ### ---
    ### process check queue
    ### ---
    sub check {
        my ($ua, $queue) = @_;
        my $url =   $queue->{$QUEUE_KEY_RESOLVED_URI} ||
                    $queue->{$QUEUE_KEY_LITERAL_URI};
        my $method = $queue->{$QUEUE_KEY_METHOD};
        my $param = $queue->{$QUEUE_KEY_PARAM};
        my @new_queues;
        my @dialogs;
        my $html_error;
        my $auth;
        my $tx;
        if ($method && $method =~ /post/i) {
            my $body_data = Mojo::Parameters->new($param)->to_hash;
            $tx  = $ua->max_redirects(0)->post_form($url, $body_data);
        } else {
            my $url = Mojo::URL->new($url);
            if ($param) {
                $url->query->merge(Mojo::Parameters->new($param));
            }
            $tx  = $ua->max_redirects(0)->get($url);
        }
        my $res     = $tx->res;
        my $code    = $res->code;
        my $type    = $res->headers->content_type;
        my $base    = $tx->req->url->userinfo(undef);
        if (! $code) {
            die $tx->error || 'Unknown error';
        }
        if (my $location = $tx->res->headers->header('location')) {
            append_queues($base, \@new_queues, [{
                $QUEUE_KEY_CONTEXT      => '*Redirected by server configuration*',
                $QUEUE_KEY_LITERAL_URI  => $location,
            }]);
        }
        if ($code == 200 && _match_for_crawl($url)) {
            my $recursion = 0;
            if (! $options{'depth'}) {
                $recursion = 1;
            } elsif (($queue->{$QUEUE_KEY_DEPTH} || 0) < $options{'depth'}) {
                $recursion = 1;
            }
            if ($type && $type =~ qr{text/(html|xml)}) {
                my $encode = guess_encoding($res) || 'utf-8';
                my $body    = Encode::decode($encode, $res->body);
                my $dom     = Mojo::DOM->new($body);
                if (my $base_tag = $dom->at('base')) {
                    $base = Mojo::URL->new($base_tag->attr('href'));
                }
                if ($recursion) {
                    my @a       = collect_urls($dom);
                    my @q       = grep {! $_->{$QUEUE_KEY_DIALOG}} @a;
                    my @dialog  = grep {$_->{$QUEUE_KEY_DIALOG}} @a;
                    append_queues($base, \@new_queues, \@q);
                    append_queues($base, \@dialogs, \@dialog);
                }
                if ($options{'html-validate'}) {
                    $html_error = validate_html($body) ? 'ng' : 'ok';
                }
            } elsif ($type && $type =~ qr{text/(text|css)}) {
                if ($recursion) {
                    my $encode  = guess_encoding_css($res) || 'utf-8';
                    my $body    = Encode::decode($encode, $res->body);
                    my @urls    = collect_urls_from_css($body);
                    append_queues($base, \@new_queues, \@urls);
                }
            }
        } elsif ($code == 401) {
            my $dialog = clone($queue);
            $dialog->{$QUEUE_KEY_CONTEXT} = '*Authentication Required*';
            $dialog->{$QUEUE_KEY_LITERAL_URI} = $url;
            $dialog->{$QUEUE_KEY_DIALOG} = {
                'www-authenticate' =>
                        scalar $res->headers->header('www-authenticate'),
            };
            push(@dialogs, $dialog);
            $queue->{$QUEUE_KEY_DIALOG} = $dialog->{$QUEUE_KEY_DIALOG};
        }
        $queue->{$QUEUE_KEY_RES}        = $code;
        $queue->{$QUEUE_KEY_MIMETYPE}   = $type;
        $queue->{$QUEUE_KEY_SIZE}       = $res->body_size;
        if ($html_error) {
            $queue->{$QUEUE_KEY_HTML_ERROR} = $html_error;
        }
        return {
            queue   => \@new_queues,
            dialog  => \@dialogs,
        };
    }
    
    ### ---
    ### Match a URL for crawling
    ### ---
    sub _match_for_crawl {
        my ($url) = @_;
        if ($options{'match-for-crawl'}) {
            for my $regexp (@{$options{'match-for-crawl'}}) {
                if ($url !~ /$regexp/) {
                    return 0;
                }
            }
        }
        if ($options{'not-match-for-crawl'}) {
            for my $regexp (@{$options{'not-match-for-crawl'}}) {
                if ($url =~ /$regexp/) {
                    return 0;
                }
            }
        }
        return 1;
    }
    
    ### ---
    ### Match a URL for checking
    ### ---
    sub _match_for_check {
        my ($url) = @_;
        if ($options{'match-for-check'}) {
            for my $regexp (@{$options{'match-for-check'}}) {
                if ($url !~ /$regexp/) {
                    return 0;
                }
            }
        }
        if ($options{'not-match-for-check'}) {
            for my $regexp (@{$options{'not-match-for-check'}}) {
                if ($url =~ /$regexp/) {
                    return 0;
                }
            }
        }
        if ($options{'match'}) {
            for my $regexp (@{$options{'match'}}) {
                if ($url !~ /$regexp/) {
                    return 0;
                }
            }
        }
        return 1;
    }
    
    ### ---
    ### append queues to master queue array
    ### ---
    sub append_queues {
        my ($base, $append_to, $urls) = @_;
        for my $entry (@$urls) {
            if ($entry->{$QUEUE_KEY_LITERAL_URI} =~ qr{^(\w+):}) {
                if (! ( $1 ~~ [qw(http https ftp ws wss)])) {
                    next;
                }
            }
            my $rurl = resolve_href($base, $entry->{$QUEUE_KEY_LITERAL_URI});
            $rurl = "$rurl";
            if (! _match_for_check($rurl)) {
                next;
            }
            if ($entry->{$QUEUE_KEY_LITERAL_URI} ne $rurl) {
                $entry->{$QUEUE_KEY_RESOLVED_URI} = $rurl;
            }
            my $md5 = fix_key($entry);
            if (! exists $fix->{$md5}) {
                $fix->{$md5} = undef;
                push(@$append_to, $entry);
            }
        }
    }
    
    ### ---
    ### Analize dome
    ### ---
    sub _analize_dom {
        my $dom = shift;
        if (my $href = $dom->{href} || $dom->{src} ||
            $dom->{content} && ($dom->{content} =~ qr{URL=(.+)}i)[0]) {
            my $context =
                    $dom->content_xml
                    || $dom->{alt}
                    || $dom->{title}
                    || $dom->to_xml
                    || '';
            if (length($context) > 300) {
                $context = substr($context, 0, 300). '...';
            }
            return {
                $QUEUE_KEY_CONTEXT      => xml_escape($context),
                $QUEUE_KEY_LITERAL_URI  => $href,
            };
        }
    }
    
    ### ---
    ### Analize dom for forms
    ### ---
    sub _analize_form_dom {
        my $dom = shift;
        if (my $href = $dom->{action}) {
            my @names;
            $dom->find('[name]')->each(sub {
                my $dom = shift;
                my $a = {name => $dom->attr('name')};
                if (my $value = xml_escape($dom->attr('value') || $dom->text)) {
                    $a->{value} = $value;
                }
                push(@names, $a);
            });
            @names = do { my %h; grep { !$h{$_->{name}}++ } @names};
            return {
                $QUEUE_KEY_CONTEXT      => '*FORM*',
                $QUEUE_KEY_LITERAL_URI  => $href,
                $QUEUE_KEY_DIALOG       => {names => \@names},
                $QUEUE_KEY_METHOD       => lc ($dom->{method} || 'get'),
            };
        }
    }
    
    ### ---
    ### Collect URLs
    ### ---
    sub collect_urls {
        my ($dom) = @_;
        my @array;
        $dom->find('script, link, a, img, area, embed, frame, iframe, input,
                                        meta[http\-equiv=Refresh]')->each(sub {
            if (my $queue = _analize_dom(shift)) {
                push(@array, $queue);
            }
        });
        $dom->find('form')->each(sub {
            if (my $queue = _analize_form_dom(shift)) {
                push(@array, $queue);
            }
        });
        $dom->find('style')->each(sub {
            my $dom = shift;
            if (my $c = $dom->content_xml) {
                push(@array, collect_urls_from_css($c));
            }
        });
        return @array;
    }

    ### ---
    ### Collect URLs from CSS
    ### ---
    sub collect_urls_from_css {
        my $str = shift;
        $str =~ s{/\*.+?\*/}{}gs;
        my @urls = ($str =~ m{url\(['"]?(.+?)['"]?\)}g);
        return map {{
            $QUEUE_KEY_CONTEXT      => '',
            $QUEUE_KEY_LITERAL_URI  => $_,
        }} @urls;
    }
    
    ### ---
    ### Guess encoding for CSS
    ### ---
    sub guess_encoding_css {
        my $res     = shift;
        my $type    = $res->headers->content_type;
        my $charset = ($type =~ qr{; ?charset=([^;\$]+)})[0];
        if (! $charset) {
            $charset = ($res->body =~ qr{^\s*\@charset ['"](.+?)['"];}is)[0];
        }
        return $charset;
    }
    
    ### ---
    ### Guess encoding
    ### ---
    sub guess_encoding {
        my $res     = shift;
        my $type    = $res->headers->content_type;
        my $charset = ($type =~ qr{; ?charset=([^;\$]+)})[0];
        if (! $charset && (my $head = ($res->body =~ qr{<head>(.+)</head>}is)[0])) {
            my $dom = Mojo::DOM->new($head);
            $dom->find('meta[http\-equiv=Content-Type]')->each(sub{
                my $meta_dom = shift;
                $charset = ($meta_dom->{content} =~ qr{; ?charset=([^;\$]+)})[0];
            });
        }
        return $charset;
    }
    
    ### ---
    ### Resolve href
    ### ---
    sub resolve_href {
        my ($base, $href) = @_;
        if (! ref $base) {
            $base = Mojo::URL->new($base);
        }
        my $new = $base->clone;
        my $temp = Mojo::URL->new($href);
        
        $temp->fragment(undef);
        if ($temp->scheme) {
            return $temp;
        }
        $new->path($temp->path->to_string);
        $new->path->canonicalize;
        if ($temp->host) {
            $new->host($temp->host);
        }
        if ($temp->port) {
            $new->port($temp->port);
        }
        $new->query($temp->query);
        while ($new->path->parts->[0] && $new->path->parts->[0] =~ /^\./) {
            shift @{$new->path->parts};
        }
        return $new;
    }
    
    ### ---
    ### Validate HTML
    ### ---
    sub validate_html {
        my $html = shift;
        if (my $type = is_html5($html)) {
            if ($options{'validator-nu'}) {
                $html = Encode::encode('UTF-8', $html);
                my $tx = $ua->post($options{'validator-nu-url'}. '?out=json',
                            {'content-type' => "$type; charset=UTF-8"}, $html);
                my $msg = $json_parser->decode($tx->res->body);
                if (scalar @{$msg->{messages}} == 0) {
                    return undef;
                } else {
                    my $str;
                    for my $e (@{$msg->{messages}}) {
                        $str = sprintf(qq{%s: %s\n}, uc $e->{type}, $e->{message});
                        $str .= qq{From line $e->{lastLine},} if $e->{lastLine};
                        $str .= qq{ column $e->{firstColumn};} if $e->{firstColumn};
                        $str .= qq{ to line $e->{lastLine},} if $e->{lastLine};
                        $str .= qq{ column $e->{lastColumn}} if $e->{lastColumn};
                        $str .= "\n";
                    }
                    return Encode::encode('UTF-8', $str);
                }
            }
            return 'html5 validation is not available';
        } else {
            my $valid = eval {
                XML::LibXML->load_xml(string => shift)->validate();
            };
            return $valid ? undef : $@;
        }
    }
    
    sub is_html5 {
        my $html = shift;
        if ($html =~ qr{^<?xml\b}) {
            if ($html =~ qr{<!DOCTYPE html>}) {
                return 'application/xhtml+xml';
            }
        } elsif ($html =~ qr{^\s*<!DOCTYPE html>}) {
            return 'text/html';
        }
    }

1;

=head1 NAME

MojoCheckbot - mojo-checkbot

=head1 SYNOPSIS

=head1 DESCRIPTION

MojoCheckbot is a backend for mojo-checkbot, a command line tool.

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
