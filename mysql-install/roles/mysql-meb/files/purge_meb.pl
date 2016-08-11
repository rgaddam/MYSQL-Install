#!/usr/bin/perl

# # # # # # # # # # # # # # # # #
# Script to purge mysql         #
# enterprise backup files       #
# # # # # # # # # # # # # # # # #

use strict;
use File::Path qw( rmtree );


# # # # # # # # # # # # # # # # #
# Usage                         #
# # # # # # # # # # # # # # # # #

die "Usage: $0 <days to keep>\n" if ($#ARGV != 0);
die "Usage: Argumement must be an integer\n" unless ($ARGV[0] =~ m/[\d*]/);

# # # # # # # # # # # # # # # # #
# Declare global variables      #
# # # # # # # # # # # # # # # # #

my $days = $ARGV[0];
my $ctr = 0;
my $cutoff = (time() - ($days * 86400));
my $host = `hostname`; $host =~ (s/\.ts.*?\.xxxx\.com\n//);
my $date = &dateStamp;
my $basedir = "/apps/oracle/mysql/meb";
my $tmpdir = "$basedir/backup-tmp";
my $bkupdir = "$basedir/backups";
my $logdir = "$basedir/logs";
my $filename = "${host}_${date}";
my $logfile = "$logdir/${filename}_purge_meb.log";
my $mailto = 'EDELORACLEDBA@XXXX.COM';

# # # # # # # # # # # # # # # # #
# Main Routine                  #
# # # # # # # # # # # # # # # # #

eval {              # Run this code
    &openLog;       # Open the log
    &purgeBackups;  # purge backups 
    &purgeFiles;    # purge files 
    &purgeLogs;     # purge logs 
    &closeLog;      # Close the log
};                  # End eval
exit;               # All done

# # # # # # # # # # # # # # # # #
# Sub Routines                  #
# # # # # # # # # # # # # # # # #

sub closeLog { # close the log file
    (logs("Closing program\n") && close(LOG)) || warn("Can't close $logfile: $!");    
} # end closeLog

sub dateStamp { # get long name for file
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime)[0..5];
    my $datetime = sprintf ("%04d-%02d-%02d_%02d-%02d-%02d",
                   $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $datetime;
} # end sub dateStamp

sub errors { # send the error message
    my $error = $_[0];
    logs ("Error: $error");
    mail ( "Error: $error");
} # end errors

sub logs { # make a log enty
    my $entry = $_[0];
    my $timestamp = &timeStamp;
    print LOG "$timestamp  $entry\n";
} # end sub logs

sub mail { # use naive mail on server
    my $msg = $_[0];
    my $mailx = "echo \"$msg\" \| mailx -s \"Alert from $host\" $mailto";
    my $result = system($mailx);
    $result == 0 ? logs("Mail sent") : logs("Mail not sent");    
} # end mail

sub openLog { # open the log file
    open(LOG, ">>$logfile") ? logs("Starting program") : warn("Can't open $logfile: $!");
} # end openLog

sub purgeBackups { # Delete files from backup directory
    $ctr = 0;
    opendir(SOURCE,$bkupdir) || errors("Can't open $bkupdir: $!");
    while (defined(my $file = readdir(SOURCE))) {
        next if ($file =~ m/^\.\.?$/); 
        next if (-d "$bkupdir/$file"); # skip directories
        next unless ($file =~ m/\.mbi/);
        my $age = (stat("$bkupdir/$file"))[9]; # get file creation date       
        if ($age < $cutoff) {
            unlink ("$bkupdir/$file") ? logs("Deleted $bkupdir/$file") : errors("Can't delete $bkupdir/$file");
            $ctr++;
        } # end if
    } # end while
    closedir(SOURCE) || errors("Can't close $bkupdir: $!");
    logs("No files to delete in $bkupdir") if ($ctr == 0); 
} # end purgeBackups

sub purgeFiles { # Purge tmp files
    $ctr = 0;
    opendir(SOURCE,$tmpdir) || errors("Can't open $tmpdir: $!");
    while (defined(my $file = readdir(SOURCE))) {
        next if ($file =~ m/^\.\.?$/);
        next unless (-d "$tmpdir/$file"); # only directories
        my $age = (stat("$tmpdir/$file"))[9]; # get file creation date
        if ($age < $cutoff) {
            rmtree ("$tmpdir/$file") ? logs("Deleted $tmpdir/$file") : errors("Can't delete $tmpdir/$file");
            $ctr++;
        } # end if
    } # end while
    closedir(SOURCE) || errors("Can't close $tmpdir: $!");
    logs("No files to delete in $tmpdir") if ($ctr == 0);
} # end purgeFiles

sub purgeLogs { # Purge log files
    $ctr = 0;
    opendir(SOURCE,$logdir) || errors("Can't open $logdir: $!");
    while (defined(my $file = readdir(SOURCE))) {
        next if ($file =~ m/^\.\.?$/);
        next if (-d "$tmpdir/$file"); # no directories
        next unless ($file =~ m/\.log/); # only log files
        my $age = (stat("$logdir/$file"))[9]; # get file creation date
        if ($age < $cutoff) {
            unlink ("$logdir/$file") ? logs("Deleted $logdir/$file") : errors("Can't delete $logdir/$file");
            $ctr++;
        } # end if
    } # end while
    closedir(SOURCE) || errors("Can't close $logdir: $!");
    logs("No files to delete in $logdir") if ($ctr == 0);
} # end purgeLogs

sub timeStamp { # get datetime stamp for log file entry
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime)[0..5];
    my $datetime = sprintf ("%02d%02d%02d %02d:%02d:%02d",
       $year - 100, $mon +1, $mday, $hour, $min, $sec);
    return $datetime;
} # end timeStamp


