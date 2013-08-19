#!/usr/bin/perl

use 5.010;
use warnings;
use strict;

require '_rtrv_info.pl';

sub rtrv_info {
    my $target = shift @_;
    my $args_ref = shift @_;
    my %info; 

    unless(%info = &_rtrv_info_db($target, $args_ref)){
	%info = &_rtrv_info_fb($target, $args_ref);
	&_put_info_db(\%info, $args_ref) unless (defined $info{error});
    }

    return %info;
}

# (my %information = &rtrv_info($ARGV[0])) or die "I can't retrieve $ARGV[0]'s basic information\n";
# say "$_ --> $information{$_}" for (keys %information);
    
