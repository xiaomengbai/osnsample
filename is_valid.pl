#!/usr/bin/perl

use 5.010;
use warnings;
use strict;

require 'rtrv_info.pl';
require 'rtrv_flist.pl';
require 'util_cookies.pl';

sub is_valid {
    my $target = shift @_;
    my $args_ref = shift @_;

    my %info = &rtrv_info($target, $args_ref);
    
    while((defined $info{error}) and ($info{error} =~ /request limited/)){
	&max_cur_cookies($args_ref);
	my $cookies = &avail_cookies($args_ref) or die "no available cookies for requesting info";
	say "switch cookies from ${$args_ref}{cookies_in_use} to $cookies because limited request";
	&set_cookies($args_ref, $cookies);
	&reload_browser($args_ref);
    }

    return 0 unless (%info and $info{id} < 2000000000);
#    say "check friend-list";

    my @flist = &rtrv_flist($info{username}, $args_ref);
#    say "check friend-list and $info{username} passed!" if @flist;

    @flist ? return $info{username} : return 0;
}

sub uni_valid {
    my $args_ref = shift @_;
    my $fail = 0;
    my %info;
    my ($node, $num);

    until($node){
	$num = int rand 2000000000;
	if( &is_valid($num, $args_ref) ){
	    %info = &rtrv_info($num, $args_ref);
	    $node = $info{username};
	}else{
	    $fail++;
	    return ("", $fail) if $fail > 10000;
	}
    }

    return ($node, $fail);
} 

sub nbr_valid {
    my $node = shift @_;
    my $args_ref= shift @_;
    my @flist;
    my $cand;
    my $fail = 0;
    my $num;

    @flist = &rtrv_flist($node, $args_ref);
    die "no neigbors!\n" unless @flist;

    while(1){
	$num = int rand ($#flist + 1);
	return ($cand, $fail) if &is_valid($cand = $flist[$num], $args_ref);
	$fail++;
	return ("", $fail) if $fail > 10000;
    }
}
# my $br = &init_browser("jy03060001.cookies");

# say "$ARGV[0] is valid" if is_valid($ARGV[0], $br);

