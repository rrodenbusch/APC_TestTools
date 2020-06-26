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
   
   my $fLine = `head -1 $ENV{HOME}/RPi/config.ini`;
   $fLine =~ s/\R//g;
   `sed -i '1 i\[default]' $ENV{HOME}/RPi/config.ini` unless ($fLine eq '[default]');
   
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
   my %requiredrLog = ( 'openRTSP'    => '0 7 * * * /usr/bin/killall openRTSP',
                        'RunNVR.pl'   => '0 7 * * * /usr/bin/killall RunNVR.pl',
                        'startPi.sh'  => '@reboot   /home/pi/RPi/startPi.sh          >>/home/pi/Watch.log 2>&1'
                      );
   my %requiredPi1 = (
                        'startPi.sh' => '@reboot   /home/pi/RPi/startPi.sh           >>/home/pi/Watch.log 2>&1',
                        'watchPower' => '@reboot   /home/pi/APC_TestTools/watchPower >>/home/pi/Watch.log 2>&1'
                     );
   my %requiredPi2 = (
                        'startPi.sh' => '@reboot   /home/pi/RPi/startPi.sh           >>/home/pi/Watch.log 2>&1'
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
   
   foreach my $key (keys(%{$required})) {
      if (!defined($matched{$key}) || ($matched{$key} == 0) ) {
         print "cron add,$required->{$key}\n";
         $newfile = 1;
         my $curLine = $required->{$key};
         push(@newLines,$curLine);
      }
   }
   
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


my $delim="#################";
my $config = readINI();
my ($coach,$runDate) = @ARGV;
$coach = $config->{coach} unless defined($coach);
$runDate = `date "+%Y%m%d` unless defined($runDate);

print "\n\n$delim  System Check $config->{myRole} $coach $runDate $delim\n";

my @cmdKeys = ( 'USAGE','PROCS','NVR','JPGS','CLIPD','CLIPS','UPTIME','VBOX');

my %Commands = ('USAGE'    => 'df -h | grep -v ^none | ( read header ; echo "$header" ; sort -rn -k 5)',
                'PROCS'    => "$ENV{HOME}/APC_TestTools/stopRPi.pl",
                'NVR'      => 'ls -ltr /data/NVR/Working |tail -10 |grep mp4',
                'CLIPD'    => "ls -ltr /data/NVR/clips |tail -4",
                'CLIPS'    => "ls -ltr /data/NVR/clips/$runDate 2>&1|tail -10",
                'JPGS'     => "tail -1 /data/NVR/jpgSizes.csv",
                'UPTIME'   => 'uptime',
                'VBOX'     => 'VBoxManage list runningvms'
                );  
my %cmdNames = ('USAGE'    => 'DISK USAGE',
                'PROCS'    => 'PROCS RUNNING',
                'NVR'      => 'NVR',
                'CLIPD'    => 'CLIP DATES',
                'CLIPS'    => 'CLIP SERVER',
                'JPGS'     => 'JPEG CAPTURES',
                'UPTIME'   => 'UPTIME',
                'VBOX'     => 'VMs'
                );
my %cmdRoles = ('USAGE'    => 'ALL',
                'PROCS'    => 'ALL',
                'NVR'      => 'rLog',
                'CLIPD'    => 'rLog',
                'CLIPS'    => 'rLog',
                'JPGS'     => 'rLog',
                'VBOX'     => 'NUC1',
                'VBOX'     => 'NUC2',
                'UPTIME'   => 'ALL'
                );
my $resp;               
print "$delim  CRON $delim\n$resp" if ($resp=cronCheck($config));    
foreach my $curKey (@cmdKeys) {
   if ( ($cmdRoles{$curKey} eq 'ALL') || 
        ($cmdRoles{$curKey} eq $config->{myRole}) ) {
      my $curCmd = $Commands{$curKey};
      $resp = `$curCmd`;
      print "\n$delim  $cmdNames{$curKey}  $delim\n$resp\n";     
   }
}

1;