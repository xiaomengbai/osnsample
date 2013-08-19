#!/usr/bin/perl

while(<>){
    chomp;
    next if $_ =~ /^\s*#/ or $_ =~ /^\s*$/;
    my @acc = split /[\t| ]+/, $_;
    my $res = `./get-cookies.pl $acc[0] $acc[1] 2>&1`;
    print "cookies/$1," if $res =~ /Cookie File: (.*cookies)/
}
print "\n";

