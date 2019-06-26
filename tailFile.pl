#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Cwd;


# Setup Signals
my %sig = ( HUP => 0, ABRT => 0, USR1 => 0, USR2 => 0, CONT => 0 );

sub getSig{
	my $name = shift;
	return $sig{$name};
}

sub resetSig{
	my $name = shift;
	$sig{$name} = 0;
}

sub setupSignals {
	my $config = shift;
	$config->{signals} = \%sig;
	$SIG{HUP}  = sub {$sig{HUP} = 1};
	$SIG{ABRT} = sub {$sig{ABRT} = 1};
	$SIG{USR1} = sub {$sig{USR1} = 1};
	$SIG{USR2} = sub {$sig{USR2} = 1};
	$SIG{CONT} = sub {$sig{CONT} = 1};
}	# setupSignals

sub processSignals{
	if ( getSig('HUP')) {
 		resetSig('HUP');
		warn "Received HUP"; 		
 	}	
 	if ( getSig('USR1')) {
 		resetSig('USR1');
		warn "Received USR1"; 		 		
 	}
 	if ( getSig('USR2')) {
 		resetSig('USR2');
		warn "Received USR2"; 		 		
 	}
}	#	processSignals

sub getFile {
	my ($names,$idx) = @_;
	my $maxIdx = -1;
	my $maxName = '';
		
	my @fileNames = glob($names);
	foreach my $fname (@fileNames) {
		my @fields = split(/\./,$fname);
		$maxName = $fname if ($fields[$idx] > $maxIdx);
		$maxIdx = $idx if ($fields[$idx] > $maxIdx);
	}
	return($maxName);
}	# getFile
	

my %options=();
getopts("hf:e:", \%options);
if (defined $options{h})	{
	print "Usage: tailFile.pl -f 'fname' -e n [0 based index of sort]\n";
	exit;
}
my $config;
setupSignals($config);
my $dir = getcwd();

my ($idx,$names,$fname) = (0,"$dir/*",'');
$names = "$options{f}" if defined($options{f});
$idx = $options{e} if (defined($options{e}));
$fname = getFile($names,$idx);
my $prevFname = '';
my $fh;	

while( getSig('ABRT') == 0) {
	processSignals();
	if ($fname ne $prevFname) {
		close($fh) if defined($fh);
		if ( open $fh, "/usr/bin/tail -f $fname |" ) {
			my $oldfh = select($fh); # default
			$| = 1;
			select($oldfh);
			$prevFname = $fname;
		} else {
			warn "Unable to to open $fname\n$!\n";
			sleep(5);
		}
	}
	if (eof $fh){
		# No data on file handle, check for a new file
		$fname = getFile($names,$idx);
		sleep(1) if ($fname eq $prevFname);
	} else {
		print <$fh>;
	}
}

1;


