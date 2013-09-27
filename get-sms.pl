#!/usr/bin/perl
# Creation date : 2013-01-28
# Purpose       : 

use Term::ANSIColor;
use Data::Dumper;
use Term::ReadKey;
use Getopt::Long;

my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();

my @contacts = `sh get-contacts2`;
my %contacts;
foreach (@contacts) {
  my @c = split(/ :: /);
  $c[1] =~ s/ //g;
  $c[1] =~ s/\+43/0/;
  $contacts{$c[1]} = $c[0];
}

my @sms = `sh get-sms`; chomp @sms;

my %sms;
my $first_line = 1;
foreach (reverse @sms) {
  my @s = split(/ :: /);
  next if $s[0] eq 'address';
  $s[0] =~ s/ //g;
  $s[0] =~ s/\+43/0/;
  # address,body,type,read
  #my $dest = $s[2] == 1? "from " : "  to ";
  my $dest = $s[2] == 1? "" : " to ";
  my $read = $s[3] == 0? " [unread]" : "";
  my $color = 'blue';
  $color = 'green' if ($s[2] == 1);
  $color = 'red' if ($s[3] == 0);
  #my $contact = $contacts{$s[0]}." ($s[0])";
  my $contact = defined $contacts{$s[0]}? $contacts{$s[0]} : $s[0];
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

  #my @txt = unpack("(A$width)*",$s[1]);
  @txt = map { $_."\n" } @txt;
  my $txt = join(" " x $indent,@txt);

  print colored $str, $color;
  print ": ";
  #print colored $s[1]."\n", $color;
  print colored $txt, $color;
  #my $str = sprintf(" $dest %s: ",$contact);
  #print Text::Format->new({columns=>60,bodyIndent => 5,firstIndent=>5})->format($s[1]);
  #print colored $read, 'red';
  #print "\n";
}
