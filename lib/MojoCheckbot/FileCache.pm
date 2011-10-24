package MojoCheckbot::FileCache;
use Mojo::Base -base;
use Carp 'croak';
use Fcntl ':flock';
use IO::File;

has 'path';

sub exists {
    my $self = shift;
    return -f $self->path;
}

sub store {
    my ($self, $data) = @_;
    my $path = $self->path;
    my $handle = IO::File->new("$path", '>:utf8');
    if (! $handle) {
        croak qq{Can't open cache file "$path": $!};
    }
    flock $handle, LOCK_EX;
    $handle->sysseek(0, SEEK_SET);
    $handle->syswrite($data);
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
    return $content;
}

1;
__END__
