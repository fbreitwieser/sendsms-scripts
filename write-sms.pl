#!/usr/bin/perl
# Creation date : 2013-01-28

# Module        : write-sms.pl
# Purpose       : Write SMS from console to Android phone
# Usage         : perl write-sms.pl
# Licence       : GPL v2
# Contact       : Florian Breitwieser <florian.bw@gmail.com>

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib $Bin;
use Term::Screen::Uni;
use Complete;
use AndroidSMS;

my $ADB = "adb";

my $scr = new Term::Screen::Uni;
$scr->clrscr();

$scr->at(4,5)->puts(" Gathering contacts ... \n");
my @contacts = get_contacts();
my %contact_to_number = contact_to_number(@contacts);
my %number_to_contact = number_to_contact(@contacts);

$scr->at(5,5)->puts(" Gathering SMS ... \n");
my @sms = AndroidSMS::get_sms();
for (my $i=0; $i<=$#sms; ++$i) {
  $sms[$i] =~ s/\+43/0/g;
  $sms[$i] =~ s/([0-9]) ([0-9])/$1$2/g;
}

$scr->at(7,5)->puts(" Recent SMS \n");
$scr->at(8,0);
print_sms(\%number_to_contact,\@sms);

my ($name,$number);
my $txt = join(" ",@ARGV);
my ($last_number) = split(/ :: /,$sms[1]);
my $last_name = $number_to_contact{$last_number};
$scr->puts("\n\n Press any key to write SMS, or Enter to write to last contact [$last_name] ... ");
my $ret = $scr->getch();
if ($ret eq "\r") {
  ($name,$number) = ($last_name,$last_number);
  $scr->clrscr();
}


while (1) {

  ($name,$number) = ask_for_contact(%contact_to_number) unless defined $number;
  last unless defined $number;
  $txt = do_send_sms($name,$number,$txt);
  $scr->puts("\n  Send another SMS? [Ynsewc]  (call contact with c, to same contact with s, same text to someone else with e). Show recent SMS with w. ");

  my $answer = $scr->getch();
  last if !defined $answer;
    if (uc($answer) eq 'N') {
      last;
    } elsif (uc($answer) eq 'C') {
      system("adb shell am start -a android.intent.action.CALL -d tel:$number");
    } elsif (uc($answer) eq 'S') {
      undef $txt;
      next;
    } elsif (uc($answer) eq 'E') {
      undef $number;
      next;
    } elsif (uc($answer) eq 'W') {
      $scr->puts(" Gathering SMS ... \n");
      @sms = AndroidSMS::get_sms();
      for (my $i=0; $i<=$#sms; ++$i) {
        $sms[$i] =~ s/\+43/0/g;
        $sms[$i] =~ s/([0-9]) ([0-9])/$1$2/g;
      }
      print_sms(\%number_to_contact,\@sms);
      $scr->puts("\n\n Press any key to write SMS ... ");
      $scr->getch();
    }
  
  undef $txt;
  undef $number;
  next;
}

sub do_send_sms {
  my ($name,$number,$txt) = @_;
  last if (!defined $name || $name eq "");
  $scr->puts("\n  Mobile phone number: $number\n");
  show_recent_messages($name,$number,@sms);
  $txt = send_sms_to_number($number,$txt);
  return($txt);
}

sub ask_for_contact {
  my (%contact_to_number) = @_;
  my $name = Complete("Enter contact name",keys %contact_to_number);
  my $number = $contact_to_number{$name};
  last if $name =~ /quit/;
  return ($name,$number);
}

sub show_recent_messages {
  my ($name,$number,@sms) = @_;
  my @sms2 = grep(/$number/,@sms);
  if (scalar @sms2 > 0) {
    $scr->puts("\n  Recent messages: \r\n");
    AndroidSMS::print_sms1($name,\@sms2);
  }
}

sub send_sms_to_number {
  my ($number,$txt) = @_;
  if (!defined $txt || length($txt) == 0) {
    $scr->puts("\n  Enter text: ");
    $txt = <>;
    chomp $txt if defined $txt;
  }
  if (!defined $txt || length($txt) == 0) {
    $scr->puts("\n  No text was entered, not sending.");
    return;
  }
  $scr->puts("\n Send \"$txt\" to number $number? [Yn] ");
  my $answer = <>; chomp $answer if defined $answer;
  if (defined $answer && (uc($answer) eq 'Y' || $answer eq "")) {
    send_sms_using_shellms($number,$txt) unless !defined $txt || $txt =~ /^\s*$/;
  }
  return $txt;
}

sub send_sms_using_shellms {
  my ($number,$txt) = @_;
#  $txt =~ s/'/\\'/g;
  my $cmd = "$ADB shell am startservice --user 0 -n com.android.shellms/.sendSMS -e contact $number -e msg ".quotemeta($txt)."";
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

