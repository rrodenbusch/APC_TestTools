#!/usr/bin/perl
use strict;
use warnings;

use Cwd qw(cwd);
use Time::Local;
use Getopt::Std;
use Date::Format;

my @fTypes = ('rLog','voltage','status','Watch');
my %fNames = ( 'rLog'=>'data/rLog/remote*.log*"',
               'Watch'=> '/home/pi/Watch.*',
               'voltage'=> '/home/pi/I2C/i2cdata/voltage/Voltage*.csv*',
               'status' => '/home/pi/I2C/i2cdata/status/*SystemStatus.csv*' );
      

my $USAGE = "Usage: scourLogs.pl\n".
                  "   -s Start epoch        [default now]\n".
                  "   -d Duration (seconds) [default 1 hr]\n".
                  "   -H Duration (Hours)\n".
                  "   -c coach # \n".
                  "   -h help\n" ;

sub getCmdLine {
   my ($dateStr);
   my %options=();
   
   getopts("hs:d:H:c:", \%options);
   if ( defined($options{h}) ) {
      die $USAGE;
   } 
   $options{coach} = 'TBD';
   $options{coach} = $options{c} if defined($options{c});
   if (defined($options{s}) ) {
      $options{start} = $options{s} if defined($options{s});
      $options{end}   = $options{start} + $options{d} if defined($options{d});
      $options{end}   = $options{start} + 3600 * $options{H} if defined($options{H});
      $options{end} = $options{e} if defined($options{e});
   } else {
      $options{end} = time();
      $options{start} = $options{end} - 3600;
      $options{start} = $options{end} - $options{d} if defined($options{d});
      $options{start} = $options{end} - 3600 * $options{H} if defined($options{H});
   }

   return(\%options);
}  #getCmdLine

sub getMAC  {
   my $return = `ip addr sh eth0 |grep link/ether`;
   my @flds = split(' ',$return);
   my $mac = $flds[1];
   $mac =~ s/://g;
   $mac = uc($mac);
   return($mac);
}

sub getFlist {
   my $fname = shift;
   my @flist=glob($fname);
   
   return (\@flist);
}  # getFlist

sub scourFile {
   my ($config,$curType,$fname) = @_;
   my ($start,$end) = ($config->{start},$config->{end});
   my @lines;
   if (substr($fname,-2) eq 'gz') {
      return(\@lines);
   }
   if (open(my $fh, $fname) ) {
      while (my $line = <$fh>) {
         next if ($curType eq 'Watch') && (index($line,'Unable to connect') != 0);
         $line =~ s/\R//g;
         $line =~ s/^Unable to connect log: //g;
         my @flds = split(',',$line);
         my $logtime = $flds[0];
         $logtime =~ s/ //g;
         next unless ($logtime =~ /^[+-]?\d+$/);
         push (@lines,"$logtime,$config->{MAC},,$curType,$fname,$line") if (($logtime >= $start) && ($logtime <= $end) );
      }
   } else {
      print STDERR "Unable to open file $fname\t$!\n";
   }
   return(\@lines);
}  # scourFile

my $config = getCmdLine();
my $tmpName = time() . ".tmp";
die "Unable to open tmp file $tmpName\t$!" unless open(my $ofh,">$tmpName");
$config->{MAC} = getMAC();

print "Epoch,MAC,COACH,ID,fType,fName,Data\n";
my $dateStr = time2str("%c",$config->{start},'EST');
print $ofh "$config->{start},$config->{MAC} ,START,$dateStr EST\n";
my @Data;
foreach my $curType (@fTypes) {
   my $fList = getFlist($fNames{$curType});
   my $fCnt = scalar @{$fList};
   foreach my $fname (@{$fList}) {
         my $retList = scourFile($config,$curType,$fname);
         my $cnt = scalar @$retList;
         print "Found $cnt lines in $fname\n" if ($cnt > 0);
         push (@Data,@{$retList}) ;
         foreach my $myLine (@{$retList}) {
            print $ofh "$myLine\n";
         }
   }
}

$dateStr = time2str("%c",$config->{end},'EST');
print $ofh "$config->{end},$config->{MAC} ,END,$dateStr EST\n";
close $ofh;
my $outname = "$config->{MAC}.$config->{start}.$config->{end}.logs.csv";
`sort -k1 -t, $tmpName > $outname`;
`rm $tmpName`;
`gzip $outname`;

exit 0;

1;
