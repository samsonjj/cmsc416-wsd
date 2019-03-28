# Author: Jonathan Samson
# Date: 3/28/19
# Class: CMSC-416-001 VCU Spring 2019
# Project: Programming Assignment 4
# Title: scorer.pl
#
#--------------------------------------------------------------------------
#   Problem Statement
#--------------------------------------------------------------------------
#
#   This program is designed to score the output produced by decision-list.pl of the same project. It outputs number of correct
# guesses, number of total guesses, and total accuracy (correct / total). It also outputs a confusion matrix for the results.
#
#   One of Natural Language Processing's (NLP's) essential challenges is word sense disambiguation (WSD). Similar spellins of
# a single word often have different meanings. This can be seen in the dictionary, where most words have multiple
# definitions. For example, run can be used to describe quick physical linear movement on foot, or the action of running
# for a position in an organization. WSD takes up the issue of automatically distinguishing the particular definition, or sense,
# of a word in text. This project applies WSD techniques to distinguise between senses given a training file and test file.
# 
#--------------------------------------------------------------------------
#   Usage Instructions and Example Input/Output
#--------------------------------------------------------------------------
#
# This program takes in two command line arguments:
#   1) the file name for the answers file, which should have output from decision-list.pl
#   2) the file name for the key file, which contains the correct answers for the same instances answers in the previous file.
#
# And example run of this program might look like the following:
#   
# [IN-COMMAND]
# perl scorer.pl my-line-answers.txt line-key.txt
#
# [IN-ANSWERSFILE]
# <answer instance="line-n.w8_059:8174:" senseid="phone"/>
# <answer instance="line-n.w7_098:12684:" senseid="phone"/>
# <answer instance="line-n.w8_106:13309:" senseid="phone"/>
# <answer instance="line-n.w9_40:10187:" senseid="phone"/>
# ...
#
# [IN-KEYFILE]
# <answer instance="line-n.w8_059:8174:" senseid="phone"/>
# <answer instance="line-n.w7_098:12684:" senseid="phone"/>
# <answer instance="line-n.w8_106:13309:" senseid="phone"/>
# <answer instance="line-n.w9_40:10187:" senseid="phone"/>
# <answer instance="line-n.w9_16:217:" senseid="phone"/>
# ...
#
# [OUT-STDOUT]
# Useless use of numeric eq (==) in void context at scorer.pl line 154.
# correct:     110
# total:       126
# accuracy:    0.873015873015873
#
# CONFUSION MATRIX
# KEY is the correct sense, after which, sense predictions are shown in a comma delimited list. Counts are shown next to senses.
#
# KEY=product: (41)product(13)phone
# KEY=phone: (69)phone(3)product
#
#--------------------------------------------------------------------------
#   Algorithm
#--------------------------------------------------------------------------
#
# Below is a description of the structure of this program and its algorithm.
#
# 1) Iterate through the answers file, storing the id and sense of each prediction in a hash.
# 2) Iterate trhough the key file, comparing the actual senses with the senses stored previously.
#       * Store the correct and total counts, as well as counts for each new key-guess pair. 
# 3) Print correct, total, and accuracy. Print confusion matrix.

use strict;
use warnings;
use feature 'say';

# Store the number of total and correct answers.
my $total = 0;
my $correct = 0;

# This hash stores the answers read from the answers file (which should have been output by decision-list.pl).
my %answers = ();

# This hash stores counts of key->guess pairs. This is so we can print a confusion matrix later.
my %confusionMatrix = ();

# Obtain the file names from the command line arguments.
my $argCount = scalar @ARGV;
if($argCount < 2) {
    die "You must enter 2 arguments for answers file and key file."
}
my $answersFile = $ARGV[0];
my $keyFile = $ARGV[1];

# Open answers file.
open(my $fhAnswers, "<:encoding(UTF-8)", $answersFile)
    or die "Could not open file '$answersFile' $!";

# Open key file.
open(my $fhKey, "<:encoding(UTF-8)", $keyFile)
    or die "Could not open file '$keyFile' $!";


# Iterate through answers file and store all key->value pairs (id->sense) in hash.
# This also ensures that all answers that should be present are provided.
while( my $line = <$fhAnswers> ) {

    # Use regex to parse out id and sense.
    my($id) = $line =~ /instance="([^"]*)"/;
    my($sense) = $line =~ /senseid="([^"]*)"/;

    # Store the pair in the hash.
    $answers{$id} = $sense;
}

# Iterate through the key file, and test each provided answer against the stored answers.
while( my $line = <$fhKey> ) {

    # Parse out id and sense using regex.
    my($id) = $line =~ /instance="([^"]*)"/;
    my ($sense) = $line =~ /senseid="([^"]*)"/;

    # If the id was not found in the answers file earlier, then there is a problem. This key file does not
    # correctly match the answers file, and we need to shut down.
    if( !exists $answers{$id} ) {
        die "There is an error matching id found in key: $id";
    }

    # If the sense is correct, increment correct count.
    if( $sense eq $answers{$id} ) {
        $correct++;
    }
    # Increment total count.
    $total++;

    # Store the key->guess pair.
    if( exists $confusionMatrix{$sense}{$answers{$id}} ) {
        $confusionMatrix{$sense}{$answers{$id}}++;
    }
    else {
        $confusionMatrix{$sense}{$answers{$id}} = 1;
    }
}

# Print #correct, #total, and accuracy.
my $accuracy = $correct / $total;
print "correct:     $correct\n";
print "total:       $total\n";
print "accuracy:    $accuracy\n\n";

# Print confusion matrix.
print "CONFUSION MATRIX\n";
print "KEY is the correct sense, after which, sense predictions are shown in a comma delimited list. Counts are shown next to senses.\n\n";
for my $key (keys %confusionMatrix) {
    print "KEY=$key: " ;
    my $first = 1;
    for my $guess (keys %{ $confusionMatrix{$key} }) {
        my $count = $confusionMatrix{$key}{$guess};
        if( $first == 0) {
            print ", ";
        }
        print "($count)$guess";
        $first == 0;
    }
    print "\n";
}
