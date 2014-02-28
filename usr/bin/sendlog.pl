#!/usr/bin/env perl

use strict;
use warnings;
use HTTP::Tiny;
use Env qw(MACADDR);
use POSIX qw(strftime);
print "INFO: Initializing\n";

my $debug = 1;
my $http;
my $api_url = 'http://ghetto.sh/roadsign.txt';
my $response;
my $api_target;
my $api_command;
my $date = strftime "%s", localtime;
my $return_message;
my $apicall;

my $message = shift or die "FATAL: no message specified\n";

# quick sanitization
$message =~ s/\s+/_/g; 
$message =~ s/>/%3E/g;
$message =~ s/\n/%0D%0A/g;
$message =~ s/\|/%7C/g; 

$http = HTTP::Tiny->new();
$response = $http->get($api_url);

$api_target = $response->{content}; chomp($api_target);
$api_command = "/checkin?message=$message&macaddr=$MACADDR&date=$date";
$apicall = $api_target.'/'.$api_command;

if ($debug) { print "INFO: Detected target as: $api_target\n"; }
if ($debug) { print "INFO: Sending message $message using MAC: $MACADDR\n"; }
if ($debug) { print "INFO: Full URL -> $apicall\n" }

$response = $http->get($apicall);
print $response->{content};
print $response->{status};
print $response->{headers};
