#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MojoCheckbot',
  VERSION_FROM => 'lib/MojoCheckbot.pm',
  AUTHOR       => 'jamadam <sugama@jamadam.com>',
  PREREQ_PM    => {'Mojolicious' => '2.31'},
  test         => {TESTS => 't/*.t'}
);
