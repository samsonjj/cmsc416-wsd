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

# trainingCounts keeps track of total frequency of features and the frequency of their successful prediction
my %trainingCounts = ();

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
        $context =~ s/([,\.!\?])/ $1 /g;
        my @tokens = split(/\s+/, $context);

        # We now need to create a feature vector for this context.
        # We can do this with any set of features we want.
        # Most of the features will be searching the "bag of word" for certain key words.
        # Some other features will do different things.

        my @featureVector = generateFeatureVector(@tokens);

        # Iterate through each feature and update "total" and "correct" counts;
        my $featureLength = scalar @featureVector;
        for( my $i=0; $i<$featureLength; $i++) {
            if( !exists $trainingCounts{$i}{"id"} ) {
                $trainingCounts{$i}{"id"} = $i;
            }
            if( !exists $trainingCounts{$i}{"total"} ) {
                $trainingCounts{$i}{"total"} = 0;
            }
            if( !exists $trainingCounts{$i}{"correct"} ) {
                $trainingCounts{$i}{"correct"} = 0;
            }
            if( $featureVector[$i] ne 0 ) {
                $trainingCounts{$i}{"total"}++;
            }
            if( $featureVector[$i] eq $correctSense ) {
                $trainingCounts{$i}{"correct"}++;
            }
        }

        $currentInstance = "";
    }
    # Otherwise, we are inbetween instance tags, so add all text to current instance.
    else {
        $currentInstance = $currentInstance."\n".$line;
    }
}

my @rankedTestIds = sort {($b->{"correct"} / $b->{"total"})
                    cmp ($a->{"correct"} / $a->{"total"})}
                    values %trainingCounts;

@rankedTestIds = map { $_->{"id"} } @rankedTestIds;

# for my $key (sort keys %trainingCounts) {
#     my $total = $trainingCounts{$key}{total};
#     my $correct = $trainingCounts{$key}{correct};
#     print "$key: $total, $correct\n";
# }

# print join ", ", @rankedTestIds;



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

        my @featureVector = generateFeatureVector(@tokens);


        my $numTests = scalar @rankedTestIds;
        my $senseFound = 0;
        print "<answer instance=\"$instanceId\" senseid=\"";
        for( my $i=0; $i<$numTests; $i++ ) {
            my $testFeatureId = $rankedTestIds[$i];
            if( $featureVector[$testFeatureId] ne 0) {
                print $featureVector[$testFeatureId];
                $senseFound = 1;
                last;
            }
        }
        if( $senseFound == 0 ) {
            print "product";
        }
        print "\"/>\n";
        $currentInstance = "";
    }
    # Otherwise, we are inbetween instance tags, so add all text to current instance.
    else {
        $currentInstance = $currentInstance."\n".$line;
    }
}

sub feature0 {
    if ( grep( /phone$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature1 {
    if ( grep( /^growth$/, @_ ) ) {
        return "product";
    }
    return 0;
}
sub feature2 {
    if ( grep( /^business$/, @_ ) ) {
        return "product";
    }
    return 0;
}
sub feature3 {
    if ( grep( /^call$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature4 {
    if ( grep( /^economy$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature5 {
    if ( grep( /^transmit$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature6 {
    if ( grep( /^wire$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature7 {
    my $len = scalar @_;
    for( my $i=0; $i<$len; $i++ ) {

    }
    if ( grep( /phone$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature8 {
    if ( grep( /^wire$/, @_ ) ) {
        return "phone";
    }
    return 0;
}
sub feature9 {
    if ( grep( /^product$/, @_ ) ) {
        return "product";
    }
    return 0;
}
sub feature9 {
    if ( grep( /^money$/, @_ ) ) {
        return "product";
    }
    return 0;
}
sub feature10 {
    if ( grep( /^model$/, @_ ) ) {
        return "product";
    }
    return 0;
}
sub generateFeatureVector {
    my @tokens = @_;

    my @featureVector = ();
    $featureVector[0] = feature0(@tokens);
    $featureVector[1] = feature1(@tokens);
    $featureVector[2] = feature2(@tokens);
    $featureVector[3] = feature3(@tokens);
    $featureVector[4] = feature4(@tokens);
    $featureVector[5] = feature5(@tokens);
    $featureVector[6] = feature6(@tokens);
    $featureVector[7] = feature7(@tokens);
    $featureVector[8] = feature8(@tokens);
    $featureVector[9] = feature9(@tokens);
    # $featureVector[10] = feature10(@tokens);

    return @featureVector;
}