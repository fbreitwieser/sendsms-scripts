package AndroidSMS;
require 5.000;
require Exporter;

use strict;
use warnings;
use Term::ReadKey;
use Term::ANSIColor;
use Data::Dumper;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_sms print_sms);
our $VERSION = '1';

my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();

sub get_sms {
  my $SQLCMD="select address,replace(body,x'0A', ' '),type,read from sms order by _id desc limit 25";
  my $sms_cmd="adb shell su -c \"sqlite3 -header -list -separator ' :: ' /data/data/com.android.providers.telephony/databases/mmssms.db \\\\\\\"$SQLCMD\\\\\\\"\"";
  my @res = `$sms_cmd`;
  chomp @res;
  return @res;  
}
sub print_sms1 {
  my ($contact,$sms) = @_;
  my %sms;
  my $first_line = 1;
  foreach (reverse @$sms) {
    my @s = split(/ :: /);
    next if $s[0] eq 'address';

    my $color = 'blue';
    $color = 'green' if ($s[2] == 1);
    $color = 'red' if ($s[3] == 0);

    if ($s[2] == 2) {
      printf " %".length($contact)."s ","[Me]";
      print colored $s[1]."\n",$color;
    } else {
      print " [$contact] ";
      print colored $s[1]."\n",$color;
    }
  }
}


sub print_sms {
  my ($contacts,$sms) = @_;
  my %sms;
  my $first_line = 1;
  chomp @$sms;
  foreach (reverse @$sms) {
    my @s = split(/ :: /);
    next if $s[0] eq 'address';
    $s[0] =~ s/ //g;
    $s[0] =~ s/\+43/0/;
    # address,body,type,read
    #my $dest = $s[2] == 1? "from " : "  to ";
    my $dest = $s[2] == 1? " from " : " to ";
    my $read = $s[3] == 0? " [unread]" : "";
    my $color = 'blue';
    $color = 'green' if ($s[2] == 1);
    $color = 'red' if ($s[3] == 0);
    my $contact = defined $contacts->{$s[0]}? $contacts->{$s[0]} : $s[0];
    my $str = sprintf(" %25s","$dest".$contact);
    my $indent = length($str) + 2;
    
    my $width = $wchar-$indent-3;
  
    my @txt2 = split(/  */,$s[1]);
    my @txt = shift @txt2;
    foreach (@txt2) {
      if (length($txt[$#txt]) + length($_) < $width) {
        $txt[$#txt] .= " $_";
      } else {
        push @txt, $_;
      }
    }
  
    @txt = map { $_."\r\n" } @txt;
    my $txt = join(" " x $indent,@txt);
  
    print colored $str, $color;
    print ": ";
    print colored $txt, $color;
  }
}

1;
