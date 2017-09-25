#!/usr/bin/perl -w
#
# mergeReads_fasta.pl
#
# Merge reads from the same individual in a fasta file
#
# July 31, 2015

use strict;

# From the command line, read in the padded fasta file, and the name of an output file
my ($USAGE) = "$0 <input.padded.fasta> <output.merged.fasta>\n";
unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;

# Create a hash keyed by PI, which will hold a list of ALL sequences associated with that PI
my %pi_sequences = ();
my $pi = '';
my $seq = '';

# Open the input file, and read all of the sequences into this hash
open (IN, $input) || die "\nUnable to open the file $input!\n";

while (<IN>) {
  chomp $_;
  
  if ($_ =~ /^>/) {
    unless (length $pi == 0) {
      if (exists $pi_sequences{$pi}) {
	push (@{$pi_sequences{$pi}}, $seq);
      } else {
	@{$pi_sequences{$pi}} = ($seq);
      }
    }
    $_ =~ s/^>//ig;
    $pi = '';
    $pi = (split('_', $_))[0];
    $seq = '';
  } else {
    $seq = $_;
  }
}
close(IN);
if (exists $pi_sequences{$pi}) {
  push (@{$pi_sequences{$pi}}, $seq);
} else {
  @{$pi_sequences{$pi}} = ($seq);
}


# Now, open the output file for printing, then get a sorted list of the PIs
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";
my @read_names = sort {lc($a) cmp lc($b)} (keys %pi_sequences);

# For each read name, check for mismatches, and create a single read to print to the output
foreach my $read (@read_names) {
  my $newstring = '';
  my @list = @{$pi_sequences{$read}};

  if (scalar @list == 1) {
    $newstring = $list[0];
  } else {
    for (my $p = 0; $p < length $list[0]; $p++) {
      my $bases = '';
      foreach my $string (@list) {
	$bases .= substr($string, $p, 1);
      }
      $bases =~ s/[NX]//ig;
      $bases =~ s/\*/D/g;
      
      if (length $bases == 0) {
	$newstring .= 'N';
      } else {
	my $check = 0;
	my $ref = substr($bases, 0, 1);
	for (my $b = 1; $b < length $bases; $b++) {
	  if (substr($bases, $b, 1) =~ /$ref/i) {
	    $check += 0;
	  } else {
	    $check += 1;
	  }
	}
	if ($check == 0) {
	  $newstring .= $ref;
	} else {
	  $newstring .= 'X';
	  print "MISMATCH: ", $read, " Position: ", $p, " ", $bases, "\n";
	}
      }
    }
  }
  $newstring =~ s/D/\*/g;
  print OUT ">", $read, "\n", $newstring, "\n";
}
close(OUT);
exit;
	  
    
