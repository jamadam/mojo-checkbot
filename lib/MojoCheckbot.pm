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
use Mojo::Util 'md5_sum';
use Mojo::Base 'Mojolicious';
use Encode;
use utf8;
use MojoCheckbot::FileCache;
use MojoCheckbot::IOLoop;
use MojoCheckbot::UserAgent;
our $VERSION = '0.23';
    
    my $QUEUE_KEY_CONTEXT       = 1;
    my $QUEUE_KEY_LITERAL_URI   = 2;
    my $QUEUE_KEY_RESOLVED_URI  = 3;
    my $QUEUE_KEY_REFERER       = 4;
    my $QUEUE_KEY_RES           = 5;
    my $QUEUE_KEY_ERROR         = 6;
    my $QUEUE_KEY_DIALOG        = 7;

    my %options = (
        sleep       => 1,
        ua          => "mojo-checkbot($VERSION)",
        timeout     => 15,
        evacuate    => 30,
    );
    
    my $fix;
    
    sub cache_id {
        my @keys = qw{start match ua cookie timeout};
        my $seed = join("\t", map {$options{$_} || ''} @keys);
        return md5_sum($seed);
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
        my $result = [];
        
        my $cache = MojoCheckbot::FileCache->new(cache_id());
        
        if ($options{resume} && $cache->exists) {
            my $resume = $cache->slurp;
            $queues = $resume->{queues};
            $result = $resume->{result};
            for my $entry (@$queues, @$result) {
                my $url =   $entry->{$QUEUE_KEY_RESOLVED_URI} ||
                            $entry->{$QUEUE_KEY_LITERAL_URI};
                $fix->{md5_sum($url)} = undef;
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
        $ua->interval($options{sleep});
        
        if ($options{cookie}) {
            my $cookies = Mojo::Cookie::Response->parse($options{cookie});
            $ua->cookie_jar(Mojo::CookieJar->new->add(@$cookies));
        }
        
        my $loop_id;
        $loop_id = MojoCheckbot::IOLoop->blocked_recurring(0 => sub {
            if (my $queue = shift @$queues) {
                my $url =   $queue->{$QUEUE_KEY_RESOLVED_URI} ||
                            $queue->{$QUEUE_KEY_LITERAL_URI};
                my ($res, $new_queues, $dialogs) = eval {
                    check($url, $ua, $options{sleep});
                };
                if ($@) {
                    $queue->{$QUEUE_KEY_ERROR} = $@;
                } else {
                    @$new_queues = map {
                        $_->{$QUEUE_KEY_REFERER} = $url;
                        $_;
                    } @$new_queues;
                    @$dialogs = map {
                        $_->{$QUEUE_KEY_REFERER} = $url;
                        $_;
                    } @$dialogs;
                    push(@$queues, @$new_queues);
                    push(@$result, @$dialogs);
                    if (ref $res) {
                        $queue->{$QUEUE_KEY_RES}    = $res->{code};
                        $queue->{$QUEUE_KEY_DIALOG} = $res->{dialog};
                    } else {
                        $queue->{$QUEUE_KEY_RES}    = $res;
                    }
                }
                push(@$result, $queue);
            }
        });
        
        if (! $options{noevacuate}) {
            my $loop_id2;
            my $interval = $options{evacuate};
            $loop_id2 = MojoCheckbot::IOLoop->recurring($interval => sub {
                $cache->store({queues  => $queues, result  => $result});
                if (! scalar @$queues) {
                    MojoCheckbot::IOLoop->drop($loop_id2);
                }
            });
        }
        
        my $r = $self->routes;
        $r->route('/diff')->to(cb => sub {
            my $c       = shift;
            my $offset  = $c->req->param('offset');
            my $last    = scalar @$result;
            if ($last - $offset > 100) {
                $last = $offset + 100;
            }
            my @diff = @$result[$offset .. $last - 1];
            $c->render_json({
                queues  => scalar @$queues,
                fixed   => scalar @$result,
                result  => \@diff
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
        $r->route('/')->to(cb => sub {
            my $c = shift;
            $c->render('index');
        });
    }
    
    sub check {
        my ($url, $ua, $interval) = @_;
        my $tx      = $ua->max_redirects(0)->head($url);
        my $code    = $tx->res->code;
        if (! $code) {
            my ($message) = $tx->error;
            die $message;
        }
        my @new_queues;
        my @dialogs;
        if (my $location = $tx->res->headers->header('location')) {
            push(@new_queues, {
                $QUEUE_KEY_CONTEXT      => '*Redirected by server configuration*',
                $QUEUE_KEY_LITERAL_URI  => $location,
            });
        }
        if ($code && $code == 200) {
            my $tx  = $ua->max_redirects(0)->get($url);
            my $res = $tx->res;
            $code   = $res->code;
            my $type = $res->headers->content_type;
            if (! $options{'match-for-crawl'} ||
                                        $url =~ /$options{'match-for-crawl'}/) {
                if ($type && $type =~ qr{text/(html|xml)}) {
                    my $encode = guess_encoding($res) || 'utf-8';
                    my $body    = Encode::decode($encode, $res->body);
                    my $dom     = Mojo::DOM->new($body);
                    my $base    = $tx->req->url;
                    if (my $base_tag = $dom->at('base')) {
                        $base = Mojo::URL->new($base_tag->attrs('href'));
                    }
                    my @a       = collect_urls($dom);
                    my @q       = grep {! $_->{$QUEUE_KEY_DIALOG}} @a;
                    my @dialog  = grep {$_->{$QUEUE_KEY_DIALOG}} @a;
                    append_queues($base, \@q, \@new_queues);
                    push(@dialogs, @dialog);
                } elsif ($type && $type =~ qr{text/(text|css)}) {
                    my $base    = $tx->req->url;
                    my $encode  = guess_encoding_css($res) || 'utf-8';
                    my $body    = Encode::decode($encode, $res->body);
                    my @urls    = collect_urls_from_css($body);
                    append_queues($base, \@urls, \@new_queues);
                }
            }
        } elsif($code && $code == 401) {
            my $tx  = $ua->max_redirects(0)->get($url);
            my $res = $tx->res;
            $code = {
                code    => $res->code,
                dialog  => {
                    'www-authenticate' => $res->headers->header('www-authenticate'),
                }
            };
        }
        return $code, \@new_queues, \@dialogs;
    }
    
    sub append_queues {
        my ($base, $urls, $append_to) = @_;
        for my $entry (@$urls) {
            if ($entry->{$QUEUE_KEY_LITERAL_URI} =~ qr{^(\w+):}
                                        && ! ( $1 ~~ [qw(http https ws wss)])) {
                next;
            }
            my $url2 = resolve_href($base, $entry->{$QUEUE_KEY_LITERAL_URI});
            if ($url2->scheme !~ qr{https?|ftp}) {
                next;
            }
            $url2 = "$url2";
            if ($options{match} && $url2 !~ /$options{match}/) {
                next;
            }
            if ($options{'match-for-check'} && $url2 !~ /$options{'match-for-check'}/) {
                next;
            }
            my $md5 = md5_sum($url2);
            if (exists $fix->{$md5}) {
                next;
            }
            $fix->{$md5} = undef;
            my $queue = {
                $QUEUE_KEY_CONTEXT      => $entry->{$QUEUE_KEY_CONTEXT},
                $QUEUE_KEY_LITERAL_URI  => $entry->{$QUEUE_KEY_LITERAL_URI},
            };
            if ($entry->{$QUEUE_KEY_LITERAL_URI} ne $url2) {
                $queue->{$QUEUE_KEY_RESOLVED_URI} = $url2;
            }
            push(@$append_to, $queue);
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
                $QUEUE_KEY_CONTEXT      => Mojo::Util::html_escape($context),
                $QUEUE_KEY_LITERAL_URI  => $href,
            };
        }
    }
    
    sub _analize_form_dom {
        my $dom = shift;
        if (my $href = $dom->{action}) {
            my @names;
            $dom->find('[name]')->each(sub {
                push(@names, shift->attrs('name'));
            });
            return {
                $QUEUE_KEY_CONTEXT      => 'FORM',
                $QUEUE_KEY_LITERAL_URI  => $href,
                $QUEUE_KEY_DIALOG       => {names => \@names},
            };
        }
    }
    
    sub collect_urls {
        my ($dom) = @_;
        my @array;
        $dom->find('script, link, a, img, area, meta[http\-equiv=Refresh]')->each(sub {
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
