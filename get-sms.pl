#!/usr/bin/perl
# Creation date : 2013-01-28

use FindBin qw/$Bin/;
use lib $Bin;
use AndroidSMS;

my @contacts = get_contacts();
my %contacts = number_to_contact(@contacts);

my @sms = get_sms();
print_sms(\%contacts,\@sms);

