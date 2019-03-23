# Author: Jonathan Samson
# Date: 3/26/19
# Class: CMSC-416-001 VCU Spring 2019
# Project: Programming Assignment 4
# Title: scorer.pl
# 
#   One of Natural Language Processing's (NLP's) essential challenges is word sense disambiguation (WSD). Similar spellins of
# a single word often have different meanings. This can be seen in the dictionary, where most words have multiple
# definitions. For example, run can be used to describe quick physical linear movement on foot, or the action of running
# for a position in an organization. WSD takes up the issue of automatically distinguishing the particular definition, or sense,
# of a word in text. This project applies WSD techniques to distinguise between two sense of the word "line": that of a phone
# line, and that of a product line.
# 
# Example Input and Output:
#
# 

use strict;
use warnings;
use feature 'say';

my $total = 0;
my $correct = 0;
my %answers = ();

my $argCount = scalar @ARGV;
if($argCount < 2) {
    die "You must enter 2 arguments for answers file and key file."
}

my $answersFile = $ARGV[0];
my $keyFile = $ARGV[1];

# Open training file.
open(my $fhAnswers, "<:encoding(UTF-16)", $answersFile)
    or die "Could not open file '$answersFile' $!";

open(my $fhKey, "<:encoding(UTF-8)", $keyFile)
    or die "Could not open file '$keyFile' $!";



# Iterate through answers file and store all key->value pairs (id->sense) in hash.
# This also ensures that all answers that should be present are provided.
while( my $line = <$fhAnswers> ) {

    my($id) = $line =~ /instance="([^"]*)"/;
    my($sense) = $line =~ /senseid="([^"]*)"/;

    print "id: $id\n";

    $answers{$id} = $sense;

    # # Make sure their ids match
    # $keyId = $lineKey =~ /id="(.*)"/;
    # $answerId = $lineAnswer =~ /id="(.*)"/;

    # if( $keyId ne $answerId ) {
    #     die "There was an "
    # }
}

while( my $line = <$fhKey> ) {
    # Make sure their ids match
    my($id) = $line =~ /instance="([^"]*)"/;

    if( !exists $answers{$id} ) {
        die "There is an error matching id found in key: $id";
    }

    my ($sense) = $line =~ /senseid="([^"]*)"/;
    print "sense: $sense\n";

    if( $sense eq $answers{$id} ) {
        $correct++;
    }
    $total++;
}
my $accuracy = $correct / $total;
print "correct:     $correct\n";
print "total:       $total\n";
print "accuracy:    $accuracy\n;
