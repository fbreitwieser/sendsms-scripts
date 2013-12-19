package Complete;
require 5.000;
require Exporter;

# Based on Complete.pm v1.401 by Wayne Thompson
# modified by Florian Breitwieser, Sep 2013

use strict;
use warnings;
use Term::ANSIColor;
use Term::Screen::Uni;

our @ISA = qw(Exporter);
our @EXPORT = qw(Complete);
our $VERSION = '1';

our($complete, $kill, $erase1, $erase2, $tty_raw_noecho, $tty_restore, $stty, $tty_safe_restore);
our($tty_saved_state) = '';


CONFIG: {
  $complete = "\025";
  $kill   = "\004"; # control D
  $erase1 =   "\177";
  $erase2 =   "\010";
  foreach my $s (qw(/bin/stty /usr/bin/stty)) {
  if (-x $s) {
    $tty_raw_noecho = "$s raw -echo";
    $tty_restore  = "$s -raw echo";
    $tty_safe_restore = $tty_restore;
    $stty = $s;
    last;
  }
  }
}


sub Complete {
  my($prompt, @cmp_lst) = @_;
  my $scr = new Term::Screen::Uni;
  my ($return, $r) = ("", 0);

  $return = "";
  $r    = 0;


  if (ref $cmp_lst[0] || $cmp_lst[0] =~ /^\*/) {
    @cmp_lst = sort { uc($a) cmp uc($b) } @{$cmp_lst[0]};
  }
  else {
    @cmp_lst = sort { uc($a) cmp uc($b) } (@cmp_lst);
  }

  $scr->clrscr();

  # Attempt to save the current stty state, to be restored later
  if (defined $stty && defined $tty_saved_state && $tty_saved_state eq '') {
  $tty_saved_state = qx($stty -g 2>/dev/null);
  if ($?) {
    # stty -g not supported
    $tty_saved_state = undef;
  }
  else {
    $tty_saved_state =~ s/\s+$//g;
    $tty_restore = qq($stty "$tty_saved_state" 2>/dev/null);
  }
  }
  system $tty_raw_noecho if defined $tty_raw_noecho;
  LOOP: {
    local $_;
    print_prompt($scr,$prompt,$return,@cmp_lst);
    while (($_ = getc(STDIN)) ne "\r") {

      CASE: {
        # (TAB) attempt completion
        $_ eq "\t" && do {

          $return = match_it($scr,$prompt,$return,1,@cmp_lst);
          $r = length($return);

          last CASE;
        };

        # (^D) completion list
        $_ eq $complete && do {
          print_cmp_lst($return,('',@cmp_lst));
          redo LOOP;
        };

        # (^U) kill
        $_ eq $kill && do {
          exit();
          if ($r) {
            $r  = 0;
      $return  = "";
            print("\r\n");
            redo LOOP;
          }
          last CASE;
        };

        # (DEL) || (BS) erase
        ($_ eq $erase1 || $_ eq $erase2) && do {
          if($r) {
            print("\b \b");
            chop($return);
            $return = match_it($scr,$prompt,$return,0,@cmp_lst);
            $r--;
          }
          last CASE;
        };

        # printable char
        ord >= 32 && do {

          $return .= $_;
          $return = match_it($scr,$prompt,$return,0,@cmp_lst);
          $r = length($return);

          #redo LOOP;
          last CASE;
        };
      }
    }

    my @res = grep(/^.*\Q$return/, @cmp_lst);
    if (scalar @res == 1) {
      $return = match_it($scr,$prompt,$return,1,@cmp_lst);
    }
  }

  # system $tty_restore if defined $tty_restore;
  if (defined $tty_saved_state && defined $tty_restore && defined $tty_safe_restore)
  {
  system $tty_restore;
  if ($?) {
    # tty_restore caused error
    system $tty_safe_restore;
  }
  }
  return($return);
}

sub print_prompt {
  my($scr,$prompt,$return,@cmp_lst) = @_;
  $scr->clrscr();
  $scr->at(1,1)->puts("##################################################\n");
  $scr->at(2,1)->puts("### Android SMS Sender:");
  if (length($return) > 0) {
    print_cmp_lst($return,@cmp_lst) ;
  } else {
    print " loaded ".scalar(@cmp_lst)." contacts\r\n";
  }
  $scr->puts("\r\n  ".($prompt).":  ");
  print colored $return, "bold"; 
}

sub get_match_length {
  my (@match) = @_;
  my $test = shift(@match);
  my $l = length($test);
  foreach my $cmp (@match) {
    until (substr($cmp, 0, $l) eq substr($test, 0, $l)) {
      $l--;
    }
  }
  if ($l > length($test)) {
    return length($test);
  } else {
    return $l;
  }
}

sub print_cmp_lst {
  my ($return,@cmp_lst) = @_;
  my @res = grep(/^.*\Q$return/, @cmp_lst);
  if (scalar @res == 0) {
    print colored " no match\r\n","blue";
  } elsif (scalar @res == 1) {
    print colored " 1 unique match [press tab]\r\n","blue";
    print colored "  --> ".join("\r\n  --> ", @res). "\r\n", "green";
  } else {
    print colored " ".scalar(@res)." matches\r\n","blue";
    print colored "  --> ".join("\r\n  --> ", @res). "\r\n", "green";
  }
}


sub match_it {
  my ($scr,$prompt,$return,$do_write,@cmp_lst) = @_;

  my @match = grep(/^.*\Q$return/, @cmp_lst);
  unless ($#match < 0) {


    if ($#match == 0) {
      if ($do_write) {
        print substr($match[0], length($return)-1, length($match[0])-length($return)+1);
        $return = $match[0];
      }
      print_prompt($scr,$prompt,$return,@cmp_lst);
    } else {
      my $l = get_match_length(@match);
      if ($l > 0) {
        if ($do_write) {
          $return= substr($match[0], 0, $l);
        }
      }
      print_prompt($scr,$prompt,$return,@cmp_lst);
    }
  } else {
    print " [no match]\r\n";
    print_prompt($scr,$prompt,$return,@cmp_lst);
  }
  return $return;
}

1;
