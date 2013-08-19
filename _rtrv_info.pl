#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use LWP 5.64;
use HTTP::Cookies;

use DBI;

use threads;
use Thread::Semaphore;

require "util.pl";

my $sem = Thread::Semaphore->new();

sub _rtrv_info_fb {
    my $target = shift @_;
    my $args_ref = shift @_;
    my $browser = ${$args_ref}{browser};
    my %info;

    my $url="https://graph.facebook.com/" . $target;

    my $response = $browser->get($url);

    return () unless $response->is_success;

    $_ = $response->content;

    while (s/("[^"]+?")[^"]+?("[^"]+?")//){
	my ($k, $v)= ($1, $2);
	$k =~ s/"//g, $v =~ s/"//g if $k =~ /"username"/ or $k =~ /"id"/;
	$info{$k} = $v;
    }

    $_ = $response->content;

    if(/Application request limit reached/){
	$info{error} = "request limited";
    }
    return %info if (defined $info{error});
    return () unless (defined $info{username} and defined $info{id});

    return %info;
}

sub _rtrv_info_db {

    my ($id, $username);
    my %info;
    $_ = shift @_, /^\d+$/ ? $info{id} = $_ : $info{username} = $_;

    my $args_ref = shift @_;


    $sem->down();
    (my $dbh = &connect_db($args_ref) ) || ($sem->up() and return ());
    $sem->up();

    my $sql = "SELECT userid, username, basicinfo FROM users WHERE ";
    $sql .= defined $info{id} ? "userid = $info{id};" : "username = '$info{username}';";

    my $sth = $dbh->prepare($sql);
    $sth->execute or die "SQL Error: $DBI::errstr\n";
    
    return () unless $sth->rows == 1;

    my @row = $sth->fetchrow_array;

    $sth->finish();
    $dbh->disconnect();

    return () unless ($row[0] != 0 and defined $row[2]);

    for (split(/,/, $row[2])) {
	$info{$1} = $2 if /("[^"]+")=("[^"]+")/;
    }
    $info{id} = $row[0];
    $info{username} = $row[1];

    return %info;
}

sub _put_info_db {
    my $info_ref = shift @_;
    my $args_ref = shift @_;

    #return unless (defined $info_ref->{username} and defined $info_ref
    $sem->down();
    (my $dbh = &connect_db($args_ref)) || ($sem->up() and return);
    $sem->up();

    my $basicinfo;
    my $username = $info_ref->{username};
    my $id = $info_ref->{id};

    # print "username: $username\n";
    # print "id: $id\n";
    for (keys %$info_ref) {
	next if (/^username$/ or /^id$/);
	$basicinfo .= $_ . "=" . $info_ref->{$_} . "," if defined $info_ref->{$_};
    }
    return unless $basicinfo;
    $basicinfo =~ s/,$//;

    $dbh->do("INSERT INTO users (userid, username, basicinfo, ts_info) VALUES ('$username', $id, '$basicinfo', NOW());") 
	or $dbh->do("UPDATE users SET userid=$id, basicinfo='$basicinfo', ts_info = NOW() where username='$username';");

    $dbh->disconnect();
}


# my $br = &init_browser($ARGV[1]);
# my %info = &_rtrv_info_fb($ARGV[0], $br);

# for (keys %info) {
#     print "$_ : $info{$_}\n";
# }


# &_put_info_db(\%info);

# my %info2 = &_rtrv_info_db($ARGV[0]);

# for (keys %info2) {
#     print "$_ : $info2{$_}\n";
# }

