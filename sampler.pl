#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use threads;
use threads::shared;

use Thread::Queue;

my $q = Thread::Queue->new();
my $TERM :shared = 0;

require 'util_cookies.pl';
require 'is_valid.pl';


die "$0 CONFIG_FILE" if @ARGV != 1;

my $configfile = $ARGV[0];
open CONFIG, "<",  $configfile or die "$configfile: $!";

# read config file
my %args;
while (<CONFIG>) {
    $args{$1} = $2 if /^\s*([^\s#]+)\s*=\s*([^\s]+)($|\s+.*$)/;
}


# init output file
$args{output} = "nodes.steps" unless $args{output};
sub _create_not_exist {
    my $filename = shift @_;
    unless( -e $filename ){
	open FILE, ">$filename" or die "cannot create file $args{output}";
	close FILE;
    }
}
&_create_not_exist($args{output});
my @nodes = &read_nodes($args{output});

# starting nodes;
my @snodes;

# set interruption function

$SIG{INT} = \&clear_func;

# init cookies file
&init_cookies(\%args);
sub _update_cookies {
    unless ( &inc_cookies(\%args) ) {
#	my $cookies = &avail_cookies(\%args) or (say "no available cookies" and &clear_func);
	my $cookies;
	&refresh_cookies(\%args) until $cookies = &avail_cookies(\%args);
	say "switch cookies from $args{cookies_in_use} to $cookies";
	&set_cookies(\%args, $cookies);
	&reload_browser(\%args);
	sleep 1 * 60;
    }
}
# $SIG{ALRM} = \&cookies_timer;
# alarm 3600;
# init browser
&init_browser(\%args);

#debug
say "$_ => $args{$_}" for (keys %args);
say "=== cooies_cont ===";
say "$_ => $args{cookies_cont}->{$_}" for (keys %{$args{cookies_cont}});

if ($args{method} =~ /\buni\b/){
    say "uniform sampling...";
    print $args{steps} - @nodes . " remains\n";
    # thread number is the smaller value between args 'thread' and remaining nodes
    my $t_nr = $args{thread} > ($args{steps} - @nodes) ? ($args{steps} - @nodes) : $args{thread};
    if ($t_nr > 1){
	threads->new(\&uni_worker, \%args) for (1..$t_nr);
    }
	
    while ( $args{steps} - @nodes > 0 ){
	my ($node, $fail);

	if ($t_nr > 1){
	    $node = $q->dequeue();
	    $fail = $q->dequeue();
	}else{
	    ($node, $fail) = &uni_valid(\%args);
	}

	warn "some thread failed too many times: $fail" and &clear_func unless $node;
	
	push @nodes, $node;
	$args{unifail} += $fail;
	$args{unisuccess}++;
	say "$node found valid!";
	
	&_update_cookies;
    }
}elsif ($args{method} =~ /\bfs\b/){
    say "frontier sampling...";
    say "-Load starting nodes...";
    # check snodes
    $args{sfile} = "snodes.list" unless $args{sfile};
    &_create_not_exist($args{sfile});
    @snodes = &read_nodes($args{sfile});

    print $args{snodes_nr} - @snodes . " more starting nodes needed\n";
    # thread number is the smaller value between args 'thread' and remaining nodes
    my $t_nr = $args{thread} > ($args{snodes_nr} - @snodes) ? ($args{snodes_nr} - @snodes) : $args{thread};
    if ($t_nr > 1){
	threads->new(\&uni_worker, \%args) for (1..$t_nr);
    }

    while ($args{snodes_nr} - @snodes > 0) {
	my ($node, $fail);

	if ($t_nr > 1){
	    $node = $q->dequeue();
	    $fail = $q->dequeue();
	}else{
	    ($node, $fail) = &uni_valid(\%args);
	}

	warn "some thread failed too many times: $fail" and &clear_func unless $node;
	
	push @snodes, $node;
	$args{unifail} += $fail;
	$args{unisuccess}++;
	say "$node found valid!";
	
	&_update_cookies;
    }
    &wait_threads;
    say "-sampling...";

    my %snode_edges;
    $snode_edges{$_} = &rtrv_flist($_, \%args) for (@snodes);

    my $sum;
    $sum += $snode_edges{$_} for (@snodes);
    print $args{steps} - @nodes . " remains\n";
    while ( $args{steps} - @nodes > 0) {
	my $rand = int rand $sum;
	my ($victim, $v_idx, $next, $fail);

	for(0..$#snodes) {
	    ($v_idx, $victim) = ($_, $snodes[$_]);
	    $rand -= $snode_edges{$victim};
	    last if $rand <= 0;
	}
	say "victim $victim found!";

	($next, $fail) = &nbr_valid($victim, \%args);
	warn "fail too many times in fetching $victim 's valid neighbor" and &clear_func unless $next;

	push @nodes, $victim;
	print "valid neighbor $next is found!\n";

	$args{nbrfail} += $fail;
	$args{nbrsuccess}++;

	$snodes[$v_idx] = $next;
	$snode_edges{$next} = &rtrv_flist($next, \%args);
	$sum = $sum - $snode_edges{$victim} + $snode_edges{$next};

	&_update_cookies;
    }
}elsif($args{method} =~ /\brw\b/){
    say "random-walk sampling...";
    print $args{steps} - @nodes . " remains\n";
    while ( $args{steps} - @nodes > 0 ){
	my ($node, $fail);

	($node, $fail) = @nodes ? &nbr_valid($nodes[$#nodes], \%args) : &uni_valid(\%args);
	warn "fail too many times in fetching valid node" and &clear_func unless $node;

	push @nodes, $node;
	say "$node found valid!";

	$args{nbrfail} += $fail;
	$args{nbrsuccess}++;

	&_update_cookies;
    }
}elsif($args{method} =~ /\bord\b/){
    say "Sampling in order...";
    my %info = rtrv_info($nodes[$#nodes], \%args) if @nodes;
    my $start = defined $info{id} ? $info{id} + 1 : $args{order_st};
    $start = ($start < $args{order_st} or $start >= $args{order_ed}) ? $args{order_st} : $start;
    say "starting at $start [$args{order_st}-$args{order_ed}]";

# # debug
#     my $node = &is_valid(5605, \%args);
#     say $node;
#     exit;
    while ($start < $args{order_ed}){
	my $node;
	push @nodes, $node if ($node = &is_valid($start, \%args));
	say "$node [$start] valid is found!" if $node;
	say "nothing in $start";

	$start++;
	&_update_cookies if $node;
    }
	
}else{
    die "Unkown sampling method $args{method}";
}
say "job done...";
&clear_func;
sub uni_worker {
    my $args_ref = shift @_;
    until(0){
	my ($node, $fail);
	($node, $fail) = &uni_valid($args_ref);
	$TERM ? return ($node, $fail) : $q->enqueue(($node, $fail));
    }
}


sub wait_threads {
    $TERM = 1;
    $_->join() foreach threads->list();
}

sub cookies_timer {
    &refresh_cookies(\%args);
    alarm 60 * 60;
}

sub clear_func{
    say "Try terminating threads...";
    &wait_threads;
    say "write result to file...";
    &write_nodes($args{output}, @nodes) if @nodes;
    &write_nodes($args{sfile}, @snodes) if @snodes;
    say "done!";
    printf("%d nodes (acc: %.2f%%) sampled uniformly\n", $args{unisuccess}, $args{unisuccess} / ($args{unisuccess} + $args{unifail}) * 100) 
	if defined $args{unifail} and defined $args{unisuccess};
    printf("%d nodes (acc: %.2f%%) sampled neighborly\n", $args{nbrsuccess}, $args{nbrsuccess} / ($args{nbrsuccess} + $args{nbrfail}) * 100) 
	if defined $args{nbrfail} and defined $args{nbrsuccess};
    say "starting nodes file: $args{sfile}" if defined $args{sfile};
    say "output file: $args{output}";
    exit;
}





