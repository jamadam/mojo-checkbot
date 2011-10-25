package MojoCheckbot;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;
use Getopt::Long 'GetOptionsFromArray';
use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::URL;
use Mojo::IOLoop;
use Mojo::CookieJar;
use Mojo::Cookie::Response;
use Mojo::Util 'md5_sum';
use Mojo::Base 'Mojolicious';
use Encode;
use utf8;
use MojoCheckbot::FileCache;
our $VERSION = '0.16';
    
    my $QUEUE_KEY_CONTEXT       = 1;
    my $QUEUE_KEY_LITERAL_URI   = 2;
    my $QUEUE_KEY_RESOLVED_URI  = 3;
    my $QUEUE_KEY_REFERER       = 4;
    my $QUEUE_KEY_RES           = 5;
    my $QUEUE_KEY_ERROR         = 6;

    my %options;
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
            'start=s',
            'sleep=i',
            'ua=s',
            'cookie=s',
            'timeout=s',
            'resume',
        );
        
        my $queues = [];
        my $result = [];
        my $cache = MojoCheckbot::FileCache->new(cache_id());
        if ($options{resume} && $cache->exists) {
            my $resume = $cache->slurp;
            $queues = $resume->{queues};
            $result = $resume->{result};
            for my $key (@$queues, @$result) {
                $fix->{md5_sum($key)} = undef;
            }
            $fix = $resume->{fix};
        }
        $queues->[0] ||= {
            $QUEUE_KEY_RESOLVED_URI => $options{start},
            $QUEUE_KEY_REFERER      => 'N/A',
            $QUEUE_KEY_CONTEXT      => 'N/A',
            $QUEUE_KEY_LITERAL_URI  => 'N/A',
        };
        
        my $ua = Mojo::UserAgent->new->name($options{ua} || "mojo-checkbot($VERSION)");
        $ua->keep_alive_timeout($options{timeout});
        
        if ($options{cookie}) {
            my $cookies = Mojo::Cookie::Response->parse($options{cookie});
            $ua->cookie_jar(Mojo::CookieJar->new->add(@$cookies));
        }
        
        my $loop_id;
        $loop_id = Mojo::IOLoop->recurring($options{sleep} => sub {
            my $queue = shift @$queues;
            my ($res, $new_queues) = eval {
                check($queue->{$QUEUE_KEY_RESOLVED_URI}, $ua);
            };
            if ($@) {
                $queue->{$QUEUE_KEY_ERROR} = $@;
            } else {
                @$new_queues = map {
                    $_->{$QUEUE_KEY_REFERER} = $queue->{$QUEUE_KEY_RESOLVED_URI};
                    $_;
                } @$new_queues;
                push(@$queues, @$new_queues);
                $queue->{$QUEUE_KEY_RES} = $res;
            }
            push(@$result, $queue);
            if (! scalar @$queues) {
                Mojo::IOLoop->drop($loop_id);
            }
        });
        
        my $loop_id2;
        $loop_id2 = Mojo::IOLoop->recurring(5 => sub {
            $cache->store({queues  => $queues, result  => $result});
            if (! scalar @$queues) {
                Mojo::IOLoop->drop($loop_id2);
            }
        });
        
        my $r = $self->routes;
        $r->route('/diff')->to(cb => sub {
            my $c = shift;
            my $offset = $c->req->param('offset');
            my $last = scalar @$result;
            if ($last - $offset > 100) {
                $last = $offset + 100;
            }
            my @diff = @$result[$offset..$last];
            $c->render_json({queues => scalar @$queues, result => \@diff});
        });
        $r->route('/')->to(cb => sub {
            my $c = shift;
            $c->render('index');
        });
    }
    
    sub check {
        my ($url, $ua) = @_;
        my $tx = $ua->max_redirects(0)->head($url);
        my $code = $tx->res->code;
        if (! $code) {
            my ($message) = $tx->error;
            die $message;
        }
        my @new_queues;
        if (my $location = $tx->res->headers->header('location')) {
            push(@new_queues, {
                $QUEUE_KEY_CONTEXT      => '*Redirected by server configuration*',
                $QUEUE_KEY_LITERAL_URI  => $location,
                $QUEUE_KEY_RESOLVED_URI => $location,
            });
        }
        if ($code && $code == 200) {
            my $tx = $ua->max_redirects(0)->get($url);
            my $res = $tx->res;
            $code = $res->code;
            if ($res->headers->content_type =~ qr{text/(html|xml)}) {
                my $charset = guess_encoding($res) || 'utf-8';
                my $body = Encode::decode($charset, $res->body);
                my $dom = Mojo::DOM->new($body);
                my $base = $tx->req->url;
                if (my $base_tag = $dom->at('base')) {
                    $base = Mojo::URL->new($base_tag->attrs('href'));
                }
                my @urls = collect_urls($dom);
                for my $entry (@urls) {
                    my $url2 = resolve_href($base, $entry->{$QUEUE_KEY_LITERAL_URI});
                    if ($url2->scheme !~ qr{https?|ftp}) {
                        next;
                    }
                    if ($options{match} && "$url2" !~ /$options{match}/) {
                        next;
                    }
                    my $md5 = md5_sum($url2);
                    if (exists $fix->{$md5}) {
                        next;
                    }
                    $fix->{$md5} = undef;
                    push(@new_queues, {
                        $QUEUE_KEY_CONTEXT      => $entry->{$QUEUE_KEY_CONTEXT},
                        $QUEUE_KEY_LITERAL_URI  => $entry->{$QUEUE_KEY_LITERAL_URI},
                        $QUEUE_KEY_RESOLVED_URI => "$url2",
                    });
                }
            }
        }
        return $code, \@new_queues;
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
            Mojo::Util::html_escape($context);
            return {
                $QUEUE_KEY_CONTEXT      => $context,
                $QUEUE_KEY_LITERAL_URI  => $href,
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
        return @array;
    }
    
    sub guess_encoding {
        my $res = shift;
        my $type = $res->headers->content_type;
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
