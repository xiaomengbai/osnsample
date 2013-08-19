#!/usr/bin/perl 

use strict;
use warnings;
use 5.010;

use LWP 5.64;
use HTTP::Cookies;

use DBI;


use threads;
use Thread::Semaphore;

my $sem = Thread::Semaphore->new();

require "util.pl";

sub _rtrv_flist_fb 
{
    my $username = shift @_;
    my $args_ref = shift @_;
    my $browser  = ${$args_ref}{browser};

    die "no browser object!" unless $browser;

    my @flist;

    my $c_user = $1 if $browser->cookie_jar->as_string =~ /c_user=([0-9]+);/;

    my $url = "https://www.facebook.com/$username/friends";

    my $response = $browser->get($url);
    
    return () unless $response->is_success;

#    say $response->content;
    $_ = $response->content;

    return () unless /friendsTypeaheadResults/;

#    say "there exists friends-list";
    while ( s#https?://www\.facebook\.com/([^/]+)\?fref## ){
	push @flist, $1 unless (defined $flist[-1] and $flist[-1] eq $1);
    }


    while (1) {
	$_ = $response->content;

	$url = "/ajax/pagelet/generic.php/AllFriendsAppCollectionPagelet\?data={\"collection_token\":\"$1$2\",\"cursor\":\"$3\",\"tab_key\":\"friends\",\"profile_id\":\"$1\",\"overview\":false,\"ftid\":null,\"order\":null,\"sk\":\"friends\"}&__user=$c_user&__a=1&__req=1q" if /pagelet_timeline_app_collection_([^:]+)([^"]+)",[^,]*,"([^"]*)"\]/;

	$url =~ s/{/%7B/g; $url =~ s/}/%7D/g; $url =~ s/"/%22/g; $url =~ s/:/%3A/g; $url =~ s/,/%2C/g;
	$url = "https://www.facebook.com" . $url;

	$response = $browser->get($url);
	
	return @flist unless $response->is_success;
	
	$_ = $response->content;

	while ( s#https:\\/\\/www\.facebook\.com\\/([^/]+)\?fref## ){
	    push @flist, $1 unless $flist[$#flist] eq $1;
	}
    }

}

sub _rtrv_flist_db 
{
    my $username = shift @_;
    my $args_ref = shift @_;
    my @flist;

    $sem->down();
    (my $dbh = &connect_db($args_ref) ) || ($sem->up() and return @flist);
    $sem->up();

    my $sth = $dbh->prepare("SELECT frndlist FROM users WHERE username = \"$username\" AND DATE_SUB(NOW(), INTERVAL 15 DAY) < ts_frnd;");
    $sth->execute or die "SQL Error: $DBI::errstr\n";
    
    return @flist unless $sth->rows == 1;

    my @row = $sth->fetchrow_array;

    $sth->finish();
    $dbh->disconnect();

    @flist = split /,/, $row[0] if defined $row[0] and $row[0] =~ /[^\d,]/;

    return @flist;
}

# _put_flist_db $username @flist
sub _put_flist_db
{
    my $username = shift @_;
    my $args_ref = shift @_;
    my $flist = join ",", @_;

    $sem->down();
    (my $dbh = &connect_db($args_ref) ) || ($sem->up() and return);
    $sem->up();

    $dbh->do("INSERT INTO users (username, frndlist, ts_frnd) VALUES ('$username', '$flist', NOW())") 
	or $dbh->do("UPDATE users SET frndlist='$flist', ts_frnd=NOW() where username='$username'");

    $dbh->disconnect();
}

# my $usr = "oooxxx";
# my @fl = (qw/xiao meng bai/);
# &_put_flist_db ($usr, (@fl));
#my @f_list = &_rtrv_flist_db("oooxxx");
#print "@f_list\n" ;
# my @f_list = &_rtrv_flist_fb($ARGV[0], $ARGV[1]);
# @f_list ? print "@f_list \ntotal: ", $#f_list + 1 : print "null\n"; 
