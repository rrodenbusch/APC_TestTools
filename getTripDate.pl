#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);

sub getStartTime {
   my $epoch = $_[0];
   
   my $StartHr = 2;  # change days at 3 am Eastern, 2am Central(localtime)
   my $startday = strftime("%Y-%m-%d",localtime($epoch-$StartHr*3600)); # Switch days at 3am local time, take current time and back off X hours
   my $endday = strftime("%Y-%m-%d",localtime($epoch+24*3600-$StartHr*3600)); # Add one day to current time to get end day
   my $dirname = strftime("%Y%m%d",localtime($epoch-$StartHr*3600));  # Format YYYYMMDD for the directories
   
   return($startday,$endday,$dirname);
}  #  getStartTime


my $epoch = $ARGV[0] if defined($ARGV[0]);
$epoch = time() unless defined($epoch);
my ($startday,$endday,$dirname) = getStartTime($epoch);
print "$dirname\n";
#$epoch -= 8*3600;  # backup 7 hours of gmtime to get 3am eastern (1 hr after reports shift to next day)
#my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($epoch);
#my $dateStr = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
#print "$dateStr\n";

1;
