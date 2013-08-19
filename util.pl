#!/bin/perl

use 5.010;
use warnings;
use strict;

use LWP 5.64;
use HTTP::Cookies;

use DBI;

sub connect_db {
    my $args_ref = shift @_;

    my @db_args = (${$args_ref}{db_source}, ${$args_ref}{db_user}, ${$args_ref}{db_pass});

    (my $dbh = DBI->connect(@db_args, { PrintError => 0, })) or say "can not connect to $db_args[0]";# and say "DB Connected";
#    (my $dbh = DBI->connect(@db_args));# and say "DB Connected";

    return $dbh;
}

sub init_browser {
    my $args = shift @_;
    my $cookie_file = ${$args}{cookies_in_use};

    my $cookie_jar =  HTTP::Cookies->new(
	file => $cookie_file,
	ignore_discard => 1,
	autosave => 1,
	);

    my $browser = LWP::UserAgent->new;

    $browser->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20100101 Firefox/21.0');
    $browser->cookie_jar($cookie_jar);

    ${$args}{browser} = $browser;
}

sub reload_browser {
    my $args = shift @_;
    my $browser = ${$args}{browser};
    my $cookie_file = ${$args}{cookies_in_use};

#    $browser = init_browser
    $browser->cookie_jar->load($cookie_file) or die "load cookie files $cookie_file error!";
}

sub read_nodes {
    my $filename = shift @_;
    my @nodes;
    
    open NODES, "+<", $filename or die "$!: $filename ";
    while(<NODES>){
	chomp;
	push @nodes, $_;
    }
    close NODES;
    return @nodes;
}

sub write_nodes {
    my $filename = shift @_;
    my @nodes = @_;

    open NODES, ">",  $filename or die $!;
    print NODES "$_\n" for (@nodes);
    close NODES;
}

sub append_node {
    my $filename = shift @_;
    my $node = shift @_;

    open NODE, ">>", $filename or die $!;
    print NODE "$node\n";
    close NODE;
}

1;


