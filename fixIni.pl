#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

my $USAGE = "Usage: fixIni.pl\n".
                  "\t   -f --force          \n" .
                  "\t   -c --capscale          \n" .
                  "\t   -C --capvoltage      \n" .
                  "\t   -l --loadscale          \n" .
                  "\t   -L --loadvoltage      \n" .
                  "\t   -N --nuc  (mac)      \n" . 
                  "\t   -n --nvn  (mac)        \n" ;


sub getCmdLine {
   my ($dateStr);
   my %options=();
   
   getopts("hC:c:l:L:Nn", \%options);
   dir $USAGE if (defined $options{h});
   $options{FORCE} = (defined($options{f}));
   $options{NUC} = (defined($options{N}));
   $options{NVN} = (defined($options{n}));
      
   return(\%options);
}

sub readINI {
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
      $ini{$key} = $val;
   }
   
   $ini{END} = 0;
   $ini{END} = 1 if (($ini{myRole} eq 'Pi1-End1') || ($ini{myRole} eq 'Pi2-End1'));
   $ini{END} = 2 if (($ini{myRole} eq 'Pi1-End1') || ($ini{myRole} eq 'Pi2-End1'));
   $ini{END} = 3 if (($ini{myRole} eq 'rLog'));
   
   return(\%ini);
}

sub getMAC {
   my $ip = shift;
   my $cmd = "sudo nmap -p80 $ip |grep 'MAC Address' |awk -F \" \" '{print $3}'";
   my $mac = `$cmd`;
   $mac =~ s/\R//g;   
   $mac =~ s/ //g;
   
   return ($mac);      
}

my $options = getCmdLine();
my $config = readINI();

my ($NVNmac1,$NVNmac2,$NVNmac3,$NVNmac4,$NUCmac);
$NVNmac1 = getMAC('192.168.0.10') if  (($options->{NVN}) && ($config->{END} == 1));
$NVNmac1 = getMAC('192.168.0.20') if  (($options->{NVN}) && ($config->{END} == 2));
$NVNmac2 = getMAC('192.168.0.11') if  (($options->{NVN}) && ($config->{END} == 1));
$NVNmac2 = getMAC('192.168.0.21') if  (($options->{NVN}) && ($config->{END} == 2));
$NVNmac3 = getMAC('192.168.0.12') if  (($options->{NVN}) && ($config->{END} == 1));
$NVNmac3 = getMAC('192.168.0.22') if  (($options->{NVN}) && ($config->{END} == 2));
$NVNmac4 = getMAC('192.168.0.13') if  (($options->{NVN}) && ($config->{END} == 1));
$NVNmac4 = getMAC('192.168.0.23') if  (($options->{NVN}) && ($config->{END} == 2));
$NUCmac  = getMAC('192.168.0.101') if (($options->{NUC}) && ($config->{END} == 1));
$NUCmac  = getMAC('192.168.0.102') if (($options->{NUC}) && ($config->{END} == 2));

#   Read config file
my @file;
my $myRole = '';
open(my $fh, "$ENV{HOME}/RPi/config.ini") or die "Unable to open config file\n$!\n";;
while( my $line = <$fh>) {
   $line =~ s/\R//g;
   my ($var,$value) = split('=',$line);
   push(@file, $line);
}
close($fh);
`mv $ENV{HOME}/RPi/config.ini $ENV{HOME}/RPi/config.bak.fix`;
my ($cOut,$lOut) = (0,0);

#   Output forced values
open($fh, ">$ENV{HOME}/RPi/config.ini") or die "Unable to open overwrite config file\n$!\n";
foreach my $line (@file) {
   my ($var,$value) = split('=',$line);
   if ( defined($var) && defined($value) ) {
      if ( ($var eq 'myNUC') && ($options->{NUC}) ) {
         print $fh "myNUC=$NUCmac\n";
         print     "myNUC=$NUCmac\n";
      } elsif ($var eq 'subnet') {
         print $fh "subnet=192.168.0\n";
         print     "subnet=192.168.0\n";
      } elsif ($var eq 'SysMonLogDir') {
         print $fh "subnet=/var/log/sysmon\n";
         print     "subnet=/var/log/sysmon\n";
      } elsif  ( ($var eq 'myNVN1') && ($options->{NVN})) {
         print $fh "myNVN1=$NVNmac1\n";
         print     "myNVN1=$NVNmac1\n";
      } elsif ( ($var eq 'myNVN2') && ($options->{NVN})) {
         print $fh "myNVN1=$NVNmac2\n";
         print     "myNVN1=$NVNmac2\n";
      } elsif ( ($var eq 'myNVN3') && ($options->{NVN})) {
         print $fh "myNVN1=$NVNmac3\n";
         print     "myNVN1=$NVNmac3\n";
      } elsif ( ($var eq 'myNVN4') && ($options->{NVN})) {
         print $fh "myNVN1=$NVNmac4\n";
         print     "myNVN1=$NVNmac4\n";
      } elsif ( ($var eq 'CAPscale') && defined($options->{c})) {
         print $fh "CAPscale=$options->{c}\n";
         print     "CAPscale=$options->{c}\n";
         $cOut = 1;
      } elsif ( ($var eq 'LOADscale') && defined($options->{l})) {
         print $fh "LOADscale=$options->{l}\n";
         print     "LOADscale=$options->{l}\n";
         $lOut = 1;
      } else {
          print $fh "$line\n";
      }
   } else {
      print $fh "$line\n";
   }
}
if (defined($options->{c} && (!$cOut) ) ) {
   print $fh "CAPscale=$options->{c}\n";
   print     "CAPscale=$options->{c}\n";
}
if (defined($options->{l} && (!$lOut) ) ) {
   print $fh "LOADscale=$options->{l}\n";
   print     "LOADscale=$options->{l}\n";
}

close($fh);
   

1;
