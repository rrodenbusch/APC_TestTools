#!/usr/bin/perl
use strict;
use warnings;
use Net::Ping;

my $FleetFile = "$ENV{HOME}/bin6/FleetDefinition.csv";
my $ipFile = "$ENV{HOME}/APC_TestTools/ipp.txt";
my %Devices = ('NUC1'=>1,'NUC2'=>1,
					'Pi1-End1'=>1,'Pi2-End1'=>1,'Pi1-End2'=>1,'Pi2-End2'=>1,
					'NVR1'=>1,'NVR2'=>1);

sub checkVPNonline {
   my $p = Net::Ping->new();
   my $retVal;
   
   $retVal = $p if ($p->ping("10.50.0.1"));   
}

sub getCoach {
   my ($FleetFile,$targCoach) = @_;
   my ($line,@names,@fields);
   my %devMap;
      
   open(my $fh, "$FleetFile") or die "Unable to open $FleetFile\n";
   my $header = <$fh>;
   $header =~ s/\R//g;
   @names = split(',',$header);
   shift(@names);
   my $coach = '';
   while ( ($coach ne $targCoach) && ($line = <$fh>) ) {
      $line =~ s/\R//g;
      my @fields = split(',',$line);
      my $coach = shift(@fields);
      if ($coach eq $targCoach) {
         my $cnt = scalar(@fields);
         $cnt = scalar(@names) if (scalar(@names) > $cnt);
         print "Coach $targCoach\t$names[0]:\t$fields[0]\n";
         for (my $i =0; $i < $cnt; $i++ ) {
            my @parts = split(' ',$names[$i]);
            my $last = pop(@parts);
            my $devName=join(' ',@parts);
            if ( $Devices{$devName} && ($last eq 'VPN') && defined($fields[$i]) ) {
               print "\t$names[$i]:\t$fields[$i]\n";
               my $ip = $fields[$i];
               $ip =~ s/ //g;
               $devMap{$devName} = $ip;
            }
         }
      }
   }
   close($fh);
   return(\%devMap);
}  # getCoach



      # Set for auto flush
my $old_fh = select(STDIN);
$| = 1;
select($old_fh);
      
my $targCoach = $ARGV[0];
die "Usage:  checkVPN.pl  coach#\n" unless defined($targCoach);
my $p = checkVPNonline();
die "VPN Offline\n" unless defined($p);
my $devMap = getCoach($FleetFile,$targCoach);
my $coachOnline = 0;
print "\n";
while (!$coachOnline) {
   foreach my $dev (sort(keys(%Devices))) {
      my $ip = $devMap->{$dev};
      my $devOnline = 0;
      $devOnline = 1 if (defined($ip) && ($ip ne '') && ($p->ping($ip)) );
      $coachOnline = 1 if ($devOnline);
      if ($coachOnline) {
         print "\tONLINE\t$dev\t$ip\n" if ($devOnline);
         print "\tOFF   \t$dev\t$ip\n" unless ($devOnline);
      }
   }
   
   if (!$coachOnline) {
      print "Offline Wait\n";
      sleep(60);
   } else {
      print "Coach $targCoach ONLINE\n";
   }
}

1;
