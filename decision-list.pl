# Author: Jonathan Samson
# Date: 3/28/19
# Class: CMSC-416-001 VCU Spring 2019
# Project: Programming Assignment 4
# Title: decision-list.pl
#
#--------------------------------------------------------------------------
#   Problem Statement
#--------------------------------------------------------------------------
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
# This is a perl program, so some version of perl must be installed before executing the file.
# See: https://www.perl.org/get.html
#
# To run the program, make sure you have a correclty training file and test file which match the format shown in the example
# after this section. Execute the program with those two files as arguments, as well as a third argument for the desired
# name of the log file, generated during program execution. The command should look as follows
#
#   perl decision-list.pl <training-file> <test-file> <log-file>
#
# During execution, the log file will be generated which details the list of tests (or decision list) which were used to
# disambiguate between word senses. Additionally, a set of answers will be printed to standard output.
#
# Below is a sample run of the program.
#
# [IN-COMMAND] perl decision-list.pl line-train.txt line-test.txt my-decision-list.txt > my-line-answers.txt
#
# [IN-TRAINFILE]
#   <corpus lang="en">
#   <lexelt item="line-n">
#   <instance id="line-n.w9_10:6830:">
#   <answer instance="line-n.w9_10:6830:" senseid="phone"/>
#   <context>
#   <s> The New York plan froze basic rates, offered no protection to Nynex against an economic downturn that sharply cut demand and didn't offer flexible pricing. </s> <@> <s> In contrast, the California economy is booming, with 4.5% access <head>line</head> growth in the past year. </s> 
#   </context>
#   </instance>
#   <instance id="line-n.w8_057:16550:">
#   <answer instance="line-n.w8_057:16550:" senseid="product"/>
#   <context>
#   <s> According to analysts, sales of PS/2 got off to a rocky start but have risen lately -- especially in Europe. </s> <@> <s> IBM wants to establish the <head>line</head> as the new standard in personal computing in Europe. </s> <@> <s> It introduced the line in April 1987 and has said it shipped nearly two million units by its first anniversary. </s> 
#   </context>
#   ...
#
# [IN-TESTFILE]
#   <corpus lang="en">
#   <lexelt item="line-n">
#   <instance id="line-n.w8_059:8174:">
#   <context>
#   <s> Advanced Micro Devices Inc., Sunnyvale, Calif., and Siemens AG of West Germany said they agreed to jointly develop, manufacture and market microchips for data communications and telecommunications with an emphasis on the integrated services digital network. </s> <@> </p> <@> <p> <@> <s> The integrated services digital network, or ISDN, is an international standard used to transmit voice, data, graphics and video images over telephone <head>lines</head> . </s> 
#   </context>
#   </instance>
#   <instance id="line-n.w7_098:12684:">
#   <context>
#   ...
#
# [IN-KEYFILE]
#   <answer instance="line-n.w8_059:8174:" senseid="phone"/>
#   <answer instance="line-n.w7_098:12684:" senseid="phone"/>
#   <answer instance="line-n.w8_106:13309:" senseid="phone"/>
#   <answer instance="line-n.w9_40:10187:" senseid="phone"/>
#   <answer instance="line-n.w9_16:217:" senseid="phone"/>
#   ...
#
# [OUT-STDOUT]
#   <answer instance="line-n.w8_059:8174:" senseid="phone"/>
#   <answer instance="line-n.w7_098:12684:" senseid="phone"/>
#   <answer instance="line-n.w8_106:13309:" senseid="phone"/>
#   <answer instance="line-n.w9_40:10187:" senseid="phone"/>
#   <answer instance="line-n.w9_16:217:" senseid="phone"/>
#   ...
#
# [OUT-LOGFILE]
#   LOG [generated by decision-list.pl]
#
#   Below is a description of each test (feature) of the decision-list which was used to disambiguate the test-file in the last run of decision-list.pl.
#   Any feature marked as 'BAG' was tested by searching the context for the given word.
#
#   [FEATURE]             (BAG) telephone
#   [CORRECT]             74
#   [TOTAL]               74
#   [LOG-LIKELIHOOD]      1
#   [SENSE]               phone
#   ...
#
#--------------------------------------------------------------------------
#   Algorithm
#--------------------------------------------------------------------------
#
# Below is a description of the structure of this program and its algorithm.
# The main idea is to use a decision-list made of bagOfWords tests. These
# tests search the context for a certain word, and if found, tag the instance
# with a certain sense. The words, senses, and order of these tests are built
# while looking through the training file.
#
# 1) Parse training file using regex.
#       * Store the context as a string, removing extraneous tags.
#           * In order to do this, we go through each line in the text, storing it beginning when we find an <instance> tag
#             and stopping when we find a </instance> tag. Then we use regex to obtain the text within the context tags.
#       * Retreive the sense which this context is tagged with.
#       * Store (in the bagOfWords hash) the number of times each word appears with each sense.
# 2) For each word, calculate the sense which it appears with the most, the number of times it occured with that sense,
#    and the number of times it occured in total.
# 3) Rank each word, so that we have an ordering for usage in the decision-list tests.
#       * Sort words with higher prediction accuracies first. If accuracy is the same, then sort by higher frequency first.
# 4) Perform word-sense disambiguation on the test file, and display answers on STDOUT.
#       * We accomplish this by testing the context for each of our trained bag-of-words tests, and on success, printing the
#         approiate sense.
#       * If none of the words are found within the context, print the default sense.


use strict;
use warnings;
use feature 'say';

# This is a two-dimensional hash which uses as keys the words found within training contexts,
# and stores a dictionary of its associated senses and frequencies as values.
my %bagOfWords = ();

# Obtain the file names from the command line arguments.
my $argCount = scalar @ARGV;
if($argCount < 3) {
    die "You must enter 3 arguments for train, test, and log file."
}
my $trainingFile = $ARGV[0];
my $testingFile = $ARGV[1];
my $logFile = $ARGV[2];

#--------------------------------------------------------------------------
#   (1) Parse the training file using regex.
#--------------------------------------------------------------------------

# Open training file.
open(my $fhTrain, "<:encoding(UTF-8)", $trainingFile)
    or die "Could not open file '$trainingFile' $!";

# Assume each tag (Ex: "<instance>") is contained on the same line, so not like "<ins\ntance>".
# Assume each line only has one tag.

# Stores the text of each instance, as we go from traverse each instance in the following while loop.
my $currentInstance = "";

# Parse into each "instance".
while( my $line = <$fhTrain> ) {

    chomp $line;

    # | We will be storing lines until we have all the lines of a single instance.
    # | So in order to do this, we check for instance tags within the text, and take appropriate action.

    # Check for <instance> tag. If found, store the text (without the tag).
    if($line =~ /.*<\s*instance\s*(.*)>(.*)/) {
        $currentInstance = $2;
    }

    # Check for </instance> tag. If found, store text before the tag, and then process the instance.
    elsif ($line =~ /(.*)<\/\s*instance\s*(.*)>(.*)/ ) {

        $currentInstance = $currentInstance."\n".$1;

        # Process currentInstance.

        # Get the sense.
        my($correctSense) = $currentInstance =~ /<answer.*senseid="(.*)"/;

        # Get a list of tokens within the context, not including tags.
        my($context) = $currentInstance =~ /<context>(.*)<\/context>/s;
        $context =~ s/(<s>|<\/s>|<@>|<p>|<\/p>)//g;
        $context =~ s/([,\.!\?"])/ $1 /g;
        my @tokens = split(/\s+/, $context);

        # Increment the count of each word->sense pair as we iterate through each word in the context.
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

#--------------------------------------------------------------------------
#   (2) For each word, calculate the sense which it appears with the most,
#       the number of times it occured with that sense, and the number of
#       times it occured in total.
#--------------------------------------------------------------------------

# This is the sense which will be predicted if no test on the decision list succeeds.
my $defaultSense = "";

# Iterate through each word.
for my $word (sort keys %bagOfWords) {

    # Total count of this word's appearances.
    my $countSum = 0;
    # Count of times the max sense has occured with this word.
    my $maxSenseCount = 0;
    # Which sense has occured with this word the most.
    my $maxSense = "";
    
    # Iterate through each sense which the word appears with.
    for my $sense (sort keys %{ $bagOfWords{$word} }) {

        # Increment total count.
        $countSum += $bagOfWords{$word}{$sense};

        # If we find a new max, store it and its count.
        if( $bagOfWords{$word}{$sense} > $maxSenseCount ) {
            $maxSenseCount = $bagOfWords{$word}{$sense};
            $maxSense = $sense;
        }
        $defaultSense = $sense;
    }

    # Store the calculated values within hash.
    $bagOfWords{$word}{"maxKey"} = $maxSense;
    $bagOfWords{$word}{"correctCount"} = $maxSenseCount;
    $bagOfWords{$word}{"totalCount"} = $countSum;
}

#--------------------------------------------------------------------------
#   (3) Rank each word, so that we have an ordering for usage in the 
#       decision-list tests.
#--------------------------------------------------------------------------

# Rank the words based off of their accuracy.
my @rankedWords = sort rankedSort (sort keys %bagOfWords);

# The sorting function for word rankings. Sorts by accuracy, but if accuracy is the same sorts by frequency. 
sub rankedSort {
    # Check if accruacy is same, if so sort by frequency.
    if( ($bagOfWords{$b}{"correctCount"} / $bagOfWords{$b}{"totalCount"})
    == ($bagOfWords{$a}{"correctCount"} / $bagOfWords{$a}{"totalCount"}) ) {
        return $bagOfWords{$b}{"correctCount"} - $bagOfWords{$a}{"correctCount"};
    }
    # Sort by accuracy.
    else {
        return ($bagOfWords{$b}{"correctCount"} / $bagOfWords{$b}{"totalCount"})
            cmp ($bagOfWords{$a}{"correctCount"} / $bagOfWords{$a}{"totalCount"}); 
    }
}

my $rankedWordsLength = scalar @rankedWords;

#--------------------------------------------------------------------------
#   (4) Create log file which contains descriptions of each of the
#       tests used, their log likelihood, and predicted sense.
#--------------------------------------------------------------------------

# Open log file.
open(my $fhLog, ">:encoding(UTF-8)", $logFile)
    or die "Could not open file '$logFile' $!"; 

# Print our newly defined decision list to the log file.
# Include description of feature, log-likelihood score, and predicted sense.
print $fhLog "LOG [generated by decision-list.pl]\n\n";
print $fhLog "Below is a description of each test (feature) of the decision-list which was used to disambiguate the test-file in the last run of decision-list.pl.\n";
print $fhLog "Any feature marked as 'BAG' was tested by searching the context (bag of words) for the given word.\n\n";

for( my $i=0; $i<$rankedWordsLength; $i++ ) {
    print $fhLog "[FEATURE ($i)]             (BAG) $rankedWords[$i]\n";
    my $correct = $bagOfWords{$rankedWords[$i]}{"correctCount"};
    my $total = $bagOfWords{$rankedWords[$i]}{"totalCount"};
    print $fhLog "[CORRECT]             $correct\n";
    print $fhLog "[TOTAL]               $total\n";
    my $logLikelihood = 1;
    if( $total != $correct) {
        $logLikelihood = abs(log($correct / ($total - $correct)));
    }
    print $fhLog "[LOG-LIKELIHOOD]      $logLikelihood\n";
    my $sense = $bagOfWords{$rankedWords[$i]}{"maxKey"};
    print $fhLog "[SENSE]               $sense\n\n";
}

#--------------------------------------------------------------------------
#   (4) Perform word-sense disambiguation on the test file, and display
#       answers on STDOUT.
#--------------------------------------------------------------------------

# Open test file.
open(my $fhTest, "<:encoding(UTF-8)", $testingFile)
    or die "Could not open file '$testingFile' $!";

# Stores the text of each instance, as we go from traverse each instance in the following while loop.
$currentInstance = "";

# Store the current instance id, necessary for answer printouts.
my $instanceId = "";

# Parse into each "instance".
while( my $line = <$fhTest> ) {

    chomp $line;

    # | We will be storing lines until we have all the lines of a single instance.
    # | So in order to do this, we check for instance tags within the text, and take appropriate action.

    # Check for <instance> tag. If found, store the text (without the tag).
    if($line =~ /.*<\s*instance\s*(.*)>(.*)/) {
        $currentInstance = $2;
        ($instanceId) = $line =~ /<instance.*id="(.*)"/;
    }
    # Check for </instance> tag. If found, store text before the tag, and then process the instance.
    elsif ($line =~ /(.*)<\/\s*instance\s*(.*)>(.*)/ ) {
        $currentInstance = $currentInstance."\n".$1;

        # Process currentInstance.

        # Store the context string, removing extraneous tags.
        my($context) = $currentInstance =~ /<context>(.*)<\/context>/s;
        $context =~ s/(<s>|<\/s>|<@>|<p>|<\/p>)//g;
        $context =~ s/([,\.!\?])/ $1 /g;

        # Get a list of tokens within the context.
        my @tokens = split(/\s+/, $context);

        # Print out beginning of answer.
        print "<answer instance=\"$instanceId\" senseid=\"";

        # Iterate through rankedWords (decision-list), and once one is found within the context, print out the associated sense.
        my $senseFound = 0;
        for my $word (@rankedWords) {
            if( $context =~ /\Q$word/ ) {
                print $bagOfWords{$word}{"maxKey"};
                $senseFound = 1;
                last;
            }
        }
        # If none of the tests pass, print the default sense.
        if( $senseFound == 0 ) {
            print $defaultSense;
        }
        
        # Finish answer printout.
        print "\"/>\n";
        $currentInstance = "";
    }

    # Otherwise, we are inbetween instance tags, so add all text to current instance.
    else {
        $currentInstance = $currentInstance."\n".$line;
    }
}