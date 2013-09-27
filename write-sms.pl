#!/usr/bin/perl
# Creation date : 2013-01-28

# Module        : write-sms.pl
# Purpose       : Write SMS from console to Android phone
# Usage         : perl write-sms.pl
# Licence       : GPL v2
# Contact       : Florian Breitwieser <florian.bw@gmail.com>

use strict;
use warnings;
use Term::Screen::Uni;
use Complete;
use AndroidSMS qw/get_sms print_sms/;

my $ADB = "adb";

my $scr = new Term::Screen::Uni;
$scr->clrscr();
$scr->at(4,5)->puts(" Gathering contacts ... \n");
my @contacts = `sh get-contacts2`; 
my %contact_to_number;
my %number_to_contact;
foreach (@contacts) {
  my @c = split(/ :: /);
  $c[1] =~ s/ //g;
  $c[1] =~ s/\+43/0/;
  $contact_to_number{$c[0]} = $c[1];
  $number_to_contact{$c[1]} = $c[0];
}
$scr->at(5,5)->puts(" Gathering SMS ... \n");
my @sms = AndroidSMS::get_sms();
for (my $i=0; $i<=$#sms; ++$i) {
  $sms[$i] =~ s/\+43/0/g;
  $sms[$i] =~ s/([0-9]) ([0-9])/\1\2/g;
}

$scr->at(7,5)->puts(" Recent SMS \n");
$scr->at(8,0);
print_sms(\%number_to_contact,\@sms);
print "\n\n Press Enter to write SMS ... ";
$scr->getch();

my ($input,$name,$number);
while (!defined $input || !defined $name || !defined $number) {
  $input = Complete("Enter contact name",keys %contact_to_number);
  my $name = $input;
  my $number = $contact_to_number{$name};
  last if $input =~ /quit/;
  last unless defined $number;
  my $txt = join(" ",@ARGV);
  print "\n  Recent messages: \r\n";
  my @sms2 = grep(/$number/,@sms);
  AndroidSMS::print_sms1($name,\@sms2);
  if (length($txt) == 0) {
    print "\n\n  Text: ";
    $txt = <>;
    chomp $txt if defined $txt;
  }
  print "\n Send \"$txt\" to number $number? [yN]";
  my $answer = <>; chomp $answer if defined $answer;
  if (defined $answer && uc($answer) eq 'Y') {
    send_sms_using_shellms($number,$txt) unless !defined $txt || $txt =~ /^\s*$/;
  }
  exit;
}

sub send_sms_using_shellms {
  my ($number,$txt) = @_;
  my $cmd = "$ADB shell am startservice --user 0 -n com.android.shellms/.sendSMS -e contact $number -e msg '$txt'";
  print STDERR "Executing $cmd\n";
  system($cmd) == 0 or die "Could not send SMS";
  system("$ADB logcat -d -s -C ShellMS_Service_sendSMS:*");
}

sub send_sms_using_shell {
  my ($number,$txt) = @_;
  print STDERR "Executing $ADB shell am start -a android.intent.action.SENDTO -d sms:$number --es sms_body '$txt' --ez exit_on_sent true\n";
  system("$ADB shell am start -a android.intent.action.SENDTO -d sms:$number --es sms_body '$txt' --ez exit_on_sent true") == 0 or die "Could not send SMS";
  sleep 1;
  system("$ADB shell input keyevent 22") == 0 or die "Could not focus on send button";
  sleep 1;
  system("$ADB shell input keyevent 66") == 0 or die "Could not press send button";
  sleep 1;
  system("$ADB shell input keyevent 3") == 0 or die "Could not press send button";
}

