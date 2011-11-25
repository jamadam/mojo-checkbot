use strict;
use warnings;
use Test::Memory::Cycle;
use Test::More;
use Mojolicious::Plugin::Tusu;

use Test::More tests => 1;

my $app = SomeApp->new;
memory_cycle_ok( $app );


package SomeApp;
use strict;
use warnings;
use base 'Mojolicious';
use Mojolicious::Plugin::Tusu;

sub startup {
    my $self = shift;
    my $tusu = $self->plugin(tusu => {});
}

__END__