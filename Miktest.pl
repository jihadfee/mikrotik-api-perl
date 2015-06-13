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
my $c;

my $host = '192.168.25.177';
my $username = 'admin';
my $password = 'letmein';

my $command;
my @query;
my $proplist;

($socklocal,$status,$rep) = Mikrotik_Connect ($host,$username,$password);
if ($status)
{
	print "\nShow how to use PING with attrib\n\n";

	$command = "/ping";
	my $address = '4.2.2.2';
	%attrib = (
		'address' => $address,
		'count' => '2'
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
		if ( defined $rep{$key}{'status'})
		{
			print "Request timeout for icmp_seq $rep{$key}{'seq'}\n";
		}
		else
		{
			print"$rep{$key}{'size'} bytes from $address \($rep{$key}{'host'}\): icmp_req=$rep{$key}{'seq'} ttl=$rep{$key}{'ttl'} time=$rep{$key}{'time'}\n";
		}
	}

	print "\nPING with out waiting\n";

	my $noret = 1;

	$command = "/ping";
	$address = '4.2.2.2';
	%attrib = (
		'address' => $address,
	);

	Mikrotik_Command ($socklocal,$command);
	Mikrotik_Attrib ($socklocal,\%attrib);
	($status, $rep) = Mikrotik_Execute($socklocal,$noret);

	for ($c = 1; $c <= 3; $c++)
	{	
 			($status, $rep) = Mikrotik_readSingle($socklocal,$c);
 			%rep = %{$rep};
 			if ($c == 1) {	print "PING $address \($rep{$c}{'host'}\) $rep{$c}{'size'} bytes of data\n"; }
			if ( defined $rep{$c}{'status'})
			{
				print "Request timeout for icmp_seq $rep{$c}{'seq'}\n";
			}
			else
			{
 				print"$rep{$c}{'size'} bytes from $address \($rep{$c}{'host'}\): icmp_req=$rep{$c}{'seq'} ttl=$rep{$c}{'ttl'} time=$rep{$c}{'time'}\n";
			}
	}
	
 	Mikrotik_print(Mikrotik_Cancel ($socklocal));	
		
	print "\nPING with tag and with out waiting\n";

	$command = "/ping";
	$address = 'www.yahoo.com';
	%attrib = (
		'address' => $address,
 	);

 	Mikrotik_Command ($socklocal,$command);
 	Mikrotik_Attrib ($socklocal,\%attrib);
 	Mikrotik_tag ($socklocal,'22');
 	($status, $rep) = Mikrotik_Execute($socklocal,$noret);

 	for ($c = 1; $c <= 3; $c++)
 	{	
			($status, $rep) = Mikrotik_readSingle($socklocal,$c);
			%rep = %{$rep};
 			if ($c == 1) {	print "PING $address \($rep{$c}{'host'}\) $rep{$c}{'size'} bytes of data\n"; }		
 
 			if ($rep{$c}{'.tag'} eq '22')
 			{
 				if ( defined $rep{$c}{'status'})
 				{
 					print "Request timeout for icmp_seq $rep{$c}{'seq'}\n";
 				}
 				else
 				{
 					print"$rep{$c}{'size'} bytes from $address \($rep{$c}{'host'}\): icmp_req=$rep{$c}{'seq'} ttl=$rep{$c}{'ttl'} time=$rep{$c}{'time'}\n";
 				}
 			}
 	}
 	
 	Mikrotik_print(Mikrotik_Cancel ($socklocal,'22'));
 
 	print "\n\nShow how to add and Item\n\n";
	
	$command = "/interface/vlan/add";
	%attrib = (
		'interface' => 'ether4',
		'vlan-id' => '10',
		'name' => 'vlan10'
	);

	Mikrotik_Command ($socklocal,$command);
	Mikrotik_Attrib($socklocal,\%attrib);
	Mikrotik_print(Mikrotik_Execute($socklocal));	

	print "\n\nShow how to use print with Query and proplist\n\n";

	$command = "/interface/print";
	@query = ("type=vlan");
	$proplist = ("name,.id,mac-address");
	
	Mikrotik_Command ($socklocal,$command);
	Mikrotik_Query ($socklocal,\@query);
	Mikrotik_proplist($socklocal,$proplist);
	($status, $rep) = Mikrotik_Execute($socklocal);

	Mikrotik_print($status, $rep);
 
	%rep = %{$rep};
 
 	print "\n\nShow how to remove Item $rep{1}{'name'} $rep{1}{'.id'} \n\n";
 	
 	$command = "/interface/vlan/remove";
 	%attrib = (
		'.id' => $rep{1}{'.id'}
	);

	Mikrotik_Command ($socklocal,$command);
	Mikrotik_Attrib($socklocal,\%attrib);
	Mikrotik_print(Mikrotik_Execute($socklocal));


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

