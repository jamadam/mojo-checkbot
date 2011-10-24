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
use Mojo::JSON;
use Mojo::IOLoop;
use Mojo::CookieJar;
use Mojo::Cookie::Response;
use Mojo::Base 'Mojolicious';
use Encode;
use utf8;
use Mojo::Util 'md5_sum';
use MojoCheckbot::FileCache;
our $VERSION = '0.13';

    my $url_filter = sub {1};
    my %options;
    my $fix;
    
    sub cache_id {
        my $seed = join('\t',
            $options{start},
            $options{match}     || '',
            $options{ua}        || '',
            $options{cookie}    || '',
            $options{timeout}   || '',
        );
        return md5_sum($seed);
    }

    sub startup {
        my $self = shift;
        my $home2 = Mojo::Home->new($self->home);
        $self->app->secret(time());
        $self->home->parse(File::Spec->catdir(dirname(__FILE__), 'MojoCheckbot'));
        $self->static->root($self->home->rel_dir('public'));
        $self->renderer->root($self->home->rel_dir('templates'));
        
        local @ARGV = @ARGV;
        GetOptionsFromArray(\@ARGV, \%options,
            'match=s' ,
            'start=s',
            'sleep=i',
            'ua=s',
            'cookie=s',
            'timeout=s',
            'resume',
        );
        
        my $ua;
        my $jobs = [];
        my @result;
        my $cache_id = cache_id();
        my $cache_dir = File::Spec->catfile(File::Spec->tmpdir, 'mojo-checkbot');
        mkdir($cache_dir);
        my $cache =
        MojoCheckbot::FileCache->new->path(File::Spec->catfile($cache_dir, $cache_id));
        if ($options{resume} && $cache->exists) {
            my $resume = Mojo::JSON->new->decode($cache->slurp);
            $jobs = $resume->{jobs};
            @result = @{$resume->{result}};
        }
        
        $jobs->[0] ||= {
            resolvedURI     => Mojo::URL->new($options{start}),
            referer         => 'N/A',
            context         => 'N/A',
            literalURI      => 'N/A',
        };
        
        $ua = Mojo::UserAgent->new->name($options{ua} || "mojo-checkbot($VERSION)");
        $ua->keep_alive_timeout($options{timeout});
        
        if ($options{cookie}) {
            my $cookies = Mojo::Cookie::Response->parse($options{cookie});
            $ua->cookie_jar(Mojo::CookieJar->new->add(@$cookies));
        }
        
        if ($options{match}) {
            my $url_filter_last = $url_filter;
            $url_filter = sub {
                my $url = shift;
                if (! $url_filter_last->($url)) {
                    return 0;
                }
                return "$url" =~ /$options{match}/;
            };
        }
        
        my $loop_id;
        $loop_id = Mojo::IOLoop->recurring($options{sleep} => sub {
            my $job = shift @$jobs;
            my ($res, $new_jobs) = eval {
                check($job->{resolvedURI}, $ua);
            };
            if ($@) {
                $job->{error} = $@;
            } else {
                push(@$jobs, @$new_jobs);
                $job->{res} = $res;
            }
            $job->{resolvedURI} = "$job->{resolvedURI}";
            push(@result, $job);
            if (! scalar @$jobs) {
                Mojo::IOLoop->drop($loop_id);
            }
        });
        
        my $loop_id2;
        $loop_id2 = Mojo::IOLoop->recurring(5 => sub {
            my $json = Mojo::JSON->new->encode({jobs => $jobs, result => \@result});
            $cache->store($json);
            if (! scalar @$jobs) {
                Mojo::IOLoop->drop($loop_id2);
            }
        });
        
        my $r = $self->routes;
        $r->route('/echo')->to(cb => sub {
            my $c = shift;
            my $offset = $c->req->param('offset');
            my @diff = @result[$offset..$#result];
            $c->render_json({remain => scalar @$jobs, result => \@diff});
        });
        $r->route('/')->to(cb => sub {
            my $c = shift;
            $c->render('index');
        });
    }
    
    sub check {
        my ($url, $ua) = @_;
        my $tx = $ua->max_redirects(5)->head($url);
        my $code = $tx->res->code;
        if (! $code) {
            my ($message) = $tx->error;
            die $message;
        }
        my @new_jobs;
        if ($code && $code == 200) {
            my $tx = $ua->max_redirects(5)->get($url);
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
                    my $url2 = resolve_href($base, $entry->{literalURI});
                    if ($url2->scheme =~ qr{https?|ftp}
                            && $url_filter->("$url2") && ! $fix->{$url2}) {
                        $fix->{$url2} = 1;
                        push(@new_jobs, {
                            context     => $entry->{context},
                            literalURI  => $entry->{literalURI},
                            resolvedURI => "$url2",
                            referer     => "$url",
                        });
                    }
                }
            }
        }
        return $code, \@new_jobs;
    }
    
    sub collect_urls {
        my ($dom) = @_;
        my @array;
        $dom->find('script, link, a, img, area')->each(sub {
            my $dom = shift;
            if (my $href = $dom->{href} || $dom->{src}) {
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
                push(@array, {context  => $context, literalURI => $href});
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
