#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;


my $USAGE = "Usage: findVPN.pl\n" .
            "       -e n : End 1|2\n" .
            "       -f   : FleetDefinition path\n".
            "       -p n : End 1|2\n" .
            "       -i   : Return IP\n" .
            "       -m   : Return MAC\n".
            "       -n n : NUC 1|2\n" .
            "       -r   : rLog\n" .
            "       -C   : Cradlepoint\n".
            "       -c   : coach #(csv)\n";
            
            
sub getCmdLine {
   my %options=();

   my $SRCDIR="$ENV{SRCDIR}" if defined($ENV{SRCDIR});
   $SRCDIR="$ENV{HOME}/bin6" unless defined($ENV{SRCDIR});
   
   getopts("he:p:n:rimc:f:", \%options);
   die $USAGE if (defined $options{h}) || (!defined($options{c}));
   $options{f} = $SRCDIR if defined($SRCDIR) && !defined($options{f});
   dir $USAGE unless defined($options{f}) || defined($SRCDIR);
   return (\%options);
}
       
sub readFleetDefinition {
   my $options = shift;
   #  {NamedData}->{coach}->{name}  = Value  GPSID computed/added
   #  {ArrayData}->{coach}->[i]     = Value
   #  {coaches}                     = Array of coach IDs
   #  {colName}->[i]                = column name by index
   #  {colIdx}->{name}              = index of column by name
   my %CoachMap;
   
      ## Read the Fleet Definition File
   if (open(my $fh, "$options->{f}/FleetDefinition.csv") ) {
      my $header = <$fh>;
      $header =~ s/\R//g;
      my @names = split(',',$header);
      my $numFields = scalar @names;
      for (my $i=0; $i<$numFields; $i++) {
         my $curName = $names[$i];
         if (defined($curName) && ($curName ne '')) {
            $curName =~ s/\R//g;
            $curName =~ s/ //g;
            $CoachMap{colName}->[$i] = $curName;
            $CoachMap{colIdx}->{$curName} = $i;
         }   
      }
      while (my $line = <$fh>) {
         $line =~ s/\R//g;
         my @fields = split(',',$line);
         my $cpmac = $fields[$CoachMap{colIdx}->{'CPMAC'}];
         my $coach = $fields[$CoachMap{colIdx}->{Coach}];
         my $gpsid = (hex substr($cpmac,6,2)) . (hex substr($cpmac,8,2)) . hex substr($cpmac,10,2);     
         $CoachMap{NamedData}->{$coach}->{GPSID} = $gpsid;
         $CoachMap{coaches}->{$coach} = 1;
         $numFields = scalar @fields;
         for (my $i=0; $i<$numFields; $i++) {
            my $curName = $CoachMap{colName}->[$i];
            $curName =~ s/\R//g;
            $curName =~ s/ //g;
            if (defined($curName) && ($curName ne '')) {
               $CoachMap{NamedData}->{$coach}->{$curName} = $fields[$i];
               $CoachMap{ArrayData}->{$coach}->[$i] = $fields[$i];
            }
         }
      }
      close($fh);
   } else {
      die "Unable to open $options->{f}/FleetDefinition.csv\n$!\n";
   }
   return ( \%CoachMap);
}  #  readFleetDefinitions   
               
my $options = getCmdLine();
my $coachMap = readFleetDefinition($options);
my ($retVal,$sensor,$phase) = ('','','');
my $coachList = $options->{c};
my @coaches = split(',',$coachList);

foreach my $coach (@coaches) {
   $phase = $coachMap->{NamedData}->{$coach}->{Phase};
   $sensor = $coachMap->{NamedData}->{$coach}->{Sensor};
   
   if ($options->{r}) {
      if ($options->{m}) {
         $retVal = $coachMap->{NamedData}->{$coach}->{NVR1MAC};
      }
      if ( defined($options->{i}) || !defined($options->{m})){
         $retVal = $coachMap->{NamedData}->{$coach}->{NVR1VPN};      
      }
   }
   print "$coach $retVal $sensor $phase\n";   
}

1;