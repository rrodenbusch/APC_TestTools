#!/usr/bin/perl -w
use strict;
use Cwd qw(cwd);
use Time::Local;
use Getopt::Std;


my $USAGE = "Usage: getClip.pl\n".
                  "\t   -c Coach(es) {csv}   \n" .
                  "\t   -d date      yyyymmdd\n" .
                  "\t   -D local dir         \n" . 
                  "\t   -T target dir        \n" . 
                  "\t   -s Set(s)    {csc}   \n" ;

sub getCmdLine {
   my ($dateStr);
   my %options=();
   
   getopts("hc:s:d:", \%options);
   if (defined $options{h})   {
      die $USAGE;
   }
   if (defined($options{d})) {
      $options{dateStr} = $options{d};
   } else {
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
      my $dateStr = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
      $options{dateStr} = $dateStr;
   }
   if (defined($options{D})) {
      $options{localDir} = $options{D} . "$options{dateStr}";
   } else {
      $options{localDir} = "$ENV{HOME}/MBTA/Working/$options{dateStr}";
   }
   if (defined($options{T})) {
      $options{targDir} = $options{T};
   } else {
      $options{targDir} = "/home/mthinx/MBTA/Working"
   }
   
   if (defined($options{s})) {
      $options{sets} = $options{s};
   }
   if (defined($options{c})) {
      $options{coaches} = $options{c};
   }
   return(\%options);
}

my $logfh;
sub logMsg {
   my ($msg,$fh) = @_;

   my $logName = 'getSetClips';
  
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
   my $dateStr = sprintf("%04d%02d%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
   $dateStr =~ s/\R//g;
   print "$dateStr, $logName: $msg\n" unless defined($logfh);
   print $logfh "$dateStr, $logName: $msg\n" if defined($logfh);;
}

sub readTripCoaches{
   my %setDefn;
   my %coachDefn;
   my %TripList;
   
   if ( (-s "TripCoaches.csv") && (open(my $fh, "<TripCoaches.csv")) ) {
      chomp(my @file = <$fh>);
      close $fh;
      @file = grep m/^[^#]/, @file;  # skip comments
      foreach my $line (@file) {
         my @flds    = split(',',$line);
         my $offset  = shift @flds;
         my $timeStr = shift @flds;
         my $tripNum = shift @flds;
         my @coaches = sort { $b <=> $a } @flds;
         if ($coaches[0] > 1000) {
            $TripList{$coaches[0]}->{$tripNum} = 1;
            foreach my $curCoach (@coaches) {
               $coachDefn{$coaches[0]}->{$curCoach} = 1; ;            
            }
         }
      }
      foreach my $curSet (keys(%coachDefn)) {
         my @coachList = (keys(%{$coachDefn{$curSet}}));
         @coachList = sort { $b <=> $a } @coachList;
         $setDefn{$curSet} = join(',',@coachList);
      }
   } else {
      logMsg "ERROR TripCoaches.csv does not exist";
   }
   return(\%setDefn,\%TripList);
}


my $options = getCmdLine();
chdir "$options->{localDir}";
my $curDir = cwd();
open ($logfh, ">>getSetClips.log");
logMsg "Working in $curDir";

if (defined($options->{sets}) || defined($options->{coaches})) { 
   logMsg "Get set data for $options->{sets}"    if (defined($options->{sets}));
   logMsg "Get coach data for $options->{coaches}" if (defined($options->{coaches}));
   my $cmd = "$ENV{HOME}/APC_TestTools/retrievePullClips.sh -d $options->{dateStr} 2>&1";
   logMsg $cmd;
   my $ret= `$cmd`;
   if ($?) {
      my $errCode = $? >> 8;
      $errCode = sprintf("%x", $errCode);
      logMsg "$errCode Error on $cmd";
      exit $? >> 8;
   }
   logMsg "$ret";
}

logMsg "Clips Commands Retrieved from server\n";
my ($allSets,$TripSets) = readTripCoaches($options->{sets}) if defined($options->{sets});
my @setList = split(',',$options->{sets});
foreach my $curSet (@setList) {
   my $curTripList = join(',',(keys(%{$TripSets->{$curSet}})));
   my $coachList = $allSets->{$curSet};
   logMsg "Processing Set $coachList";
   my $echo = "Starting Set $coachList";
   `echo \"$echo\" >>getSetClips.log`;
   my @coaches = split(',',$coachList);
   
   foreach my $coach (@coaches) {
      my $pid;
      next if $pid = fork(); # parent goes to the next
      die "fork failed: $1" unless defined $pid;
      my $myPID = $$;
      my $oldfh = select(STDOUT); # default
      $| = 1;
      select($oldfh);
      ## Echo out the starting message      
      my $echo = "fork $myPID for coach $coach starting";
      `echo \"$echo\" >>getSetClips.log`;
      ## Run the fork
      my $cmd = "$ENV{HOME}/APC_TestTools/retrieveClips.sh -f -c $coach 2>&1 >>retrieve$coach.log";
      `$cmd`;
      ## Echo out the completed messagse
      $echo = "Clips retrieved from $coach";
      `echo \"$echo\" >>getSetClips.log`;
      exit; 
   }
   1 while (wait() != -1);

   my $cmd = "$ENV{HOME}/APC_TestTools/syncClips.sh -f 2>&1 >>getSetClips.log";
   logMsg "All forks done";
   logMsg "Syncing $curSet to server for trips $curTripList";
   `$cmd`;
   logMsg "Set $curSet synced for trips $curTripList";
}

1;