#!/usr/bin/perl
use strict;
use warnings;

sub cronCheck {
   my %required = ( 'openRTSP' => '0 7 * * * /usr/bin/killall openRTSP');
   my %matched;
   my $newfile = 0;
   my @newLines;
  
   my $cronfile = `crontab -l`;
   my @cronlines = split('\n',$cronfile);
   foreach my $curLine (@cronlines) {
      $curLine =~ s/\R//g;
      push (@newLines, $curLine) if ($curLine =~ m/^\s*#/);
      next                       if ($curLine =~ m/^\s*#/);
      foreach my $key (keys(%required)) {
         if (index($curLine,$key) != -1) {
            $matched{$key} = 1;
            if ($required{$key} ne $curLine) {
               $newfile = 1;
               $curLine = $required{$key};
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

}

cronCheck();

1;