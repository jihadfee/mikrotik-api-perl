#! /usr/bin/perl -w
#--------------------------------------------------
#Script Name: Mikrotik.pm
#Script Version: 1.0
#Date: 01.05.2015
#Author: Jihad Jaafar
#Description: This Module Allow's the program to talk any Mikrotik router version 5 and above
#	
#
#
#
#Revision History
#	1.0/01.05.2015: original version
#--------------------------------------------------

package mikrotik;

use strict;
use warnings;
use IO::Socket;
use Digest::MD5;
use String::HexConvert ':all';

require Exporter;

our $VERSION ='1.0';

our @ISA = qw(Exporter);
our @EXPORT = qw(
			Mikrotik_Connect
			Mikrotik_Command
			Mikrotik_API_Attrib
			Mikrotik_tag
			Mikrotik_Attrib_tag
			Mikrotik_proplist
			Mikrotik_Attrib
			Mikrotik_Query
			Mikrotik_Execute
			Mikrotik_Cancel
			Mikrotik_Do
			Mikrotik_readSingle
			Mikrotik_readSentence
			Mikrotik_readWord
			Mikrotik_writeSentence
			Mikrotik_writeWord
			Mikrotik_print
			Mikrotik_Close
			Mikrotik_Set_DEBUG
			);
			
our @EXPORT_OK = qw(
			);

my $debug = 0;


#Establish a Connections with the Mikrotik Router
#INPUT host, username and Passward.
#
#RETURN a status of the connection
#Socket number to the USER if successful
#Error as a Reference to a hash if NOT successful

sub Mikrotik_Connect
{
	my $sock;
	my $host = $_[0];
	my $port = 8728;
	my $proto = 'tcp';
	my $username = $_[1];
	my $password = $_[2];
	my $ret;
	my @ret;
	my $chal;
	my $md5;
	my $digest;
	my @command;

	$sock = new IO::Socket::INET(
			PeerAddr => $host,
			PeerPort => $port,
			Proto	 => $proto) or die "Error Creating Socket : $!\n";
	
	push(@command, '/login');
	
	Mikrotik_writeSentence($sock,\@command);
	$ret = Mikrotik_readWord($sock);
	$ret = Mikrotik_readWord($sock);
	@ret = split /=/,$ret;

	$chal = pack("H*",$ret[2]);

	$md5 = new Digest::MD5;
	$md5->add(chr(0));
	$md5->add($password);
	$md5->add($chal);
	$digest = $md5->hexdigest;

	push(@command, '/login');
	push(@command, '=name=' . $username);
	push(@command, '=response=00' . $digest);

	return ($sock,Mikrotik_Do($sock,\@command));
}

#Write a Command to the router
#INPUT Socket and Scaler "String"
#
#RETURN NONE

sub Mikrotik_Command
{
	my $sock = $_[0];
	my $word = $_[1];
	Mikrotik_writeWord($sock,$word);
}

#Write API Attributes ".attribute=value" to the router
#INPUT Socket and Reference to a HASH
#
#RETURN NONE

sub Mikrotik_API_Attrib
{
	my $sock = $_[0];
	my %attrib = %{$_[1]};
	my $key;
	my $value;

	my @keys = keys %attrib;
	foreach $key (@keys)
	{
		$value = $attrib{$key};
		$value = "\.$key\=$value";
		Mikrotik_writeWord ($sock,$value);
	}
}

#Write a tag ".tag=value" to the router
#This is used for setting the tag for a command ie /ping
#INPUT Socket and Scaler "String"
#
#RETURN NONE

sub Mikrotik_tag
{
	my $sock = $_[0];
	my $tag = "\.tag\=$_[1]";
	Mikrotik_writeWord ($sock,$tag);
}

#Write a tag Attribute "=tag=value" to the router 
#This is used for the cancel command
#INPUT Socket and Scaler "String"
#
#RETURN NONE

sub Mikrotik_Attrib_tag
{
	my $sock = $_[0];
	my $tag = "\=tag\=$_[1]";
	Mikrotik_writeWord ($sock,$tag);
}

#Write a tag proplist "=.proplist=value" to the router 
#This is used the only send back the attributes you want for a command ie /interface/print =.proplist=name,.id,mac-address
#INPUT Socket and Scaler "String"
#
#RETURN NONE

sub Mikrotik_proplist
{
	my $sock = $_[0];
	my $value = "\=.proplist=$_[1]";
	Mikrotik_writeWord ($sock,$value);
}

#Write Attributes "=attribute=value" to the router
#INPUT Socket and Reference to a HASH
#
#RETURN NONE

sub Mikrotik_Attrib
{
	my $sock = $_[0];
	my %attrib = %{$_[1]};
	my $key;
	my $value;

	my @keys = keys %attrib;
	foreach $key (@keys)
	{
		$value = $attrib{$key};
		$value = "\=$key\=$value";
		Mikrotik_writeWord ($sock,$value);
	}
}

#Write Attributes "?Query" to the router
#This is used to only show the ITEM you want ie /interface/print ?type=vlan 
#INPUT Socket and Reference to a ARRAY
#
#RETURN NONE

sub Mikrotik_Query
{
	my $sock = $_[0];
	my @value = @{$_[1]};
	my $value;
	foreach $value (@value)
	{
		$value = "\?$value";
		Mikrotik_writeWord ($sock,$value);
	}
}

#Execute the Command, attribute, proplist, tag, Query
#INPUT Socket and Return if TURE "ie you put something return results"
#
#RETURN Status and reference to a HASH with the result's of the Command sent

sub Mikrotik_Execute
{
	my $sock = $_[0];
	Mikrotik_writeStr($sock,chr(0));
	if (!defined $_[1])
	{
		return (Mikrotik_readSentence($sock));
	}
}

#Execute a Cancel Command
#INPUT Socket and or a tag number
#
#RETURN Status and reference to a HASH with the result's of the Command sent


sub Mikrotik_Cancel
{
	my $sock = $_[0];
	my $dummy;
	my $tag;
	my $status;
	my $rep;
	my %rep;
	my @tag;
		
 	Mikrotik_Command ($sock,"/cancel");
 	if (defined $_[1])
	{
 		Mikrotik_Attrib_tag ($sock,$_[1]);
 	}
 	($status, $rep) = Mikrotik_Execute($sock);
 
 	$dummy = Mikrotik_readWord($sock);
	$tag   = Mikrotik_readWord($sock);
 	$dummy = Mikrotik_readWord($sock);
	$tag   = Mikrotik_readWord($sock);

 	if (defined $tag)
	{
		@tag = split /=/,$tag;
 		%rep = %{$rep};
 		$rep{'.tag'} = $tag[1];
 		$rep = \%rep;
 	}
	return ($status, $rep);  
}

#DO Execute a Command
#INPUT Socket and the Command ie "/print"
#
#RETURN Status and reference to a HASH with the result's of the Command sent

sub Mikrotik_Do
{
	my $sock = $_[0];
	my @command = @{$_[1]};
	Mikrotik_writeSentence($sock,\@command);
	return (Mikrotik_readSentence($sock));
}

#Read a Single Reply
#This is Used for when you want to control the receiving data
#INPUT Socket and the element "This makes it easier to natural count of item ie for /ping"
#
#RETURN Status and reference to a HASH with the result's of the Command sent

sub Mikrotik_readSingle
{
		my $sock = $_[0];
		my %sentence;
		my $word;
		my $key;
		my $dummy;
		my $value;
		my $status = 0;
		my $element = $_[1];


 		while (1)
 		{
 				$word = Mikrotik_readWord($sock);
 				if (not defined($word))
 				{
 					$status = 1;
 					last;
 				}
 				elsif ($word =~ /!re/)
				{
					next;
 				}
 				else
 				{	
 					if ($word =~ /.tag/)
 					{
 						($key,$value) = split /=/,$word;
 					}
 					else
 					{
 						($dummy,$key,$value) = split /=/,$word;
 					}

					$sentence{$element}{$key} = $value;
				}
 		}
 		return ($status, \%sentence);
}

#Read a Complete Reply until !done
#INPUT Socket
#
#RETURN Status and reference to a HASH with the result's of the Command sent
#ERROR if the status is "0" it will send you the Error on why the command failed

sub Mikrotik_readSentence
{
		my $sock = $_[0];
		my %sentence;
		my $word;
		my $key;
		my $dummy;
		my $value;
		my $status = 0;
		my $element = 0;


 		while (1)
 		{
 				$word = Mikrotik_readWord($sock);
 				if (not defined($word))
 				{
 					next;
 				}
 				elsif ($word =~ /!done/)
 				{
 					$status = 1;
 					last;
 				}
 				elsif ($word =~ /!re/)
				{
					$element++;
 				}
 				elsif ($word =~ /!trap/)
 				{
 					$word = Mikrotik_readWord($sock);

 					if ($word =~ /.tag/)
 					{
 						($key,$value) = split /=/,$word;
 						$sentence{$key} = $value;
 						$word = Mikrotik_readWord($sock);
 						($dummy,$key,$value) = split /=/,$word;
 					}
 					else
 					{
						($dummy,$key,$value) = split /=/,$word;
					}

 					if ($key =~ /category/)
 					{
						if    ($value == 0) { $value = 'Missing item or command'}
						elsif ($value == 1) { $value = 'Argument value failure'}
						elsif ($value == 2) { $value = 'Execution of command interrupted'}
						elsif ($value == 3) { $value = 'Scripting related failure'}
						elsif ($value == 4) { $value = 'General failure'}
						elsif ($value == 5) { $value = 'API related failure'}
						elsif ($value == 6) { $value = 'TTY related failure'}
						elsif ($value == 7) { $value = 'Value generated with :return command'}
						$sentence{$key} = $value;
					}
					else
					{
						$sentence{$key} = $value;
					}
									
 					$word = Mikrotik_readWord($sock);
					if (defined ($word))
					{
 						if ($word =~ /.tag/)
 						{
 							($key,$value) = split /=/,$word;
 						}
 						else
 						{
 							($dummy,$key,$value) = split /=/,$word;
						}
						$sentence{$key} = $value;
					}
					$status = 0;
					last;
 				}
 				else
 				{
 					if ($word =~ /.tag/)
 					{
 						($key,$value) = split /=/,$word;
 					}
 					else
 					{
 						($dummy,$key,$value) = split /=/,$word;
					}
					
					$sentence{$element}{$key} = $value;
				}
 		}
 		
 		$dummy = Mikrotik_readWord($sock);
 		
 		return ($status, \%sentence);
}

#Read a Word and length of the word ie a line
#INPUT Socket
#
#RETURN Scaler "String" 

sub Mikrotik_readWord
{
	my $sock = $_[0];
	my $word;
	my $len = Mikrotik_readLen($sock);
	if ($len > 0)
	{
		$word = Mikrotik_readstr($sock,$len);
		if ($debug != 0) { Mikrotik_DEBUG ($sock,$word,"R"); }
	}
	return $word;
}

#Read data form the router via the Socket
#INPUT Socket
#
#RETURN Scaler "String" 

sub Mikrotik_readstr
{
	my $sock = $_[0];
	my $data;
	$sock->recv($data,$_[1]);
	if ($debug == 5) { Mikrotik_FULL_DEBUG ($sock,$data,"R"); }
	return $data;
}

#Read the Length for the word form the router via the Socket
#INPUT Socket
#
#RETURN Scaler "number" 

sub Mikrotik_readLen 
{
	my $sock = $_[0];
	my $line;
	my $len;
	$sock->recv($line,1);
	$len = ord($line);
	if ($len & 0x80)
	{
		last;
	}
	elsif ($len & 0xC0 == 0x80)
	{
		$len &= !0xC0;
		$len <<= 8;
		$len += Mikrotik_readLen($sock);
	}
	elsif ($len & 0xE0 == 0xC0)
	{
		$len &= !0xE0;
		$len <<= 8;
		$len += Mikrotik_readLen($sock);
		$len <<=8;
		$len += Mikrotik_readLen($sock);
	}
	elsif ($len & 0xF0 == 0xE0)
	{
		$len &= !0xF0;
		$len <<= 8;
		$len += Mikrotik_readLen($sock);
		$len <<=8;
		$len += Mikrotik_readLen($sock);        
		$len <<=8;
		$len += Mikrotik_readLen($sock);       
	}
	elsif ($len & 0xF8 == 0xF0)
	{
		$len = Mikrotik_readLen($sock);
		$len <<= 8;
		$len += Mikrotik_readLen($sock);
		$len <<=8;
		$len += Mikrotik_readLen($sock);        
		$len <<=8;
		$len += Mikrotik_readLen($sock);    
	}
	if ($debug == 5) { Mikrotik_FULL_DEBUG ($sock,$len,"L"); }
	return $len;
}

#Write a Sentence to the Router
#INPUT Socket and Reference to an ARRAY 
#
#RETURN NONE

sub Mikrotik_writeSentence
{
	my $sock = $_[0];
	my @sentence = @{$_[1]};
	my $word;

 	foreach $word (@sentence)
 	{
 		Mikrotik_writeWord($sock,$word);
 	}
 	Mikrotik_writeStr($sock,chr(0));
}

#Write a word to the Router
#INPUT Socket and a Scaler "string"
#
#RETURN NONE

sub Mikrotik_writeWord
{
	my $sock = $_[0];
	my $word = $_[1];
	Mikrotik_writeLen($sock,$word);
	if ($debug != 0) { Mikrotik_DEBUG ($sock,$word,"W"); }	
	Mikrotik_writeStr($sock,$word);
}

#Write a string to the Router
#INPUT Socket and a Scaler "string"
#
#RETURN 0 if failed

sub Mikrotik_writeStr
{
	my $sock = $_[0];
	my $str = $_[1];
	if ($debug == 5) { Mikrotik_FULL_DEBUG ($sock,$str,"W"); }
	my $rev = $sock->send($str);
	if ($rev eq 0) { print "Error::No socket"}
}

#Write the Length to the route for a word
#INPUT Socket and Length
#
#RETURN NONE

sub Mikrotik_writeLen 
{
	my $sock = $_[0];
	my $len = length($_[1]);
    if ($len < 0x80)
    {
        Mikrotik_writeStr ($sock,chr($len));
    }
    elsif ($len < 0x4000)
    {
        $len |= 0x8000;
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr($len & 0xFF));
    }
    elsif ($len < 0x200000)
    {
        $len |= 0xC00000;
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr($len & 0xFF));
    }
    elsif ($len < 0x10000000)
    {
        $len |= 0xE0000000;
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr($len & 0xFF));
    }
    elsif ($len < 0x10000000)
    {
        $len |= 0xE0000000;
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr(($len >> 8) & 0xFF));
        Mikrotik_writeStr ($sock,chr($len & 0xFF));
    }
}
 
#Print a hash Result with the Status
#INPUT Socket and the Reference to a HASH
#
#RETURN NONE
 
sub Mikrotik_print
{
my $status = $_[0];
my $rep = $_[1];
my %rep;
my $key;
my @keys;
my $key2;
my @keys2;
my $value;

if ($status)
{
	%rep = %{$rep}; 
	@keys = (keys %rep);
	
	@keys = sort {$a <=> $b} @keys;
	
	foreach $key (@keys)
	{
		@keys2 = (keys $rep{$key});
		foreach $key2 (@keys2)
		{
			$value = $rep{$key}{$key2};
			print "$key:$key2 = $value\n";
		}
	}
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

}
 
#Close the Connection to the router
#INPUT Socket
#
#RETURN 0 if failed

sub Mikrotik_Close
{
	my $sock = $_[0];
	$sock->close() or return 0;		#Close Socket
}

#Print DEBUG info
#INPUT	1 Data 
#		2 HEX
#		3 SOCK:(W/R):Data
#		4 SOCK:(W/R):HEX
#RETURN NONE

sub Mikrotik_DEBUG
{
	my $dir;
	$_[0] =~ /(0x\w+)/;
	my $sock = $1;
	my $value = $_[1];
	if ( defined $_[2]) { $dir = $_[2] };
	
	if ($debug == 1)
	{
		print "$value\n";
	}
	elsif ($debug == 2)
	{
		my $text = ascii_to_hex($value);
		print "$text\n";
	}
	elsif ($debug == 3)
	{
		print "$sock:$dir:$value\n";
	}
	elsif ($debug == 4)
	{
		my $text = ascii_to_hex($value);
		print "$sock:$dir:$text\n";
	}
}

#Print DEBUG info
#INPUT	5 SOCK:(W/R/L):HEX
#RETURN NONE

sub Mikrotik_FULL_DEBUG
{
	$_[0] =~ /(0x\w+)/;
	my $sock = $1;
	my $value = $_[1];
	my $dir = $_[2];
	
	my $text = ascii_to_hex($value);
	if ($dir ne "L") { print "$sock:$dir:$text\n"; }
	print "$sock:$dir:$value\n";
}

#Set DEBUG LEVEL
#INPUT	1 Data 
#		2 HEX
#		3 SOCK:(W/R):Data
#		4 SOCK:(W/R):HEX
#		5 SOCK:(W/R/L):HEX 
#RETURN NONE

sub Mikrotik_Set_DEBUG
{
	if ($debug =~ m/[0-5]{1}/)
	{
		$debug = $_[0];
	}
}


1;