package MojoCheckbot;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;
use Getopt::Long 'GetOptionsFromArray';
use Mojo::DOM;
use Mojo::URL;
use Mojo::CookieJar;
use Mojo::Cookie::Response;
use Mojo::Util qw{md5_sum html_escape};
use Mojo::Base 'Mojolicious';
use Mojo::Parameters;
use Encode;
use utf8;
use MojoCheckbot::FileCache;
use MojoCheckbot::IOLoop;
use MojoCheckbot::UserAgent;
our $VERSION = '0.27';
    
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
    );
    
    my %options = (
        sleep       => 1,
        ua          =>
            "mojo-checkbot/$VERSION (+https://github.com/jamadam/mojo-checkbot)",
        timeout     => 15,
        evacuate    => 30,
    );
    
    my $fix;
    
    sub cache_id {
        my @keys = qw{start match ua cookie timeout};
        my $seed = join("\t", map {$options{$_} || ''} @keys);
        return md5_sum($seed);
    }
    
    sub fix_key {
        my ($queue) = @_;
        my $context = $queue->{$QUEUE_KEY_CONTEXT};
        my $method  = $queue->{$QUEUE_KEY_METHOD} || '';
        my $url     = $queue->{$QUEUE_KEY_RESOLVED_URI} || $queue->{$QUEUE_KEY_LITERAL_URI};
        if ($context eq '*FORM*') {
            my @names =
                sort {$a cmp $b}
                map {$_->{name}} @{$queue->{$QUEUE_KEY_DIALOG}->{names}};
            return md5_sum(join("\t", $method, $url, @names));
        } else {
            return md5_sum(join("\t", $method, $url));
        }
    }

    sub startup {
        my $self = shift;
        my $home2 = Mojo::Home->new($self->home);
        $self->app->secret(time());
        $self->home->parse(File::Spec->catdir(dirname(__FILE__), 'MojoCheckbot'));
        $self->static->root($self->home->rel_dir('public'));
        $self->renderer->root($self->home->rel_dir('templates'));
        
        GetOptionsFromArray(\@ARGV, \%options,
            'match=s' ,
            'match-for-check=s' ,
            'match-for-crawl=s' ,
            'start=s',
            'sleep=i',
            'ua=s',
            'cookie=s',
            'timeout=s',
            'resume',
            'noevacuate',
            'evacuate=i',
        );
        
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
            $QUEUE_KEY_RESOLVED_URI => $options{start},
            $QUEUE_KEY_REFERER      => 'N/A',
            $QUEUE_KEY_CONTEXT      => 'N/A',
            $QUEUE_KEY_LITERAL_URI  => 'N/A',
        };
        
        my $ua = MojoCheckbot::UserAgent->new->name($options{ua});
        $ua->keep_alive_timeout($options{timeout});
        
        if ($options{cookie}) {
            my $cookies = Mojo::Cookie::Response->parse($options{cookie});
            $ua->cookie_jar(Mojo::CookieJar->new->add(@$cookies));
        }
        
        my $loop_id;
        $loop_id = MojoCheckbot::IOLoop->blocked_recurring($options{sleep} => sub {
            if (my $queue = shift @$queues) {
                my $url =   $queue->{$QUEUE_KEY_RESOLVED_URI} ||
                            $queue->{$QUEUE_KEY_LITERAL_URI};
                my $res = eval {
                    check($url, $ua,
                        $queue->{$QUEUE_KEY_METHOD}, $queue->{$QUEUE_KEY_PARAM});
                };
                if ($@) {
                    $queue->{$QUEUE_KEY_ERROR} = $@;
                } else {
                    for (@{$res->{queue}}, @{$res->{dialog}}) {
                        $_->{$QUEUE_KEY_REFERER} = $url;
                        $_->{$QUEUE_KEY_PARENT} = scalar @$result;
                    }
                    push(@$queues, @{$res->{queue}});
                    if ($res->{code} == 401) {
                        %$queue = (%$queue, %{$res->{dialog}->[0]});
                    } else {
                        push(@$dialog, @{$res->{dialog}});
                    }
                    $queue->{$QUEUE_KEY_RES} = $res->{code};
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
                    MojoCheckbot::IOLoop->drop($loop_id2);
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
            $c->render_json({
                queues  => scalar @$queues,
                fixed   => scalar @$result,
                result  => \@diff,
                dialog  => \@diff_d,
            });
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
            $c->render_json({result => 'success'});
        });
        $r->route('/form')->to(cb => sub {
            my $c = shift;
            my $url = Mojo::URL->new($c->req->param($QUEUE_KEY_RESOLVED_URI));
            my $queue = {};
            for my $key (@QUEUE_KEYS) {
                $queue->{$key} = $c->req->param('key_'. $key);
            }
            append_queues($queue->{$QUEUE_KEY_REFERER}, $queues, [$queue]);
            $c->render_json({result => 'success'});
        });
        $r->route('/')->to(cb => sub {
            my $c = shift;
            $c->render('index');
        });
    }
    
    sub check {
        my ($url, $ua, $method, $param) = @_;
        my @new_queues;
        my @dialogs;
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
        my $base    = $tx->req->url;
        if (! $code) {
            my ($message) = $tx->error;
            die $message;
        }
        if (my $location = $tx->res->headers->header('location')) {
            append_queues($base, \@new_queues, [{
                $QUEUE_KEY_CONTEXT      => '*Redirected by server configuration*',
                $QUEUE_KEY_LITERAL_URI  => $location,
            }]);
        }
        if ($code == 200 &&
                (! $options{'match-for-crawl'} ||
                                     $url =~ /$options{'match-for-crawl'}/)) {
            my $type = $res->headers->content_type;
            if ($type && $type =~ qr{text/(html|xml)}) {
                my $encode = guess_encoding($res) || 'utf-8';
                my $body    = Encode::decode($encode, $res->body);
                my $dom     = Mojo::DOM->new($body);
                if (my $base_tag = $dom->at('base')) {
                    $base = Mojo::URL->new($base_tag->attrs('href'));
                }
                my @a       = collect_urls($dom);
                my @q       = grep {! $_->{$QUEUE_KEY_DIALOG}} @a;
                my @dialog  = grep {$_->{$QUEUE_KEY_DIALOG}} @a;
                append_queues($base, \@new_queues, \@q);
                append_queues($base, \@dialogs, \@dialog);
            } elsif ($type && $type =~ qr{text/(text|css)}) {
                my $base    = $tx->req->url;
                my $encode  = guess_encoding_css($res) || 'utf-8';
                my $body    = Encode::decode($encode, $res->body);
                my @urls    = collect_urls_from_css($body);
                append_queues($base, \@new_queues, \@urls);
            }
        } elsif ($code == 401) {
            push(@dialogs, {
                $QUEUE_KEY_LITERAL_URI  => $url,
                $QUEUE_KEY_DIALOG       => {
                    'www-authenticate' =>
                            scalar $res->headers->header('www-authenticate'),
                },
            });
        }
        return {
            code    => $code,
            queue   => \@new_queues,
            dialog  => \@dialogs,
        };
    }
    
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
            if ($options{match}) {
                if ($rurl !~ /$options{match}/) {
                    next;
                }
            }
            if ($options{'match-for-check'}) {
                if ($rurl !~ /$options{'match-for-check'}/) {
                    next;
                }
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
                $QUEUE_KEY_CONTEXT      => html_escape($context),
                $QUEUE_KEY_LITERAL_URI  => $href,
            };
        }
    }
    
    sub _analize_form_dom {
        my $dom = shift;
        if (my $href = $dom->{action}) {
            my @names;
            $dom->find('[name]')->each(sub {
                my $dom = shift;
                my $a = {name => $dom->attrs('name')};
                if (my $value = html_escape($dom->attrs('value') || $dom->text)) {
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

    sub collect_urls_from_css {
        my $str = shift;
        $str =~ s{/\*.+?\*/}{}gs;
        my @urls = ($str =~ m{url\(['"]?(.+?)['"]?\)}g);
        return map {{
            $QUEUE_KEY_CONTEXT      => '',
            $QUEUE_KEY_LITERAL_URI  => $_,
        }} @urls;
    }
    
    sub guess_encoding_css {
        my $res     = shift;
        my $type    = $res->headers->content_type;
        my $charset = ($type =~ qr{; ?charset=([^;\$]+)})[0];
        if (! $charset) {
            $charset = ($res->body =~ qr{^\s*\@charset ['"](.+?)['"];}is)[0];
        }
        return $charset;
    }
    
    sub guess_encoding {
        my $res     = shift;
        my $type    = $res->headers->content_type;
        my $charset = ($type =~ qr{; ?charset=([^;\$]+)})[0];
        if (! $charset) {
            my $head = ($res->body =~ qr{<head>(.+)</head>}is)[0];
            my $dom = Mojo::DOM->new($head);
            $dom->find('meta[http\-equiv=Content-Type]')->each(sub{
                my $meta_dom = shift;
                $charset = ($meta_dom->{content} =~ qr{; ?charset=([^;\$]+)})[0];
            });
        }
        return $charset;
    }
    
    sub resolve_href {
        my ($base, $href) = @_;
        if (! ref $base) {
            $base = Mojo::URL->new($base);
        }
        my $new = $base->clone;
        my $temp = Mojo::URL->new($href);
        
        $temp->fragment('');
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
