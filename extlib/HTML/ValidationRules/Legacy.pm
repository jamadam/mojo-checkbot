package HTML::ValidationRules::Legacy;
use strict;
use warnings;
use Mojo::Base 'Exporter';
use Mojo::JSON;
use Mojo::Util qw{decode};

our @EXPORT_OK = qw(extract validate),

our $TERM_PROPERTIES         = 'properties';
our $TERM_REQUIRED           = 'required';
our $TERM_MAXLENGTH          = 'maxLength';
our $TERM_MIN_LENGTH         = 'minLength';
our $TERM_OPTIONS            = 'options';
our $TERM_PATTERN            = 'pattern';
our $TERM_MIN                = 'maximam';
our $TERM_MAX                = 'minimum';
our $TERM_TYPE               = 'type';
our $TERM_ADD_PROPS          = 'additionalProperties';
our $TERM_NUMBER             = 'number';

sub extract {
    my ($form, $charset) = @_;
    my $props   = {};
    my @required;
    
    if (! ref $form) {
        $form = Mojo::DOM->new($charset ? decode($charset, $form) : $form);
    }
    
    $form->find("*[name]")->each(sub {
        my $tag = shift;
        my $type = $tag->attr('type');
        my $name = $tag->attr('name');
        $props->{$name} ||= {};
        
        if (grep {$_ eq $type} qw{hidden checkbox radio submit image}) {
            push(@{$props->{$name}->{$TERM_OPTIONS}}, $tag->attr('value'));
        }
        
        if ($tag->type eq 'select') {
            $tag->find('option')->each(sub {
                push(@{$props->{$name}->{$TERM_OPTIONS}}, shift->attr('value'));
            });
        }
        
        if ($type eq 'number') {
            $props->{$name}->{$TERM_TYPE} = $TERM_NUMBER;
            if (my $val = $tag->attr->{min}) {
                $props->{$name}->{$TERM_MIN} = $val;
            }
            if (my $val = $tag->attr->{max}) {
                $props->{$name}->{$TERM_MAX} = $val;
            }
        }
        
        if (! exists $tag->attr->{disabled}) {
            if ($type ne 'submit' && $type ne 'image' && $type ne 'checkbox' &&
                        ($type ne 'radio' || exists $tag->attr->{checked})) {
                $props->{$name}->{$TERM_REQUIRED} = Mojo::JSON->true;
            }
        }
            
        if (exists $tag->attr->{maxlength}) {
            $props->{$name}->{$TERM_MAXLENGTH} = $tag->attr->{maxlength} || 0;
        }
        
        if (exists $tag->attr->{required}) {
            $props->{$name}->{$TERM_MIN_LENGTH} = 1;
        }
        
        if (exists $tag->attr->{pattern}) {
            $props->{$name}->{$TERM_PATTERN} = $tag->attr->{pattern};
        }
    });
    
    return {
        $TERM_PROPERTIES => $props,
        $TERM_ADD_PROPS => Mojo::JSON->false,
    };
}

sub validate {
    my ($schema, $params, $charset) = @_;
    
    if (! ref $params) {
        $params = Mojo::Parameter->new;
        $params->charset($charset);
        $params->append($params);
    }
    
    my $props = $schema->{$TERM_PROPERTIES};
    
    if (! $schema->{$TERM_ADD_PROPS}) {
        for my $name ($params->param) {
            if (! $props->{$name}) {
                return "Field $name is injected";
            }
        }
    }
    
    for my $name (keys %$props) {
        
        my @params = $params->param($name);
        
        if (($props->{$name}->{$TERM_REQUIRED} || '') eq Mojo::JSON->true) {
            if (! scalar @params) {
                return "Field $name is required";
            }
        }
        
        if (my $allowed = $props->{$name}->{$TERM_OPTIONS}) {
            for my $given (@params) {
                if (! grep {$_ eq $given} @$allowed) {
                    return "Field $name has been tampered";
                }
            }
        }
        if (exists $props->{$name}->{$TERM_MAXLENGTH}) {
            for my $given (@params) {
                if (length($given) > $props->{$name}->{$TERM_MAXLENGTH}) {
                    return "Field $name is too long";
                }
            }
        }
        if (defined $props->{$name}->{$TERM_MIN_LENGTH}) {
            for my $given (@params) {
                if (length($given) < $props->{$name}->{$TERM_MIN_LENGTH}) {
                    return "Field $name cannot be empty";
                }
            }
        }
        if (my $pattern = $props->{$name}->{$TERM_PATTERN}) {
            for my $given (@params) {
                if ($given !~ /\A$pattern\Z/) {
                    return "Field $name not match pattern";
                }
            }
        }
        if (($props->{$name}->{$TERM_TYPE} || '') eq $TERM_NUMBER) {
            for my $given (@params) {
                if ($given !~ /\A[\d\+\-\.]+\Z/) {
                    return "Field $name not match pattern";
                }
                if (my $min = $props->{$name}->{$TERM_MIN}) {
                    if ($given < $min) {
                        return "Field $name too low";
                    }
                }
                if (my $max = $props->{$name}->{$TERM_MAX}) {
                    if ($given > $max) {
                        return "Field $name too great";
                    }
                }
            }
        }
    }
    return;    
}

1;

__END__

=head1 NAME

HTML::ValidationRules::Legacy - Extract Validation Rules from HTML Form Element

=head1 SYNOPSIS

=head1 DESCRIPTION

B<This software is considered to be alpha quality and isn't recommended for
regular usage.>

=head2 CLASS METHODS

=head3 extract

    my $schema = extract($form_in_strig, $charset)
    my $schema = extract($form_in_mojo_dom)

Generates a schema out of form string or Mojo::DOM instance. It returns
schema in hashref consists of JSON-schema-like properties.

=head3 validate

Validates form data against given schema.

    my $error = validate($params_in_string, $schema, $charset);
    my $error = validate($params_in_mojo_params, $schema);

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
