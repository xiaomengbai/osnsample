#!/usr/bin/perl

use 5.010;
use warnings;
use strict;
use LWP 5.64;
use HTTP::Cookies;

$#ARGV == 1 or die "get-cookies.pl username password "; 

my $cookie_file = $ARGV[0];
$cookie_file =~ s/^(.*)@.*/$1.cookies/g;
my $cookie_jar =  HTTP::Cookies->new(
    file => "$cookie_file",
    ignore_discard => 1,
    autosave => 1,
    );

my $browser = LWP::UserAgent->new;

$browser->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20100101 Firefox/21.0');
$browser->cookie_jar($cookie_jar);

my $url = 'https://www.facebook.com/';

my $response = $browser->get($url);

die "Can't get $url -- ", $response->status_line unless $response->is_success;

my @post_data;

foreach (qw/lsd default_persistent timezone lgnrnd locale/) {
    $1 and push @post_data, ($_, $1) if ( $response->content =~ /.*<input[^>]*name="$_" value="([^"]*)"[^>]*>.*/); 
}

push @post_data, ('email', $ARGV[0]);
push @post_data, ('pass', $ARGV[1]);
$post_data[3] = 'en_US';

$url = "https://www.facebook.com/login.php?login_attempt=1";
$response = $browser->post($url, [
			       (@post_data)
			   ]);

# if ( 1 ) {
#     # print $response->request->as_string;
#     # print $response->as_string;
#     # $cookie_jar->extract_cookies($response);
#     print $cookie_jar->as_string;
# $cookie_jar->save();
# }
# $cookie_jar->extract_cookies($response);

($cookie_jar->as_string =~ /c_user/) or die "Get Cookie File failed!";

say "Cookie File: $cookie_file";
