package Marquee::Plugin::EPHelperExample;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
use List::Util qw{min};

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app) = @_;
    
    # Commify a number
    $app->dynamic->handlers->{ep}->add_function(commify => sub {
        my ($ep, $num) = @_;
        
        if ($num) {
            while($num =~ s/(.*\d)(\d\d\d)/$1,$2/){};
            return $num;
        }
        if ($num eq '0') {
            return 0;
        }
        return;
    });
    
    # Mininum value out of given array
    $app->dynamic->handlers->{ep}->add_function(min => sub {
        my ($ep, @array) = @_;
        if (ref $array[0] && ref $array[0] eq 'ARRAY') {
            @array = @{$array[0]};
        }
        return List::Util::min(@array);
    });
    
    # Maximum value out of given array
    $app->dynamic->handlers->{ep}->add_function(max => sub {
        my ($ep, @array) = @_;
        if (ref $array[0] && ref $array[0] eq 'ARRAY') {
            @array = @{$array[0]};
        }
        return List::Util::max(@array);
    });
    
    # Replace string
    $app->dynamic->handlers->{ep}->add_function(replace => sub {
        my ($ep, $str, $search, $replace) = @_;
        if (ref $search && ref $search eq 'Regexp') {
            $str =~ s{$search}{$replace}g;
        } else {
            $str =~ s{\Q$search\E}{$replace}g;
        }
        return $str;
    });
    
}

1;

__END__

=head1 NAME

Marquee::Plugin::EPHelperExample - An Example for EP helpers

=head1 SYNOPSIS

    $app->plugin('EPHelperExample');

In templates..

    <%= commify($price) %>
    <%= min(@prices) %>
    <%= max(@prices) %>
    <%= replace($string, '::', '/') %>
    <%= replace($string, qr/\s/, '') %>

=head1 DESCRIPTION

This is an example plugin for adding EP template functions.

=head1 FUNCTIONS

The following template functions are available.

=head2 commify

Commifies given number.

    <%= commify(123456789) %> <!-- 123,456,789 -->

=head2 min

Finds the minimum value of array of numbers.

    <%= min(1, 2, 3) %> <!-- 1 -->

=head2 max

Finds the maximum value of array of numbers.

    <%= max(1, 2, 3) %> <!-- 3 -->

=head2 replace

Replaces given string or pattern in given string.

    <%= replace('foo::bar', '::', '/') %> <!-- foo/bar -->
    <%= replace('foo::::bar', qr{:+}, '/') %> <!-- foo/bar -->

=head1 INSTANCE METHODS

L<Marquee::Plugin::EPHelperExample> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin.

    $self->register($app);

=head1 SEE ALSO

L<Marquee::SSIHandler::EP>, L<Marquee>, L<Mojolicious>

=cut
