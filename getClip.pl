#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use Time::Local;
use Getopt::Std;

my $USAGE = "Usage: getClip.pl\n".
                  "\t   -c Coach             \n" .
                  "\t   -d Input dir         \n" .
                  "\t   -D output dir        \n" .
                  "\t   -e end time epoch    \n" .
                  "\t   -E end offset (sec)  \n" .
                  "\t   -f CSV data file     \n" .
                  "\t   -i IP (csv: 10,13,20,23)\n".
                  "\t   -l clip len (sec)    \n" .                  
                  "\t   -m MACs              \n" .
                  "\t   -n Channel [0..3]    \n" .
                  "\t   -s start time epoch  \n" .              
                  "\t   -S start offset (s)  \n" .              
                  "\t   -t targDir           \n" . 
                  "\t   -o output file prefix\n" .             
                  "   file1 file2 ...        \n\n" .
            "CSV file {startepoch,endepoch,fname}\n";

sub logMsg {
   my $msg = shift;
   print "$msg\n";
}

sub readActiveDoors {
   my $logfh = shift;
   my $fname = 'ActiveDoors.csv';
   my %Doors;
   
   logMsg $logfh, "Unable to open $fname\$!\n" unless (open(my $fh,$fname));
   <$fh>;  #take off header
   while (my $line = <$fh>) {
      chomp $line;
      my @flds = split(',',$line);
      $Doors{$flds[0]}->{'1L'} = $flds[1];
      $Doors{$flds[0]}->{'1R'} = $flds[2];
      $Doors{$flds[0]}->{'2L'} = $flds[3];
      $Doors{$flds[0]}->{'2R'} = $flds[4];
   }
   close($fh);
   return (\%Doors);
}

sub doorActiveOpen {
   my ($doors,$coach,$end,$threshold,$activeDoors) = @_;
   my $doorOpen = 0;
   
   my $doorID = '';
   $doorID = '1L' if ($end == 1) && ($threshold eq 'LEFT');
   $doorID = '1R' if ($end == 1) && ($threshold eq 'RIGHT');
   $doorID = '2L' if ($end == 2) && ($threshold eq 'LEFT');
   $doorID = '2R' if ($end == 2) && ($threshold eq 'RIGHT');
   my $active = $activeDoors->{$coach}->{$doorID};
   
   my $mask = 0x00;
   $mask = 0x01 if ($threshold eq 'LEFT');
   $mask = 0x02 if ($threshold eq 'RIGHT');
   my $open = ( ($doors ne '') && ($doors & $mask) == 0);
   
   if ( ($mask != 0) && ($open) && ($active)) {
      $doorOpen = 1;
   };
   return($doorOpen);
}


sub readINI {
   my $self = shift;
   my %ini;
   my %devices;
   my @file;
   
   open(my $fh, "$ENV{HOME}/RPi/config.ini");
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
      $self->{$key}=$val;
      $ini{$key}=$val;
   }
   return(\%ini);
}  # end readINI


sub getCmdLine {
   my ($startEpoch, $endEpoch,$dir,$MACs,$coach,$chan,$ip,$prefix);
   my %options=();
   
   getopts("hc:d:D:e:E:f:i:l:m:n:s:S:t:o:", \%options);
   if (defined $options{h})   {
      die $USAGE;
   }
   $startEpoch = $options{s} if defined($options{s});
   $startEpoch = 0 unless defined($startEpoch);
   $endEpoch = $startEpoch + 15 * 60;           # default 15 minutes
   $endEpoch = $options{e} if defined($options{e});
   $endEpoch = $startEpoch + $options{l} if defined($options{l});
   $dir = cwd;
   $dir = $options{d} if defined($options{d});
   $MACs = $options{m} if defined($options{m});
   $coach = $options{c} if defined($options{c});
   $chan = $options{n} if defined($options{n});
   $ip = $options{i} if defined($options{i});
   $prefix = 'clip_';
   $prefix .= $options{o} if defined($options{o});
   
   `mkdir $options{t}` if (defined($options{t})  && (!(-d $options{t})));
   
   my $config = readINI() if (defined($ip));
   my %NVNhash;
   if (defined($ip)) {
      $ip =~ s/\R//g;
      if (my $NVNmap = $config->{NVNmap} ) {
         $NVNmap =~ s/\R//g if defined($NVNmap);
         my @fields = split(':',$NVNmap);
         foreach my $curField (@fields) {
            my ($mac,$ip) = split(',',$curField);
            $mac =~ s/://g;
            $NVNhash{$ip} = uc substr($mac,-6);
         }         
      }

      if (defined($NVNhash{$ip}) ) {
         $MACs = $NVNhash{$ip};
      } else {
         my $subnet = '192.168.0';
         $subnet = $config->{subnet} if (defined($config->{subnet}));
         my $ret = "sudo nmap -p 80 " . $subnet . '.' . "$ip \| grep MAC";
         $ret = `$ret`;
         my $mac = (split(' ',$ret))[2];
         $mac =~ s/://g;
         $mac = substr($mac,-6) if ($mac ne '');
         $MACs = $mac  if ($mac ne '');
         logMsg "Mapped -i $ip to -m $mac";
      }      
   }

   return($startEpoch,$endEpoch,$dir,$MACs,$coach,$chan,\%options,$prefix);
}

sub parseFname {
   ##   xxxxxx_YYYYMMDDhhmmss-aaaaaa-bbbbbb.mp4
   ##   xxxxxx  last 6 of MAC on video feed
   ##   YYYYYMMDDhhmmss  date time
   ##   aaaaaaa, bbbbbbb start and end offset (secs) of the file vs datetime
   my $curFile = shift;
   my ($MAC, $year,$mon,$mday,$hh,$mm,$ss,$start) = 
              (substr($curFile,0,6),substr($curFile,7,4),substr($curFile,11,2),substr($curFile,13,2),
               substr($curFile,15,2),substr($curFile,17,2),substr($curFile,19,2),substr($curFile,22,5));
   my $fStartEpoch = timegm($ss,$mm,$hh,$mday,--$mon,$year) + $start;
   my $fEndEpoch   = (stat $curFile)[9];
   return($fStartEpoch,$fEndEpoch,$MAC);
}

sub getFileList{
   my ($dir,$MACs,$coach,$chan,$options) = @_;
   my ($fList,@files);
   
   if ( ($dir ne cwd()) && (!chdir($dir)) ) {
      my $msg = "Bad working directory, $!";
      logMsg $msg;
      die $msg;   
   }
   
   if (scalar @ARGV > 0) { # No command line files
      $fList = \@ARGV;
   } else {
      my @files = glob("$MACs".'_*') if (defined($MACs));    
      @files = glob('*.mp4') unless (defined($MACs));
      $fList = \@files;
   }
   return($fList);   
}

sub catMP4 {
   my $firstClip = shift;
   my $lastClip  = shift;
   my @wholeFiles = @_;

   my $clipName = $firstClip;
   
   if ( (scalar @wholeFiles > 0) || (defined($lastClip)) ) {
      ### Put them together and then cleanup
      logMsg("Concatenating files");
   }
   
   return($firstClip);
}

sub getClip {
   my ($fname,$start,$end,$cntr,$prefix) = @_;
   print "File $fname start $start End $end\n";

   my ($fStartEpoch,$fEndEpoch,$MAC) = parseFname($fname);
   my $ret = `ffmpeg -i $fname 2>&1 | grep "Duration" |cut -d ' ' -f 4 |sed s/,//`;
   my $ffDur = 3600*substr($ret,0,2) + 60*substr($ret,3,2) +
                    substr($ret,6,2) + substr($ret,9,2)/100;
   my $fnDur = $fEndEpoch - $fStartEpoch;
   my $durScale = $ffDur / $fnDur;
   

   my ($SSopt,$TOopt) = ("-ss 0","");
   my $FileOffset = $start -$fStartEpoch;
   my $offset = $durScale * $FileOffset;
   $SSopt = "-ss $offset " if ($offset > 0);       # start of clip is in the file
   $offset = $offset + $durScale*($end - $start);
   $TOopt = "-to $offset" if ($end < $fEndEpoch);  # end of clip is in the file
   my $cntrStr = "";
   $cntrStr = "_" . $cntr . "_" if ( defined($cntr) && ($cntr ne '') );
   my $targName = $prefix .'_' . $MAC . '_' . $start .'_'. $end . $cntrStr . '.mp4';
   my $cmd = 'ffmpeg -loglevel panic -y ' .
             "-i $fname $SSopt $TOopt -c copy $targName";  
   logMsg "Extracting Scale $ffDur,$fnDur,$durScale $SSopt $TOopt -i $fname into $targName\n$cmd";
   my $cmdRet = `$cmd`;
   
   my $retVal = $targName if (-e $targName);
   return($retVal);
}

sub mvClips {
   my $targDir = shift;
   
   if (defined($targDir)  && (-d $targDir) ) {
      print "Copying files to $targDir\n";
      foreach my $curFname (@_) {
         if (defined($curFname) && (-e $curFname)) {
            my $targName = $targDir . '/' . $curFname;
            `mv -f $curFname $targName` if defined($targName ne $curFname);      
         }
      }
   }
}

my ($startEpoch,$endEpoch,$dir,$MACs,$coach,$chan,$options,$prefix) = getCmdLine();
my $fList = getFileList($dir,$MACs,$coach,$chan,$options);
my $odir = $options->{o} if defined($options->{o});

my $fCnt = scalar @$fList;
logMsg "Searching $fCnt files";
my ($firstClip,$lastClip,@fullFiles,$fullClip);
if (scalar @$fList > 1) {
   logMsg "Looking for $startEpoch to $endEpoch in $fCnt files";  
   foreach my $curFile (@$fList) {
      my ($firstFile,$lastFile,$wholeFile) = ('','','');
      my ($fStartEpoch,$fEndEpoch) = parseFname($curFile);
   
      $firstFile   = $curFile if ( ($startEpoch >= $fStartEpoch) && ($startEpoch <= $fEndEpoch) );   
      $lastFile    = $curFile if ( ($endEpoch >= $fStartEpoch)   && ($endEpoch <= $fEndEpoch) && ($firstFile eq '') );
      $wholeFile   = $curFile if ( ($startEpoch >= $fStartEpoch) && ($endEpoch <= $fEndEpoch) && ($firstFile eq '') && ($lastFile eq ''));
   
      push(@fullFiles,$curFile) if ( defined($firstFile) && ($firstFile eq $curFile));
      push(@fullFiles,$lastFile) if ( $lastFile ne '' );
   
      if ( !( defined($firstFile) && ($firstFile eq $curFile) )   && 
           !( defined($lastFile)  && ($lastFile eq $curFile) ) ){
         push(@fullFiles,$curFile) if ( ($fStartEpoch >= $startEpoch) && ($fEndEpoch <= $endEpoch) );        
      }
   }
   my $firstFile  = shift(@fullFiles);
   my $lastFile   = pop(@fullFiles);
   
   $firstClip  = getClip($firstFile,$startEpoch,$endEpoch,,$prefix) if defined($firstFile);
   $lastClip   = getClip($lastFile,$startEpoch,$endEpoch,1,$prefix)  if defined($lastFile);
 

} elsif (scalar @$fList ) {
   # Process the only file on the list
   my $curFile = shift @$fList;
   my ($fStartEpoch,$fEndEpoch,$MAC) = parseFname($curFile);
   my $ret = `ffmpeg -i $curFile 2>&1 | grep "Duration" |cut -d ' ' -f 4 |sed s/,//`;
   my $ffDur = 3600*substr($ret,0,2) + 60*substr($ret,3,2) +
                    substr($ret,6,2) + substr($ret,9,2)/100;
   my $fnDur = $fEndEpoch - $fStartEpoch;
   my $durScale = $ffDur / $fnDur;
   my $SSopt = "-ss 0";
   $SSopt = "-ss ". int($durScale*$options->{S}) if ( defined($options->{S}) );
   my $start = $fStartEpoch + $durScale*$options->{S} if ( defined($options->{S}) );
   my $fileStart = $fStartEpoch + $options->{S};
   my ($end,$fileEnd);
   if (defined($options->{E})) {
      $end = $durScale*$options->{E};
      $fileEnd = $options->{E};
      $fileEnd -= $options->{S} if defined($options->{S});
   }
   $end = $start + $durScale*$options->{l} if defined($options->{l});
   $fileEnd = $options->{l} if defined($options->{l});
   $fileEnd = int($fileEnd) + 1 unless (int($fileEnd) == $fileEnd);
   my $TOopt = "-to $end";
   my $targName = "$prefix" ."_" . $MAC . '_' . $fileStart .'_'. $fileEnd . '.mp4';
   print "ffmpeg Dur: $ffDur  file Dur: $fnDur  scale $durScale\n";
   my $cmd = 'ffmpeg -loglevel panic -y ' .
                "-i $curFile $SSopt $TOopt -c copy $targName";  
   logMsg "Scale $durScale\nExtracting $cmd";
   my $cmdRet = `$cmd`;
   $firstClip = $targName;
   $fullClip = $targName;
} else {
   die $USAGE;
}

my $statLine = "Created $firstClip";
$statLine .= "," . join(',',@fullFiles) if (scalar @fullFiles > 0);
$statLine .= ",$lastClip" if defined($lastClip) && ($lastClip ne '');
logMsg "$statLine\n";

mvClips($options->{t},$firstClip,$lastClip,@fullFiles);
#my $cmd = 'ls -ltr ' . "$options->{t}";
#my $ret = `$cmd`;
#print "$ret\n";

1;