package MojoCheckbot::Util;
use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::Util;
use Mojo::DOM;
use Mojo::URL;
use Mojo::JSON;
use Mojo::IOLoop;
use Mojolicious::Lite;
    
    sub try_head {
        my ($url, $ua) = @_;
        my $res = $ua->max_redirects(5)->head($url);
        return $res->res->code, $res->res->headers->content_type, $res->error;
    }
    
    sub resolve_href {
        my ($base, $href) = @_;
        my $new = $base->clone;
        my $temp = Mojo::URL->new($href);
        $new->path($temp->path->to_string);
        $new->path->canonicalize;
        $new->query($temp->query);
        $new->fragment($temp->fragment); # delete?
        if ($new->path->parts->[0] && $new->path->parts->[0] =~ /^\./) {
            shift @{$new->path->parts};
        }
        return $new;
    }

1;
