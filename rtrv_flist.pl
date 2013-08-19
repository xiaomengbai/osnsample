#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

require '_rtrv_flist.pl';

sub rtrv_flist {
    my $username = shift @_;
    my $args_ref = shift @_; # &init_browser("jy03060001.cookies");
    my @flist;

    unless(@flist = &_rtrv_flist_db($username, $args_ref)){
	@flist = &_rtrv_flist_fb($username, $args_ref);
	&_put_flist_db($username, $args_ref, (@flist)) if @flist;
    }

    return @flist;
}

# (my @list = &rtrv_flist($ARGV[0])) or die "I can't retrieve $ARGV[0]'s friend-list";
# say "@list";
