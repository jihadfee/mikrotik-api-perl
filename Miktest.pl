#! /usr/bin/perl -w

use strict;
use mikrotik;


my $socklocal;
my $status;
my $rep;
my %rep;
my %attrib;
my $key;
my @keys;

my $host = '192.168.25.177';
my $username = 'admin';
my $password = 'letmein';

($socklocal,$status,$rep) = Mikrotik_Connect ($host,$username,$password);
if ($status)
{
	print "Show how to use print with Query and proplist\n\n";

	my $command = "/interface/print";
	my @query = ("type=vlan");
	my $proplist = ("name,.id,mac-address");
	
	Mikrotik_Command ($socklocal,$command);
	Mikrotik_Query ($socklocal,\@query);
	Mikrotik_proplist($socklocal,$proplist);
	Mikrotik_print(Mikrotik_Execute($socklocal));


	print "\nShow how to use PING with attrib\n\n";

	$command = "/ping";
	my $address = 'www.google.com';
	%attrib = (
		'address' => $address,
		'count' => '5'
	);

	Mikrotik_Command ($socklocal,$command);
	Mikrotik_Attrib ($socklocal,\%attrib);
	($status, $rep) = Mikrotik_Execute($socklocal);


	%rep = %{$rep};
	@keys = (keys %rep);	

	@keys = sort {$a <=> $b} @keys;
	
	print "PING $address \($rep{1}{'host'}\) $rep{1}{'size'} bytes of data\n";

	foreach $key (@keys)
	{
		print"$rep{$key}{'size'} bytes from $address \($rep{$key}{'host'}\): icmp_req=$rep{$key}{'seq'} ttl=$rep{$key}{'ttl'} time=$rep{$key}{'time'}\n";
	}



	Mikrotik_Close($socklocal);
}
else
{
		%rep = %{$rep};
		@keys = sort(keys %rep);
  		foreach $key (@keys)
		{
			print "$key = $rep{$key}\n";
		}
}

