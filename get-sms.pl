#!/usr/bin/perl
# Creation date : 2013-01-28

use Term::ANSIColor;
use Data::Dumper;
use Term::ReadKey;
use Getopt::Long;
use AndroidSMS;

my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();

my @contacts = get_contacts();
my %contacts = number_to_contact(@contacts);

my @sms = get_sms();
print_sms(\%contacts,\@sms);

