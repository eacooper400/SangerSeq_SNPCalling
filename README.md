# Sanger Sequencing Alignment and SNP Calling
Instructions as well as Perl scripts for aligning, basecalling,
merging, and ultimately calling SNPs from Sanger sequencing data.

## Alignment with PhredPhrap
This alignment approach relies on the Phred, Phrap, and Consed
software available
![here](http://www.phrap.org/phredphrapconsed.html).

1.  For each sequenced region, create a directory with 3
sub-directories inside of it to hold the raw and aligned data:

```bash
$ mkdir Region1
$ cd Region1/
$ mkdir chromat_dir edit_dir phd_dir
```

2.  Move all of the chromatogram (`.ab1`) files into the `chromat_dir`.

```bash
$ mv *.ab1 Region1/chromat_dir/
```

3.  Create a target file in `.fasta` format, convert to `.phd` format, and
move it into the `phd_dir`:

```bash
$ module load consed/29
$ fasta2Phd.perl targetRegion1.fa
$ cp targetRegion1.phd.1 Region1/phd_dir/
```

4.  `cd` into the `edit_dir` to run phredPhrap:

```bash
$ cd Region1/edit_dir/
$ phredPhrap
```

### Basecalling with Consed
Once phredPhrap has finished running, you need to manually inspect the
sequences and edit the basecalls using Consed.

1.  From the `edit_dir`, run the `consed` command (you will need X11
tunneling turned on for this).

2.  In Consed, start by sorting the reads alphabetically (so that you
can see the Forward and Reverse reads together in each contig):

`Sort -> Sort Options and Help -> Sort Alpha`

3.  If reads are divided into multiple contigs, I recommend cleaning
up each contig first before trying to merge them.

4.  Go to the start position of the target sequence, and change
everything to the left to **X**:

`Misc -> Change X's to the Left in all reads`

5.  At the other end, change all bases to X's to the right side at the point
where all sequences start to look bad (usually around 600 bp).

6.  Go to `Dim -> Dim Nothing` so that it is easier to see and edit
all possible mismatches.

7.  Scroll through all of the sequences looking for mismatches; right
    click the base to bring up the chromatograms, and edit however
    seems appropriate.  When you are done (or need to stop), go to
    `File -> Save Assembly`

8.  To merge contigs, first open the assembly view for EACH contig.
    Then, put the cursor on the position where you know they should
    align.  Hit the `Compare Contig` button in the open window of the
    first set of contigs.  Then hit the same button in the other
    contig window.  Hit `Align`, and if they are aligned okay, hit
    `Join Contig`.  Save the assembly again, and re-scroll through to
    see if anything else needs to be edited.


### Join all basecalled assemblies together
If you are sequencing an entire gene, you likely had to break it up
into more than one region.  After basecalling each region, you need to
join everything together into one sequence.

1.  First, create an alignent of just the regional target sequences
with the master (full gene) target sequence.  Make a new directory for
this alignment, with the same sub-directory structure.  Then copy all
individual/regional target .phd files into the new `phd_dir`:

```bash
$ mkdir Gene_Target
$ cd Gene_Target
$ mkdir chromat_dir edit_dir phd_dir
$ cp Region*/phd_dir/target.phd.1 Gene_Target/phd_dir/
$ cd edit_dir
$ phredPhrap
```

2.  Now, make another new folder to hold the merged `.ace` files, and
    copy ALL alignments into it with the `mergeAces.perl` command
    (this includes the newly made Gene_Target alignment:

```bash
$ perl consed-29.0/bin/mergeAces.perl --makedir Final_Align/ --copy Region1/ Region2/ Region3/ Gene_Target/
```

3.  The above command will create one .ace file using the most
    recently saved `.ace` files from each alignment.  You need to open
    this `.ace` file in Consed and potentially join the contigs if they
    did not completely merge together (the same way as described above
    for joining contigs in a single region alignment).


### Call SNPs from Final Ace FIle
There are 3 perl scripts included here to help with SNP calling from
an `.ace` alignment.  You need to run all 3 of them in the following
order:

1.  `ace2paddedFasta.pl`

```bash
ace2paddedFasta.pl <input.ace> <output.fasta>
```

Run the above script on your final merged `.ace` file, and give the name
of the output file in `.fasta` format that you want it to make.

2.  `mergeReads_fasta.pl`

```bash
mergeReads_fasta.pl <input.padded.fasta> <output.merged.fasta>
```

Give the file created by step 1 as input, and the second argument is
the name of the new `.fasta` to create.

This script merges reads from the same individual (forward and
reverse, and overlapping parts of different regions).  It will check
that the basecalls for the same individual all agree, and will return
an error with a list of mismatches if they do not.

You may have to manually edit the `.ace` file in consed again to fix any
erroneous basecalls.

3.  `SNPsfromFasta.pl`

```bash
SNPsfromFasta.pl <input.fasta> <output.snps.txt>
```

Run this final script on the output from step 2, and give the name of
the output file as your second argument.

The output will be a tab-delimited `.txt` format, with 3 columns plus
a column for each individual in your sequencing file.

The first 3 columns are:
* Position: the position (in bp) of the SNP
* Alleles: the REF/ALT alleles for that SNP site
* Consensus: the consensus allele at that site

The sample columns each have the basecall for that individual at that
site (with 1 row per SNP site).

Indels will not automatically be grouped; you may need to go in and do
this manually after the fact.
