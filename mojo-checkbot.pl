#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::URL;
use Getopt::Long;
    
    my $statistics = {};
    my $errors = [];
    my $checked = 0;

    my %options;
    GetOptions(\%options, 'match=s', 'report-urls');
    
    $| = 1;
    local $SIG{ALRM} = sub {
        print "$checked URLs checked for now.\n";
        for my $key (keys %$statistics) {
            my $num = 0;
            if (scalar @{$statistics->{$key}}) {
                $num = scalar @{$statistics->{$key}};
            }
            print "    $key: $num\n";
        }
        print scalar @$errors. " crawling errors occured\n";
        alarm 5;
    };
    alarm 5;
    
    my $url_filter = sub {1};
    
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
    
    my $ua = Mojo::UserAgent->new;
    
    my $res = check(Mojo::URL->new($ARGV[0]));
    
    if ($res && $res != 200) {
        print "GET $ARGV[0] causes status code $res";
    }
    
    my %fix;
    
    sub check {
        $checked++;
        no warnings 'recursion';
        my $url = shift;
        if ($url_filter->($url) && ! $fix{"$url"}) {
            $fix{"$url"} = 1;
            if ($options{'sreport-urls'}) {
                print "HEAD ". $url. "\n";
            }
            my ($head_res, $content_type) = head_code($url);
            if ($head_res && $head_res == 200) {
                if ($content_type =~ qr{text/(html|xml)}) {
                    my $http_res = $ua->max_redirects(5)->get($url);
                    my $dom = Mojo::DOM->new($http_res->res->body);
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
                            if ($href =~ qr{https?://}) {
                                $cur_url = Mojo::URL->new($href);
                            } else {
                                $cur_url = resolveHref($base || $url, $href);
                            }
                            if (my $res = check($cur_url)) {
                                $statistics->{$res} ||= [];
                                push(@{$statistics->{$res}}, {
                                    anchor  => $dom->content_xml,
                                    href    => $href,
                                    uri     => "$cur_url",
                                    referer => "$url",
                                });
                            }
                        }
                    });
                }
            }
            return $head_res;
        }
    }
    
    sub head_code {
        my $url = shift;
        my $res = $ua->max_redirects(5)->head($url);
        if ($res->error) {
            push(@$errors, $res->error);
        } else {
            return $res->res->code, $res->res->headers->content_type;
        }
        return;
    }
    
    sub resolveHref {
        my ($base, $href) = @_;
        my $new = $base->clone;
        my $temp = Mojo::URL->new($href);
        $new->path($temp->path->to_string);
        $new->path->canonicalize;
        $new->query($temp->query);
        $new->fragment($temp->fragment);
        return $new;
    }
