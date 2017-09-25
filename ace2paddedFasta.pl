#!/usr/bin/perl -w
#
# ace2paddedFasta.pl
#
# Convert reads in the ace format to multiple sequences (Aligned!!)
# in a padded fasta format
#
# July 31, 2015

use strict;
use Data::Dumper;

# From the command line, read in the ace file and the name of the output file
my ($USAGE) = "$0 <input.ace> <output.fasta>\n";

unless (@ARGV) {
  print $USAGE;
  exit;
}
my ($input, $output) = @ARGV;

# Open the input and output files
open (IN, $input) || die "\nUnable to open the file $input!\n";
open (OUT, ">$output") || die "\nUnable to open the file $output!\n";

# Create a hash to hold the padded starts for every read
# Save the consensus sequence in a separate string
my %read_starts = ();
my $consensus = '';

# Set flags for read names and read sequences outside of the file loop
my $read = '';
my $bases = '';
my $co_flag = 0;
my $rd_flag = 0;

# Hold all of the individual reads in a hash outside of the file loop
my %read_sequences = ();

# Start reading through the input file;
# save the consensus sequence first, the the padded starts,
# then process each individual read
while (<IN>) {
  chomp $_;

  if ($_ =~ /^AS/) {
    next;
  }

  elsif ($_ =~ /^\s*$/) {
    $co_flag = 0;
    $rd_flag = 0;
    next;
  }

  elsif ($_ =~ /^CO\sContig/) {
    $co_flag = 1;
    next;
  } 

  elsif ($co_flag) {
    $consensus .= $_;
  }

  elsif ($_ =~ /^BQ/) {
    $co_flag = 0;
  }

  elsif ($_ =~ /^AF/) {
    my @info = split(/\s{1,}/, $_);
    $read_starts{$info[1]} = $info[3];
  }

  elsif ($_ =~ /^RD/) {
    unless ((length $read) == 0) {
      $read_sequences{$read} = $bases;
    }
      $read = (split(/\s{1,}/, $_))[1];
      $rd_flag = 1;
      $bases = '';
  }

  elsif ($rd_flag) {
    $bases .= $_;
  }

  elsif ($_ =~ /^QA/) {
    $read_sequences{$read} = $bases;
    next;
  } 

  else {
    next;
  }
}
close(IN);

# Print out the consensus sequence to the output file
print OUT ">Consensus", "\n", $consensus, "\n";

# Now, go through every read sequence, look up it's adjusted start position,
# and either trim or pad the read as necessary so that it lines up to the consensus
# then print it in fasta format to the output
my @read_names = sort {lc($a) cmp lc($b)} (keys %read_sequences);

foreach my $name (@read_names) {
  my $string = $read_sequences{$name};
  my $position = $read_starts{$name};
  my $newstring = '';

  # If the starting position is negative, the beginning of the read needs to be trimmed up until position 1
  if ($position < 0) {
    my $trimpos = abs($position) + 1;
    $newstring = substr($string, $trimpos, (length($string) - $trimpos));
  } 

  # If the position is greater than 1, then the sequence needs to be padded at the start until position 1
  elsif ($position > 1) {
    my $pads = $position - 1;
    $newstring = 'N' x $pads;
    $newstring .= $string;
  }

  else {
    $newstring = $string;
  }

  # Finally, make sure that all of the new strings are the same length as the consensus, then print them
  my $finalstring = '';
  if ((length $newstring) < (length $consensus)) {
    my $add = (length $consensus) - (length $newstring);
    my $temp = 'N' x $add;
    $finalstring = $newstring . $temp;
  }

  elsif ((length $newstring) == (length $consensus)) {
    $finalstring = $newstring;
  }

  else {
    $finalstring = substr($newstring, 0, (length $consensus));
  }

  print OUT ">", $name, "\n", $finalstring, "\n";
}


close(OUT);
exit;


  
