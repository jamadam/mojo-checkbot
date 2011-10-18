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
use MojoCheckbot::Util;
use Mojo::Base 'Mojolicious';
our $VERSION = '0.0.1';

    my $url_filter = sub {1};
    my $jobs = [];
    my %options;
    my $ua;
    my $fix;

    sub startup {
        my $self = shift;
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
            anchor  => 'N/A',
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
        return MojoCheckbot::Util::fetch($url, $self->ua, sub{
            my $http_res = shift;
            if ($http_res->res->headers->content_type =~ qr{text/(html|xml)}) {
                my $body = $http_res->res->body;
                utf8::decode($body);
                my $dom = Mojo::DOM->new($body);
                $dom->xml(1);
                my $base = $url;
                if (my $base_tag = $dom->at('base')) {
                    $base = Mojo::URL->new($base_tag->attrs('href'));
                }
                $dom->find('body a')->each(sub {
                    my $dom = shift;
                    my $href = $dom->{href};
                    if ($href && $href !~ /^(mailto|javascript):/) {
                        $href =~ s{#[^#]+$}{};
                        my $cur_url;
                        if ($href =~ qr{https?://}) {
                            $cur_url = Mojo::URL->new($href);
                        } else {
                            $cur_url = MojoCheckbot::Util::resolve_href($base, $href);
                        }
                        if ($url_filter->("$cur_url") && ! $fix->{$cur_url}) {
                            $fix->{$cur_url} = 1;
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
        });
    }

1;
