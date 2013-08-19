#!/usr/bin/perl

use strict;
use warnings;
use 5.010;



sub avail_cookies {
    my $args_ref = shift @_;

    return 0 unless (keys %{${$args_ref}{cookies_cont}});

    for (keys %{${$args_ref}{cookies_cont}}){
	return $_ if ${${$args_ref}{cookies_cont}}{$_} < ${$args_ref}{cookies_bound};
    }
    return 0;
}

sub refresh_cookies {
    my $args_ref = shift @_;

    ${${$args_ref}{cookies_cont}}{$_} = 0 for (keys %{${$args_ref}{cookies_cont}});
}

sub set_cookies {
    my $args_ref = shift @_;
    my $cur_cookies = shift @_;

    ${$args_ref}{cookies_in_use} = $cur_cookies;
}

sub inc_cookies {
    my $args_ref = shift @_;
    my $cur_cookies = ${$args_ref}{cookies_in_use};

    return 0 unless defined $cur_cookies;
    my $count = ++${${$args_ref}{cookies_cont}}{$cur_cookies};
    return $count > ${$args_ref}{cookies_bound} ? 0 : $count;
}

sub max_cookies {
    my $args_ref = shift @_;
    my $cookies = shift @_;

    ${${$args_ref}{cookies_cont}}{$cookies} = ${$args_ref}{cookies_bound};
}

sub max_cur_cookies{
    my $args_ref = shift @_;
    my $cookies = ${$args_ref}{cookies_in_use};

    &max_cookies($args_ref, $cookies);
}

sub init_cookies {
    my $args_ref = shift @_;
    my %cookies_cont;
    my $cookies;

    ${$args_ref}{cookies_bound} = 30 unless ${$args_ref}{cookies_bound};
    ${$args_ref}{cookies_cont} = \%cookies_cont;
    ${$args_ref}{cookies_cont}->{$_} = 0 for (split /,/, ${$args_ref}{cookies_files});
    
    $cookies = &avail_cookies($args_ref) or die "can't find available cookies";
    &set_cookies($args_ref, $cookies);
}

1;
