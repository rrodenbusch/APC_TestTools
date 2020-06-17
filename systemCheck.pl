#!/usr/bin/perl
use strict;
use warnings;

sub readINI {
   #
   # Read the config.ini 
   #
   my %ini;
   my %devices;
   my @file;
   
   open(my $fh, "$ENV{HOME}/RPi/config.ini") 
               or die "Unable to open config.ini $!\n";;
   while( my $line = <$fh>) {
      $line =~ s/\R//g;
      push(@file, $line);
   }
   close($fh);

   @file = grep m/^[^#]/, @file;  # skip comments
   for (@file) {
      chomp;
      my ($key, $val) = split /=/;
      $key =~ s/\R//g;
      $val =~ s/\R//g;
      $val =~ s/ //g if ($key eq 'myRole');
      if ($key eq 'I2C_Device') {
         my($I2addy,$I2device,$I2name,$I2optional) = split(',',$val);
         $I2addy = hex($I2addy);
         $devices{$I2addy}->{name} = $I2name;
         $devices{$I2addy}->{optional} = $I2optional;
         $devices{$I2addy}->{type} = $I2device;
      } else {
         $ini{$key}=$val;
      }
   }
   
   return(\%ini);
}

sub cronCheck {
   #
   #  Make sure the required lines are present in the crontab
   #
   my $config = shift;
   my $required;
   my %requiredrLog = ( 'openRTSP'   => '0 7 * * * /usr/bin/killall openRTSP',
                        'startPi.sh' => '@reboot   /home/pi/RPi/startPi.sh >>/home/pi/Watch.log 2>&1'
                      );
   my %requiredPi1 = (
                        'startPi.sh' => '@reboot   /home/pi/RPi/startPi.sh >>/home/pi/Watch.log 2>&1'
                     );
   my %requiredPi2 = (
                        'startPi.sh' => '@reboot   /home/pi/RPi/startPi.sh >>/home/pi/Watch.log 2>&1'
                     );
                     
   if ($config->{myRole} eq 'rLog') {
      $required = \%requiredrLog;
   } elsif ( ($config->{myRole} eq 'Pi1-End1') ||
             ($config->{myRole} eq 'Pi1-End2') ) {
      $required = \%requiredPi1;
   } else {
      $required = \%requiredPi2;
   }
   my %matched;
   my $newfile = 0;
   my @newLines;
  
   my $cronfile = `crontab -l`;
   my @cronlines = split('\n',$cronfile);
   foreach my $curLine (@cronlines) {
      $curLine =~ s/\R//g;
      push (@newLines, $curLine) if ($curLine =~ m/^\s*#/);
      next                       if ($curLine =~ m/^\s*#/);
      foreach my $key (keys(%{$required})) {
         if (index($curLine,$key) != -1) {
            $matched{$key} = 1;
            if ($required->{$key} ne $curLine) {
               print "cron update,$required->{$key}\n";
               $newfile = 1;
               $curLine = $required->{$key};
               next;
            }
         }
      }  # next key
      push(@newLines,$curLine);      
   }  # next line of file
   
   if ($newfile) {
      my $newLines = join("\n",@newLines);
      `crontab -l >$ENV{HOME}/RPi/cron.bak`;
      my $fname = "$ENV{HOME}/RPi/cron.new";
      open(my $fh, ">$fname") or die "Unable to open $fname\t$!\n";
      print $fh "$newLines\n";
      close $fh;
      `crontab $fname`;
   }
   $cronfile = `crontab -l`;
   @cronlines = split('\n',$cronfile);
   $cronfile = '';
   foreach my $curLine (@cronlines) {
      $curLine =~ s/\R//g;
      next                       if ($curLine =~ m/^\s*#/);
      $cronfile .= "$curLine\n";
   }
   return($cronfile);
}

sub checkNVR{
   my $config = shift;
   return (0) unless ( $config->{myRole} eq 'rLog' );
   
}

my @commands = ('df -h | grep -v ^none | ( read header ; echo "$header" ; sort -rn -k 5)',
                "$ENV{HOME}/APC_TestTools/stopRPi.pl");

#my $cmdList = 
my $resp;
my $config = readINI();

print $resp if ($resp=cronCheck($config));
print $resp if ($resp=checkNVR($config));
foreach my $curCmd (@commands) {
   $resp = `$curCmd`;
   print "$resp\n";
}

1;