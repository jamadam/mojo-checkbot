#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MojoCheckbot',
  VERSION_FROM => 'lib/MojoCheckbot.pm',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  EXE_FILES    => ['script/mojo_checkbot'],
  test         => {TESTS => 't/*.t'}
);
