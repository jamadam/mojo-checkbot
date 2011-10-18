#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';
use Data::Dumper;
use Getopt::Long 'GetOptionsFromArray';
use Mojo::UserAgent;
use Mojo::Util;
use Mojo::DOM;
use Mojo::URL;
use Mojo::JSON;
use Mojo::IOLoop;
use Mojolicious::Lite;
use MojoCheckbot::Util;

    my %options;
    GetOptionsFromArray(\@ARGV, \%options,
        'match=s',
        'start=s',
        'delay=i',
    );
    
    my $jobs = [{
        url     => Mojo::URL->new($options{start}),
        referer => 'N/A',
        anchor  => 'N/A',
        href    => 'N/A',
    }];
    
    my @result;
    my $errors = [];
    my %fix;
    my $ua = Mojo::UserAgent->new;
    my $url_filter = sub {1};
    my $clients = {};
    
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
    $loop_id = Mojo::IOLoop->recurring($options{delay} => sub {
        my $job = shift @$jobs;
        my $res = check($job->{url});
        $job->{res} = $res;
        $job->{url} = "$job->{url}";
        push(@result, $job);
        if (! scalar @$jobs) {
            Mojo::IOLoop->drop($loop_id);
        }
    });
    
    get '/echo' => sub {
        my $self = shift;
        my $offset = $self->req->param('offset');
        my @result1 = @result[$offset..$#result];
        $self->render_json({remain => scalar @$jobs, result => \@result1});
    };
    
    any '/' => sub {
        my $self = shift;
        $self->render('index');
    };
    
    app->start;
    
    sub check {
        my $url = shift;
        my ($head_res, $content_type, $ua_error) = MojoCheckbot::Util::try_head($url, $ua);
        if ($ua_error) {
            push(@$errors, $ua_error);
        }
        if ($head_res && $head_res == 200) {
            if ($content_type =~ qr{text/(html|xml)}) {
                my $http_res = $ua->max_redirects(5)->get($url);
                my $body = $http_res->res->body;
                utf8::decode($body);
                my $dom = Mojo::DOM->new($body);
                $dom->xml(1);
                my $base;
                if (my $base_tag = $dom->at('base')) {
                    $base = Mojo::URL->new($base_tag->attrs('href'));
                }
                $dom->find('body a')->each(sub {
                    my $dom = shift;
                    my $href = $dom->{href};
                    if ($href) {
                        $href =~ s{#[^#]+$}{};
                        my $cur_url;
                        if ($href =~ /^(mailto|javascript):/) {
                            return;
                        }
                        if ($href =~ qr{https?://}) {
                            $cur_url = Mojo::URL->new($href);
                        } else {
                            $cur_url = MojoCheckbot::Util::resolve_href($base || $url, $href);
                        }
                        if ($url_filter->("$cur_url") && ! $fix{$cur_url}) {
                            $fix{$cur_url} = 1;
                            my $anchor = $dom->content_xml;
                            Mojo::Util::html_escape($anchor);
                            push(@$jobs, {
                                anchor  => $anchor,
                                href    => $href,
                                url     => $cur_url,
                                referer => "$url",
                            });
                        }
                    }
                });
            }
        }
        return $head_res;
    }
