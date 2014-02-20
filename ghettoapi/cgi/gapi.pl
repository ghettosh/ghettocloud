#!/usr/bin/env perl

use CGI qw(:standard);

##### my $querystr;
##### my @entry;
##### my %inputdata;
##### my $key;
##### my $value;
##### print "Content-type: text/plain\n\n";
##### $querystr = $ENV{'QUERY_STRING'};
##### $querystr =~ s|#||g;
##### @entry = split(/&/,$querystr);
##### 
##### foreach (@entry) {
#####   ($key,$value) = split(/=/);
#####   $value =~ s/%20/_/g;
#####   $inputdata{$key} = $value;
##### }
##### 
##### while (($key, $value) = each(%inputdata)){
#####      print $key . " ==> " . $value . "\n";
##### }

print "Content-type: text/plain\n\n";
my $q=CGI->new;
my $params = $q->Vars;
print $params->{'message'};
