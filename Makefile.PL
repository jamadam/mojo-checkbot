#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MojoCheckbot',
  VERSION_FROM => 'lib/MojoCheckbot.pm',
  AUTHOR       => 'jamadam <sugama@jamadam.com>',
  EXE_FILES    => ['script/mojo-checkbot'],
  test         => {TESTS => 't/*.t'}
);
