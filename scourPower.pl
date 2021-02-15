#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use Time::Local;
use Getopt::Std;
use Date::Format;

my @fTypes = ('rLog','voltage','Watch');
my %fNames = ( 'rLog'=>'/data/rLog/remote*.log*',
               'Watch'=> '/home/pi/Watch.*',
               'voltage'=> '/home/pi/I2C/i2cdata/voltage/Voltage*.csv*' );
      

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

   $options{H} = '45.17.125.128' unless defined($options{H});
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

sub getEvents {
   my ($config,$fname) = @_;
   my ($start,$end,$EID,$mac) = (0,0,'',$config->{MAC});
   my @Events;
   my @fLines;
   
   if (open(my $fh, $fname) ) {
      chomp(@fLines = <$fh>);
      close $fh;
   } else {
      print "Error opening $fname\$!\n";
   }
   foreach my $curLine (@fLines) {
      $curLine =~ s/\R//g;
      my @flds = split(',',$curLine);
      my $srcfile = $flds[4];
      my $epoch = shift(@flds);
      my $power = pop(@flds);
      if ($EID ne '') {
         # active event
         $end = $epoch;
         if ($power eq 'ON') {
            my $delta = $end - $start;
            push (@Events,"$start,$EID,$end,$delta,$srcfile,$fname");
            $EID = '';
            $start = $epoch;
         }
      } elsif ($power eq 'OFF') {
         # begin event
         $EID   = "$mac.$epoch";
         $start = $epoch;
         $end   = $start;
      }
   }
   return (\@Events);
}

sub getFlist {
   my $fname = shift;
   my @flist=glob($fname);
   
   return (\@flist);
}  # getFlist

sub scourVoltage {
   my ($config,$curType,$fname) = @_;
   my @lines;
   my @fLines;
   my $cnt = 0;
   
   print "Starting $fname\n";
   if (substr($fname,-2) eq 'gz') {
      @fLines = `gunzip -c $fname `;
   } else {
      @fLines = `cat $fname`;
   }
   my $recCnt = scalar @fLines;
   print " $recCnt records\n";
   my $prevLine = '';
   my $prevState = 'OFF';
   foreach my $line (@fLines) {
      $line =~ s/\R//g;
      my @flds = split(',',$line);
      my $logtime = $flds[0];
      next unless ($logtime =~ /^[+-]?\d+$/);
      $flds[2] = -1 unless defined($flds[2]);
      $flds[3] = -1 unless defined($flds[3]);
      next if ($flds[2] == -1) || ($flds[3] == -1);
      
#      $cnt = 3 unless ($flds[2] == -1) || ($flds[3] == -1) || ( $flds[2] < 14) || ($flds[2] >= $flds[3]);
      $cnt = 3 unless  ( $flds[3] > 14.6 ) || ( ($flds[3] > 14.0) && ($flds[2] >= $flds[3] + 0.275) );
      my $state='OFF';
      $state = 'ON' if ($cnt < 3);
      if ($cnt > 0) {
         push (@lines,"$logtime,$config->{MAC},,$curType,$fname,$prevLine,$state") if ($state eq 'OFF') && ($prevState eq 'ON');
         push (@lines,"$logtime,$config->{MAC},,$curType,$fname,$line,$state");
         $cnt--;         
      }
      $prevLine = $line;
      $prevState = $state;
   }
   $recCnt = scalar @lines;
   print "  $recCnt kept\n";
   return(\@lines);
}  # scourVoltage

sub scourFile {
   my ($config,$curType,$fname) = @_;
   my (@lines,@fLines,$fh); 
   my $cnt = 0; 
   
   print "Starting $fname\n";
   if (substr($fname,-2) eq 'gz') {
      `gunzip -c $fname >$fname.tmp`;
      open($fh,"$fname.tmp");
   } else {
      open($fh, $fname);
   }
   while (my $curLine = <$fh>) {
      $curLine =~ s/\R//g;
      my $tmpLine = uc($curLine);
      push (@fLines, $curLine) if (index($tmpLine,'POWER') > -1) || (index($tmpLine,'PWR') > -1);   
   }
   close($fh);
   `rm $fname.tmp` if (-e "$fname.tmp");
      
   my $recCnt = scalar @fLines;
   my ($state,$device,%LastOn,%LastState);

   print "  $recCnt records:\n";
   foreach my $line (@fLines) {
      $device=$curType;
      $line =~ s/\R//g;
      $line =~ s/^Unable to connect log: //g;
      my @flds = split(',',$line);
      my $logtime = $flds[0];
      $device = $flds[3] unless $curType eq 'Watch';
      $logtime =~ s/ //g;
      next unless ($logtime =~ /^[+-]?\d+$/);      
      my $tmpline = uc($line);
      $tmpline =~ s/ //g;
      if ( (index($tmpline,'POWER:0') >= 0) || (index($tmpline,'PWR:0') >= 0) ) {
         push(@lines,$LastOn{$device}) if ( defined($LastState{$device}) && ($LastState{$device} eq 'ON') ); 
         push (@lines,"$logtime,$config->{MAC},,$curType,$fname,$line");
         $cnt = 3;
         $LastState{$device} = 'OFF';
      } else {
         if ($cnt > 0) {
            push (@lines,"$logtime,$config->{MAC},,$curType,$fname,$line"); 
            $cnt--;      
         }
         $LastState{$device} = 'ON';
         $LastOn{$device} = "$logtime,$config->{MAC},,$curType,$fname,$line";
      }
   }
   $recCnt = scalar @lines;
   print "    $recCnt kept\n";
   return(\@lines);
}  # scourFile



my $oldfh = select(STDOUT); # default
$| = 1;
select($oldfh);


my $cdir = getcwd();
my $config = getCmdLine();
$config->{MAC} = getMAC();
my $tmpName = "$config->{MAC}." . time() . ".tmp";
die "Unable to open tmp file $tmpName\t$!" unless open(my $ofh,">$tmpName");

#print "Epoch,MAC,COACH,ID,fType,fName,Data\n";
my $dateStr = time2str("%c",$config->{start},'EST');
#print $ofh "$config->{start},$config->{MAC} ,START,$dateStr EST\n";
my @Data;
foreach my $curType (@fTypes) {
   my $fList = getFlist($fNames{$curType});
   my $fCnt = scalar @{$fList};
   print "Starting $fCnt files of $curType\n";
   my $retList;
   foreach my $fname (@{$fList}) {
      if ($curType eq 'voltage') {
         $retList = scourVoltage($config,$curType,$fname);
         my $cnt = scalar @$retList;
         print "Found $cnt lines in $fname\n" if ($cnt > 0);
      } else {
         $retList = scourFile($config,$curType,$fname);
      }
      push (@Data,@{$retList}) ;
      foreach my $myLine (@{$retList}) {
         print $ofh "$myLine\n";
      }
   }
}
close $ofh;
sleep 5;
`sync`;
my $lineCnt = `wc -l $cdir/$tmpName`;
$lineCnt  =~ s/\R//g if defined($lineCnt);
$lineCnt = 0 unless defined($lineCnt);
my $outname = "$config->{MAC}.$config->{start}.$config->{end}.powerLogs.csv";
my $resp = `sort -k1 -t, $cdir/$tmpName > $cdir/$outname`;
print "Sort Error on file $lineCnt $cdir/$tmpName: $resp\n" unless (-e "$cdir/$outname");
`rm $cdir/$tmpName` if (-e "$outname");
my $Events = getEvents($config,"$cdir/$outname");
system("gzip $cdir/$outname");

my $eventname = "$config->{MAC}.$config->{start}.$config->{end}.powerEvents.csv";
if (open ($ofh, ">$cdir/$eventname") ) {
   print $ofh "Start,EID,End,Duration,SrcFile,FileName\n";
   foreach my $curLine (@{$Events}) { print $ofh "$curLine\n";}
   close $ofh;
   `gzip $cdir/$eventname`;
} else {
   warn "Unable to open $cdir/$eventname  $!\n" 
};

my $cmd = 'rsync -r $cdir/B827EB* mthinx@'.$config->{H}.':/extdata/power';
my $ret = `$cmd`;
print "Synce return: $ret\n" if (defined($ret));

exit 0;
1;
