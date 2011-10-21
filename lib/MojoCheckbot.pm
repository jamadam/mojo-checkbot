package MojoCheckbot;
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use Data::Dumper;
use Getopt::Long 'GetOptionsFromArray';
use Mojo::UserAgent;
use Mojo::Util;
use Mojo::DOM;
use Mojo::URL;
use Mojo::JSON;
use Mojo::IOLoop;
use Mojo::CookieJar;
use Mojo::Cookie::Response;
use Mojo::Base 'Mojolicious';
use Encode;
our $VERSION = '0.01';

    my $url_filter = sub {4};
    my $jobs = [];
    my %options;
    my $ua;
    my $fix;

    sub startup {
        my $self = shift;
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
        );
        
        $jobs->[0] = {
            url     => Mojo::URL->new($options{start}),
            referer => 'N/A',
            context  => 'N/A',
            href    => 'N/A',
        };
        
        $ua = Mojo::UserAgent->new->name($options{ua} || "mojo-checkbot($VERSION)");
        
        if ($options{cookie}) {
            my $cookies = Mojo::Cookie::Response->parse($options{cookie});
            $self->ua->cookie_jar(Mojo::CookieJar->new->add(@$cookies));
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
        
        my @result;
        my $loop_id;
        $loop_id = Mojo::IOLoop->recurring($options{sleep} => sub {
            my $job = shift @$jobs;
            my $res = $self->check($job->{url});
            $job->{res} = $res;
            $job->{url} = "$job->{url}";
            push(@result, $job);
            if (! scalar @$jobs) {
                Mojo::IOLoop->drop($loop_id);
            }
        });
        
        my $r = $self->routes;
        $r->route('/echo')->to(cb => sub {
            my $c = shift;
            my $offset = $c->req->param('offset');
            my @result1 = @result[$offset..$#result];
            $c->render_json({remain => scalar @$jobs, result => \@result1});
        });
        $r->route('/')->to(cb => sub {
            my $c = shift;
            $c->render('index');
        });
    }
    
    sub check {
        my ($self, $url) = @_;
        return fetch($url, $self->ua, sub{
            my $tx = shift;
            my $res = $tx->res;
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
                    my $url2 = resolve_href($base, $entry->{href});
                    if ($url2->scheme =~ qr{https?|ftp} && $url_filter->("$url2") && ! $fix->{$url2}) {
                        $fix->{$url2} = 1;
                        push(@$jobs, {
                            context => $entry->{context},
                            href => $entry->{href},
                            url => $url2,
                            referer => "$url",
                        });
                    }
                }
            }
        });
    }
    
    sub collect_urls {
        my ($dom) = @_;
        my @array;
        my $cb = sub {
            my $dom = shift;
            if (my $href = $dom->{href} || $dom->{src}) {
                $href =~ s{#[^#]+$}{};
                my $context =
                        $dom->content_xml || $dom->{alt} || $dom->{title} || '';
                Mojo::Util::html_escape($context);
                push(@array, {
                    context  => $context,
                    href    => $href,
                });
            }
        };
        $dom->find('script')->each($cb);
        $dom->find('link')->each($cb);
        $dom->find('a')->each($cb);
        $dom->find('img')->each($cb);
        $dom->find('area')->each($cb);
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
    
    sub fetch {
        my ($url, $ua, $cb) = @_;
        my ($res, $content_type, $ua_error) = try_head($url, $ua);
        if ($res && $res == 200) {
            my $http_res = $ua->max_redirects(5)->get($url);
            $cb->($http_res);
            return $http_res->res->code;
        }
        return $res;
    }
    
    sub try_head {
        my ($url, $ua) = @_;
        my $res = $ua->max_redirects(5)->head($url);
        return $res->res->code, $res->res->headers->content_type, $res->error;
    }
    
    sub resolve_href {
        my ($base, $href) = @_;
        my $new = $base->clone;
        my $temp = Mojo::URL->new($href);
        if ($temp->scheme) {
            return $temp;
        }
        $new->path($temp->path->to_string);
        $new->path->canonicalize;
        $new->query($temp->query);
        $new->fragment($temp->fragment); # delete?
        while ($new->path->parts->[0] && $new->path->parts->[0] =~ /^\./) {
            shift @{$new->path->parts};
        }
        return $new;
    }

1;
