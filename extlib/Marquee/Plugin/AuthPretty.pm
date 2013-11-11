package Marquee::Plugin::AuthPretty;
use strict;
use warnings;
use Mojo::Util qw'encode hmac_sha1_sum';
use Mojo::Base 'Marquee::Plugin';

__PACKAGE__->attr(realm => 'Secret Area');

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app, $entries, $storage, $expire) = @_;
    
    if (! -d $storage) {
        die "$storage is not a directory";
    }
    
    _vacuum($self, $storage, $expire);
    
    push(@{$app->roots}, __PACKAGE__->Marquee::asset());
    
    $app->hook(around_dispatch => sub {
        my ($next) = @_;
        
        my $c       = Marquee->c;
        my $path    = $c->req->url->path->clone->leading_slash(1)->to_string;
        my $secret  = $c->app->secret;
        
        my @entries = @$entries;
        while (@entries) {
            my $regex   = shift @entries;
            my $realm   = ! ref $entries[0] ? shift @entries : $self->realm;
            my $cb      = shift @entries;
            
            $regex =~ s{:(.+)}{:\($1\)};
            
            if ($path !~ $regex) {
                next;
            }
            
            my $matched = $1;
            
            # already authorized
            if (my $sess_id = $c->signed_cookie('pretty_auth')) {
                if (-e File::Spec->catfile($storage,
                                hmac_sha1_sum($matched, $sess_id, $secret))) {
                    last;
                }
            }
            
            # authentication
            my $username = $c->req->body_params->param('username') || '';
            my $password = $c->req->body_params->param('password') || '';
            if (! $cb->($username, $password)) {
                $c->stash->set(
                    static_dir  => 'static',
                    path        => $path,
                    realm       => $realm,
                );
                $c->res->body(
                    encode('UTF-8',
                        $app->dynamic->handlers->{ep}->render_traceable(
                            __PACKAGE__->Marquee::asset('auth.html.ep')
                        )
                    )
                );
                $c->res->code(200);
                $c->res->headers->content_type($app->types->type('html'));
                return;
            }
            
            # store session
            my $sess_id = hmac_sha1_sum($^T. $$. rand(1000000));
            $c->signed_cookie(pretty_auth => $sess_id);
            my $sess_file = hmac_sha1_sum($matched, $sess_id, $secret);
            IO::File->new(
                    File::Spec->catfile($storage, $sess_file), '>>') or die $!;
            
            # redirect
            $c->app->serve_redirect($path);
            return;
        }
        
        if (! $c->served) {
            $next->();
        }
    });
}

### --
### vacuum session file directory
### --
sub _vacuum {
    my ($self, $storage, $expire) = @_;
    
    $expire ||= 3600;
    
    opendir(my $dir, $storage);
    
    map {
        my $file = File::Spec->catfile($storage, $_);
        if (-f $file && time - (stat $file)[9] > $expire) {
            unlink($file);
        }
    } readdir($dir);
    
    closedir($dir);
}

1;

__END__

=head1 NAME

Marquee::Plugin::AuthPretty - [EXPERIMENTAL] Pretty authentication form

=head1 SYNOPSIS
    
    $self->plugin(AuthPretty => [
        qr{^/admin/} => 'Secret Area' => sub {
            my ($username, $password) = @_;
            return $username eq 'user' &&  $password eq 'pass';
        },
        qr{^/admin/} => 'Secret Area2' => sub {
            my ($username, $password) = @_;
            return $username eq 'user' &&  $password eq 'pass';
        },
    ], 'path/to/storage_dir', 3600);

=head1 DESCRIPTION

This plugin wraps the whole dispatcher and requires authentication for
specific paths with pretty viewed form.

=head1 ATTRIBUTES

L<Marquee::Plugin::AuthPretty> inherits all attributes from
L<Marquee::Plugin> and implements the following new ones.

=head2 C<realm>

Default value of realm which appears to response header. Each entry can override
it. Defaults to 'Secret Area'.

    $plugin->realm('My secret area');
    my $realm = $plugin->realm;

=head1 INSTANCE METHODS

L<Marquee::Plugin::AuthPretty> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin with path entries. $path_entries must be a list of
regex, realm, auth callback groups. realm is optional.

    $self->register($app, $path_entries);

=head1 EXAMPLE

You can port apache htpasswd entries as follows.

    my $htpasswd = {
        user1 => 'znq.opIaiH.zs',
        user2 => 'dF45lPM2wMCDA',
    };
    
    $self->plugin(AuthPretty => [
        qr{^/admin/} => 'Secret Area' => sub {
            my ($username, $password) = @_;
            if (my $expect = $htpasswd->{$username}) {
                return crypt($password, $expect) eq $expect;
            }
        },
    ]);

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut
