#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw'catdir rel2abs splitdir';
use lib catdir(dirname(__FILE__), 'lib');
use File::Find::Rule;
use Text::Sass::XS;
use Try::Tiny;

my @dirs = (
    catdir(dirname(__FILE__), 'lib/MojoCheckbot'),
);

my @files = File::Find::Rule->file()->name('*.scss')->in(@dirs);

print scalar(@files). " scss files found.\n";

my $sass = Text::Sass::XS->new;
my $errors = 0;
for my $in (@files) {
    my $out = $in;
    $out =~ s{\.scss}{.css};
    
    try {
        my $css = $sass->compile_file($in);
        open(my $fh, ">", $out) or die 'can\'t open file $out';
        print $fh qq{\@charset "UTF-8";\n}; # libsass bug or something? https://github.com/hcatlin/libsass/issues/313
        print $fh $css;
        close($fh);
        print "$in successfully compiled\n";
    } catch {
        print "FAIL: $_";
        $errors++;
    };
}

if ($errors) {
    print "Some errors occured during the compilation.\n";
} else {
    print "All scss files successfully compiled.\n";
}
