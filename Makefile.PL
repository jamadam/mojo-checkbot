use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME            => 'MojoCheckbot',
    VERSION_FROM    => 'lib/MojoCheckbot.pm',
    ABSTRACT_FROM   => 'lib/MojoCheckbot.pm',
    LICENSE         => 'perl',
    AUTHOR          => 'jamadam <sugama@jamadam.com>',
    PREREQ_PM       => {
    },
    BUILD_REQUIRES => {
        'Mojolicious'   => '4.67',
        'Clone::PP'     => '1.02',
    },
);

my $eumm = $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}          if $eumm < 6.31;
delete $params{MIN_PERL_VERSION} if $eumm < 6.48;
delete $params{META_MERGE}       if $eumm < 6.46;
delete $params{META_ADD}         if $eumm < 6.46;
delete $params{LICENSE}          if $eumm < 6.31;

if ($eumm < 6.52 && $params{CONFIGURE_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}          || {} },
        %{ $params{CONFIGURE_REQUIRES} },
    };
    delete $params{CONFIGURE_REQUIRES};
}
if ($eumm < 6.5503 && $params{BUILD_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}      || {} },
        %{ $params{BUILD_REQUIRES} },
    };
    delete $params{BUILD_REQUIRES};
}

WriteMakefile(%params);
