#!/usr/bin/perl

# # # # # # # # # # # # # # # # #
# Script to backup mysql        #
# slave databases to disk       #
# # # # # # # # # # # # # # # # #

use strict;

# # # # # # # # # # # # # # # # #
# Usage                         #
# # # # # # # # # # # # # # # # #

die "Usage: $0 <user> <password>\n" unless ($#ARGV == 1);

# # # # # # # # # # # # # # # # #
# Declare global variables      #
# # # # # # # # # # # # # # # # #

my $user = $ARGV[0];
my $passwd = $ARGV[1];
my $host = `hostname`; $host =~ (s/\.ts.*?\.xxx\.com\n//);
my $datetime = &dateStamp;
my $basedir = "/apps/oracle/mysql/meb";
my $bkupdir = "$basedir/backups";
my $tmpdir = "$basedir/backup-tmp";
my $logdir = "$basedir/logs";
my $filename = "${host}_${datetime}";
my $logfile = "$logdir/${filename}_meb.log";
my $inst = substr($host,length($host)-1,1);
my $mailto = 'EDELORACLEDBA@XXX.COM';

# # # # # # # # # # # # # # # # #
# Main Routine                  #
# # # # # # # # # # # # # # # # #

eval {                             # Run this code
    logs ("Begining Program");     # Open logfile
    &runBackups;                   # Backup databases
    &verifyBkup;                   # Check status
    logs ("Ending Program");       # Close logfile
};                                 # End eval
exit;                              # All done

# # # # # # # # # # # # # # # # #
# Sub Routines                  #
# # # # # # # # # # # # # # # # #

sub dateStamp { # get datetime stamp for use in filename
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime)[0..5];
    my $datetime = sprintf ("%04d-%02d-%02d_%02d-%02d-%02d",
           $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $datetime;
} # end dateStamp

sub errors { # send the error message
    my $error = $_[0];
    logs ("Error: $error");
    mail ( "Error: $error");
} # end errors

sub logs { # make a log enty
    my $entry = $_[0];
    my $timestamp = &timeStamp;
    open(LOG, ">>$logfile") || warn("Can't open $logfile: $!");
    print LOG "$timestamp  $entry\n";
    close(LOG) || warn("Can't close $logfile: $!");
} # end sub logs

sub mail { # use naive mail on server
    my $msg = $_[0];
    my $mailx = "echo \"$msg\" \| mailx -s \"Alert from $host\" $mailto";
    my $result = system($mailx);
    $result == 0 ? logs("Mail sent") : logs("Mail not sent");
} # end mail

sub runBackups {
    # Local variables
    my $result;
    my $cmd = "$basedir/bin/mysqlbackup";
    my $login = "--user=root --password=$passwd";
    my $server = "--host=localhost --port=3306 --with-timestamp";
    my $repl = "--slave-info";
    my $backup = "--backup-image=$bkupdir/$filename.mbi";
    my $backup_dir = "--backup-dir=$tmpdir backup-to-image";
    my $backup_log = ">> $logfile 2>&1";
    # Backup instructions
    if ($inst == 1) { # only on node 1 for master
        logs("Starting Backup");
        $result = (system("$cmd $login $server $backup $backup_dir $backup_log")); 
    } # end if
    if ($inst == 2) { # only on node 2 for slave backup
        logs("Starting Backup");
        $result = (system("$cmd $login $server $repl $backup $backup_dir $backup_log")); 
    } # end if
    if ($result == -1) { # check results
        errors("Backup job could not be completed: $!");
    } else {
        logs("Backup job completed");
    } # end if
} # end runBackups

sub timeStamp { # get datetime stamp for log file entry
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime)[0..5];
    my $datetime = sprintf ("%02d%02d%02d %02d:%02d:%02d",
       $year - 100, $mon +1, $mday, $hour, $min, $sec);
    return $datetime;
} # end timeStamp


sub verifyBkup {
    my $status;
    my $label = 'prints "mysqlbackup completed OK\!"';
    my $success = "mysqlbackup completed OK\!";
    open(STATUS, "< $logfile") || errors("Can't open $logfile: $!");
    while (<STATUS>) {$status .= $_};
    close(STATUS) || errors("Can't close $logfile file: $!");
    $status =~ s/$label//; # strip label
    unless ($status =~ m/$success/) {
        errors("Backup did not complete successfully");
    } # end unless
} # end verifyBkup

