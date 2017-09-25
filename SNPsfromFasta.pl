#!/usr/bin/perl -w
#
# SNPsfromFasta.pl
#
# Call SNPs from a (padded to the same length) Fasta file
#
# August 6, 2015

use strict;
use Data::Dumper;

# From the command line, get the name of the input and output files
my ($USAGE) = "$0 <input.fasta> <output.snps.txt>\n";
unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;

# Read all of the sequences (except the targets) into a hash keyed by name
my %sequences = ();
my $name = '';
my $string = '';
my $flag = 0;

open (IN, $input) || die "\nUnable to open the file $input!\n";
while (<IN>) {
  chomp $_;
  
  if ($_ =~ /^>/) {
    unless ((length $name) == 0) {
      $sequences{$name} = $string;
    }
    $name = '';
    $string = '';

    $_ =~ s/^>//ig;
    unless ($_ =~ /^[TR]/) {
      $name = $_;
      $flag = 1;
    }
  } elsif ($flag) {
    $string = $_;
    $flag = 0;
  } else {
    next;
  }
}
close(IN);

unless ((length $name) == 0) {
  $sequences{$name} = $string;
}

# Open the output file for printing
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

# Get the consensus string, then the sorted list of all of the PIs
my $consensus = $sequences{'Consensus'};

my @sorted_keys = sort {lc($a) cmp lc($b)} (keys %sequences);
my @pi_list = ();
foreach my $k (@sorted_keys) {
  unless ($k =~ /Consensus/) {
    push (@pi_list, $k);
  }
}

# Print a header to the output file
print OUT "Position\t", "Alleles\t", "Consensus";
foreach my $key (@pi_list) {
  print OUT "\t", $key;
}
print OUT "\n";

# Now, go through every possible position in the consensus sequence...
for (my $p = 0; $p < length $consensus; $p++) {
  my $ref = substr($consensus, $p, 1);
  $ref =~ s/\*/I/ig;
  $ref = uc $ref;

  # Save the string of PI bases outside of the loop of every individual
  my $genoString = '';

  # Save a check if the SNP is polymorphic or not
  my $poly_check = 0;
  my $alt_allele = '';

  # Now, loop through every PI in the sorted list, and get the base at this position
  foreach my $pi (@pi_list) {
    my $base = substr($sequences{$pi}, $p, 1);
    $base =~ s/\*/I/ig;
    $base = uc $base;
    $genoString .= $base;

    unless (($base =~ /$ref/) || ($base =~ /[NX]/) || ($ref =~ /[NX]/)) {
      $poly_check++;
      unless ($base =~ /[MRSYWK]/) {
	$alt_allele = $base;
      }
    }
  }

  if ($poly_check > 0) {
    $genoString =~ s/I/\-/ig;
    my @temp = split('', $genoString);
    my $outstring = join("\t", @temp);

    $alt_allele =~ s/I/\-/ig;
    $ref =~ s/I/\-/ig;

    print OUT $p, "\t", $ref, "/", $alt_allele, "\t", $ref, "\t", $outstring, "\n";
  } else {
    next;
  }
}
close(OUT);

    
exit;

  
