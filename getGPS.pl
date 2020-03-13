#!/usr/bin/perl
use lib "$ENV{HOME}/RPi";
use strict;
use warnings;

use RPiConfig;
use RemoteLog;


sub getConnection {
   my $config = shift;
   my $ip = shift;
   my $remoteLog = $config->{remoteLog} if ($config->{remoteLog});
   # auto-flush on socket
   $| = 1;
   $remoteLog->sendMessage("GetGPS: Binding to $ip  554\n") if ($remoteLog);
   # creating a listening socket
   my $socket = new IO::Socket::INET (
                         PeerAddr   => $ip,
                         PeerPort   => 554,
                         Proto      => 'tcp',
                         Listen     => 5,
                         Blocking   => 0,
                         ReuseAddr  => 1
                     );
   return $socket;
} 

sub parsePV {
   my $msg = shift;
   $msg =~ s/\R//g;
   # 0123456789012345678901234567890123
   # >RPVAAAAABBBBBBBBDDDDDDDDDEEEFFFHI
   #  4,5 GPS time of data (A)
   #  9,8 Lat B  xxx.xxxxx
   # 17,9 Lon D  xxxx.xxxxx
   # 26,3 Speed(mph)
   # 29,3 Heading(deg)
   # 32,1 Source
   # 33,1 Age ( 2=Fresh < 10s : 1=Old > 10s; 0=NA)
   my $gpsTime = substr($msg,4,5);
   my $lat = substr($msg,9,3) . '.' . substr($msg,12,4);
   $lat += 0;
   my $lon = substr($msg,17,4) . '.' . substr($msg,21,5);
   $lon += 0;
   my $speed = substr($msg,26,3);
   my $age = substr($msg,33,1);
 
   return($gpsTime,$lat,$lon,$speed,$age);
}


my $config = new RPiConfig();
my $remoteLog = new RemoteLog($config);
$remoteLog->{logIP} = $config->{subnet} . '.231';

my $ip = $config->{subnet} . ".1";
my ($gpsTime,$lat,$lon,$speed,$age,$char,$line);

while(1)
{
   my $CurPos; # Hash handle for the most recent data
   open(my $fh, "wget --quiet --output-document=- 192.168.0.1:554 |");
   my $read;
   while ($read = read $fh, $char, 1) {
      $line .= $char;
      if ($char eq '<') {
         $line =~ s/\R//g;
         if (substr($line,0,4) eq '>RPV'){
            print "$line\n"; 
            ($gpsTime,$lat,$lon,$speed,$age) = parsePV($line);
            my $line = "Lat $lat Lon $lon Time $gpsTime Speed $speed (mph) Age $age\n";
            print $line;
         }
         $line = '';
      }
   }
   close($fh);
}
 
1;
