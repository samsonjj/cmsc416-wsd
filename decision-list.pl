# Author: Jonathan Samson
# Date: 3/26/19
# Class: CMSC-416-001 VCU Spring 2019
# Project: Programming Assignment 4
# Title: decision-list.pl
# 
#   One of Natural Language Processing's (NLP's) essential challenges is word sense disambiguation (WSD). Similar spellins of
# a single word often have different meanings. This can be seen in the dictionary, where most words have multiple
# definitions. For example, run can be used to describe quick physical linear movement on foot, or the action of running
# for a position in an organization. WSD takes up the issue of automatically distinguishing the particular definition, or sense,
# of a word in text. This project applies WSD techniques to distinguise between two sense of the word "line": that of a phone
# line, and that of a product line.
# 
# Example Input and Output:
# perl decision-list.pl line-train.txt line-test.txt my-decision-list.txt > my-line-answers.txt
#
# 1) Parse training file.
# 2) Create feature vector. Run each test and record successes vs actual sense.
# 3) Rank each test based on frequency counts.
# 4) Parse test file.
# 5) Create feature vector. Run each test, create test vector, and check which one succeeded first based on ranking. Choose that sense.
# 6) If no test passes, return default.

use strict;
use warnings;
use feature 'say';

my %bagOfWords = ();

my $argCount = scalar @ARGV;
if($argCount < 3) {
    die "You must enter 3 arguments for train, test, and log file."
}

my $trainingFile = $ARGV[0];
my $testingFile = $ARGV[1];
my $logFile = $ARGV[2];

#################### (1) ####################
# Parse Training file.

# Open training file.
open(my $fhTrain, "<:encoding(UTF-8)", $trainingFile)
    or die "Could not open file '$trainingFile' $!";

# Assume each tag (Ex: "<instance>" is contained on the same line), so not like "<ins\ntance>".
# Assume each line only has one tag

my $currentInstance = "";

# Parse into each "instance".
while( my $line = <$fhTrain> ) {

    chomp $line;

    # Check for <instance> tag.
    if($line =~ /.*<\s*instance\s*(.*)>(.*)/) {
        $currentInstance = $2;
    }
    # Check for </instance> tag
    elsif ($line =~ /(.*)<\/\s*instance\s*(.*)>(.*)/ ) {
        $currentInstance = $currentInstance."\n".$1;

        # Process currentInstance
        my($correctSense) = $currentInstance =~ /<answer.*senseid="(.*)"/;

        my($context) = $currentInstance =~ /<context>(.*)<\/context>/s;
        $context =~ s/(<s>|<\/s>|<@>|<p>|<\/p>)//g;
        $context =~ s/([,\.!\?"])/ $1 /g;
        my @tokens = split(/\s+/, $context);

        # We now need to create a feature vector for this context.
        # We can do this with any set of features we want.
        # Most of the features will be searching the "bag of word" for certain key words.
        # Some other features will do different things.

        for my $word (@tokens) {
            if( !exists $bagOfWords{$word}{$correctSense} ) {
                $bagOfWords{$word}{$correctSense} = 1;
            }
            else {
                $bagOfWords{$word}{$correctSense}++;
            }
        }

        $currentInstance = "";
    }
    # Otherwise, we are inbetween instance tags, so add all text to current instance.
    else {
        $currentInstance = $currentInstance."\n".$line;
    }
}

my $defaultSense = "";
for my $word (sort keys %bagOfWords) {
    my $countSum = 0;
    my $maxKeyCount = 0;
    my $maxKey = "";
    for my $sense (sort keys %{ $bagOfWords{$word} }) {
        $countSum += $bagOfWords{$word}{$sense};
        # print $bagOfWords{$word}{$sense};
        if( $bagOfWords{$word}{$sense} > $maxKeyCount ) {
            $maxKeyCount = $bagOfWords{$word}{$sense};
            $maxKey = $sense;
        }
        $defaultSense = $sense;
    }
    $bagOfWords{$word}{"maxKey"} = $maxKey;
    $bagOfWords{$word}{"correctCount"} = $maxKeyCount;
    $bagOfWords{$word}{"totalCount"} = $countSum;
}

# my @rankedWords = sort {($bagOfWords{$b}{"correctCount"} / $bagOfWords{$b}{"totalCount"})
#                     cmp ($bagOfWords{$a}{"correctCount"} / $bagOfWords{$a}{"totalCount"})}
#                     sort keys %bagOfWords;

my @rankedWords = sort rankedSort (sort keys %bagOfWords);

my $rankedWordsLength = scalar @rankedWords;
for( my $i=0; $i<$rankedWordsLength; $i++ ) {
    my $word = $rankedWords[$i];
    my $correct = $bagOfWords{$word}{"correctCount"};
    my $total = $bagOfWords{$word}{"totalCount"};
    my $max = $bagOfWords{$word}{"maxKey"};
    if ($total < 3) {
        splice @rankedWords, $i, 1;
        $i--;
    }
    $rankedWordsLength = scalar @rankedWords;
}

for( my $i=0; $i<$rankedWordsLength; $i++ ) {
    my $word = $rankedWords[$i];
    my $correct = $bagOfWords{$word}{"correctCount"};
    my $total = $bagOfWords{$word}{"totalCount"};
    my $max = $bagOfWords{$word}{"maxKey"};
    # print "$word ($correct $total $max)\n";
}

# Open log file.
# open(my $fhLog, ">:encoding(UTF-8)", $logFile)
#     or die "Could not open file '$logFile' $!";

# my @featureDescriptions = getFeatureDescriptions();
# my $numTests = scalar @rankedTestIds;

# for( my $i=0; $i<$numTests; $i++) {
#     my $total =  $trainingCounts{$rankedTestIds[$i]}{"total"};
#     my $correct =  $trainingCounts{$rankedTestIds[$i]}{"correct"};

#     print $fhLog "Test $i: $featureDescriptions[$rankedTestIds[$i]]\n";
#     print $fhLog "# instances: $total\n";
#     print $fhLog "# correct: $correct\n";
# }

# my $mostCommonTag = "";
# my $mostFrequentTagBaselineAccuracy = 0;
# if( $totalPhone > $totalProduct ) {
#     $mostCommonTag = "phone";
#     $mostFrequentTagBaselineAccuracy = $totalPhone / ($totalPhone + $totalProduct);
# }
# else {
#     $mostCommonTag = "product";
#     $mostFrequentTagBaselineAccuracy = $totalProduct / ($totalPhone + $totalProduct);
# }
# print $fhLog "\n"."Baseline of most frequent tag in train file is $mostCommonTag with probability $mostFrequentTagBaselineAccuracy\n"; 


#################### (idk) ####################
# Tag the test file.

open(my $fhTest, "<:encoding(UTF-8)", $testingFile)
    or die "Could not open file '$testingFile' $!";

my $instanceId = "";
$currentInstance = "";

# Parse into each "instance".
while( my $line = <$fhTest> ) {

    chomp $line;

    # Check for <instance> tag.
    if($line =~ /.*<\s*instance\s*(.*)>(.*)/) {
        $currentInstance = $2;
        ($instanceId) = $line =~ /<instance.*id="(.*)"/;
    }
    # Check for </instance> tag
    elsif ($line =~ /(.*)<\/\s*instance\s*(.*)>(.*)/ ) {
        $currentInstance = $currentInstance."\n".$1;

        # Process currentInstance
        my($context) = $currentInstance =~ /<context>(.*)<\/context>/s;
        my $contextBackup = $context;
        $context =~ s/(<s>|<\/s>|<@>|<p>|<\/p>)//g;
        $context =~ s/([,\.!\?])/ $1 /g;
        my @tokens = split(/\s+/, $context);

        # We now need to create a feature vector for this context.
        # We can do this with any set of features we want.
        # Most of the features will be searching the "bag of word" for certain key words.
        # Some other features will do different things.

        print "<answer instance=\"$instanceId\" senseid=\"";

        my $senseFound = 0;
        for my $word (@rankedWords) {
            if( $context =~ /\Q$word/ ) {
                print $bagOfWords{$word}{"maxKey"};
                $senseFound = 1;
                last;
            }
        }
        $defaultSense = "phone";
        if( $senseFound == 0 ) {
            print $defaultSense;
        }
        print "\"/>\n";
        $currentInstance = "";
    }
    # Otherwise, we are inbetween instance tags, so add all text to current instance.
    else {
        $currentInstance = $currentInstance."\n".$line;
    }
}

sub rankedSort {
    if( ($bagOfWords{$b}{"correctCount"} / $bagOfWords{$b}{"totalCount"})
    == ($bagOfWords{$a}{"correctCount"} / $bagOfWords{$a}{"totalCount"}) ) {
        return $bagOfWords{$b}{"correctCount"} - $bagOfWords{$a}{"correctCount"};
    }
    else {
        return ($bagOfWords{$b}{"correctCount"} / $bagOfWords{$b}{"totalCount"})
            cmp ($bagOfWords{$a}{"correctCount"} / $bagOfWords{$a}{"totalCount"}); 
    }
}