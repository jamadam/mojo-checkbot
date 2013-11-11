package MojoCheckbot::FileCache;
use strict;
use warnings;
use Mojo::Base -base;
use Carp 'croak';
use Fcntl ':flock';
use IO::File;
use File::Basename qw(dirname);
use File::Spec;
use Mojo::JSON;

has 'path';
has 'dir' => sub {
    File::Spec->catfile(File::Spec->tmpdir, 'mojo-checkbot');
};

my $j = Mojo::JSON->new;

sub new {
    my $self = shift->SUPER::new();
    my $name = shift;
    mkdir $self->dir;
    $self->path(File::Spec->catfile($self->dir, $name));
    return $self;
}

sub exists {
    my $self = shift;
    return -f $self->path;
}

sub store {
    my ($self, $data) = @_;
    my $path = $self->path;
    my $json = $j->encode($data);
    my $handle = IO::File->new("$path", '>:utf8');
    if (! $handle) {
        croak qq{Can't open cache file "$path": $!};
    }
    flock $handle, LOCK_EX;
    $handle->sysseek(0, SEEK_SET);
    $handle->syswrite($json);
    $handle->eof;
    flock $handle, LOCK_UN;
    return $self;
}

sub slurp {
    my $self = shift;
    my $path = $self->path;
    my $handle = IO::File->new("$path", '<:utf8');
    if (! $handle) {
        croak qq{Can't open cache file "$path": $!};
    }
    $handle->sysseek(0, SEEK_SET);
    my $content = '';
    while ($handle->sysread(my $buffer, 131072)) {
        $content .= $buffer;
    }
    return $j->decode($content);
}

1;
__END__

=head1 NAME

MojoCheckbot::FileCache - Cache handler

=head1 SYNOPSIS
    
    my $cahce = MojoCheckbot::FileCache->new;
    $cahce->path('/path/to/cache');
    $cahce->store('string');
    my $string = $cahce->slurp;

=head1 DESCRIPTION

MojoCheckbot::FileCache represents file caches used by MojoCheckbot.

=head1 METHODS

=head2 MojoCheckbot::FileCache->new

=head2 $instance->exists

=head2 $instance->store

Stores string into cache files.

=head2 $instance->slurp

Read cache file and returns it.

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
