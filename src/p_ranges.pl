#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;

my $fh = IO::File->new($ARGV[0]) || die "Cannot open p-value file: $ARGV[0]"."!!\n";
my $out = IO::File->new("> $ARGV[1].rangeList.txt");

while(my $line = $fh->getline)
{
    chomp($line);
    print $out $line." ";
    print $out "0"." ";
    print $out $line."\n";
}

$fh->close;
$out->close;
