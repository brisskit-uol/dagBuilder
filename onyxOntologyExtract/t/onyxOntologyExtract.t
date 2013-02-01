#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
use FindBin;
mkdir "$FindBin::Bin/output";
system "chmod u+rw $FindBin::Bin/output";
unlink "$FindBin::Bin/output/code_file.txt";

system "perl onyxOntologyExtract.pl $FindBin::Bin/input/TestQuestionnaire.zip -o $FindBin::Bin/output";
open CODE, "$FindBin::Bin/output/code_file.txt";
my @lines = ();

my %nom_codes = ();
my %codes = ();
my $nom_dups = undef;
while ( chomp( my $line = <CODE> || "" ) ) {
	my @fields = split( "\t", $line );
	my $code = $fields[3];
	#only check nominal codes are not duplicate -> ok to use duplicate ontology codes
	if ($code=~/^CBO\:/) {
		$nom_codes{$code} and $nom_dups=1;
		$nom_codes{$code}=\@fields;
	}
	$codes{$fields[0]."|".$fields[1]}=\@fields;
}

ok !$nom_dups, "No nominal code duplicates";

#check nominal boolean line
is_deeply($codes{"UNKNOWN|RiskFactorTobacco.EVER_SMOKED.YES"},
	[
		"UNKNOWN",           "RiskFactorTobacco.EVER_SMOKED.YES",
		"TestQuestionnaire", "CBO:1e3369ee92ea1c2d63092b3f2bc290e7",
		"BOOLEAN"
	]
,"Check nominal boolean");

#check DK value
is_deeply( $codes{"UNKNOWN|RiskFactorAlcohol.EVER_DRUNK_ALCOHOL.DK"},
["UNKNOWN","RiskFactorAlcohol.EVER_DRUNK_ALCOHOL.DK","TestQuestionnaire","CBO:45a6d5328bdb6bfa450a25881f81d182","BOOLEAN"],"Check DK value");

#check line with SNOMED and nominal line
is_deeply( $codes{"UNKNOWN|RiskFactorTobacco.EVER_SMOKED.NO"},
	[ "UNKNOWN", "RiskFactorTobacco.EVER_SMOKED.NO", "TestQuestionnaire", "SM:266919005", "BOOLEAN" ],"Check nominal SNOMED boolean" );

is_deeply( $codes{"1353|266919005"},
	[ "1353", "266919005", "SNOMED-CT", "SM:266919005", "BOOLEAN" ],"Check SNOMED boolean" );

#check icd10 line
is_deeply( $codes{"1516|I00-I99.9"},
	[ "1516", "I00-I99.9", "ICD10", "IC:I00-I99.9", "BOOLEAN" ],"Check ICD10 boolean") ;

#check loinc line
is_deeply( $codes{"1350|19787-1"},
	[ "1350", "19787-1", "LOINC", "LC:19787-1", "BOOLEAN" ],"Check LOINC boolean");

#check answer with only open value has two lines (one for nominal and one for sNOMED) both with the same code
is_deeply($codes{"UNKNOWN|RiskFactorAlcohol.AGE_BEGAN_DRINKING.AMOUNT.VALUE"},
["UNKNOWN","RiskFactorAlcohol.AGE_BEGAN_DRINKING.AMOUNT.VALUE","TestQuestionnaire","SM:228328008","INTEGER"]
,"Check nominal open value");
is_deeply($codes{"1353|228328008"},
["1353","228328008","SNOMED-CT","SM:228328008","INTEGER"]
,"Check ontology mapping for open value");

#check answer with open value has two lines (nominal and SNOMED) when other options, both with same code
is_deeply($codes{"UNKNOWN|RiskFactorOtherTobacco.PIPE_CONSUMPTION_WEEK.AMOUNT.VALUE"},
["UNKNOWN","RiskFactorOtherTobacco.PIPE_CONSUMPTION_WEEK.AMOUNT.VALUE","TestQuestionnaire","SM:230058003","INTEGER"]
,"Check nominal open value with other categories");
is_deeply($codes{"1353|230058003"},
["1353","230058003","SNOMED-CT","SM:230058003","INTEGER"]
,"Check ontology mapping for open value with other categories");

#check answer with only open value has two lines (nominal and SNOMED) both with same code
is_deeply($codes{"UNKNOWN|RiskFactorSocioeconomic.HOUSEHOLD_NUMBER.VALUE.PEOPLE"},
["UNKNOWN","RiskFactorSocioeconomic.HOUSEHOLD_NUMBER.VALUE.PEOPLE","TestQuestionnaire","SM:224525003","INTEGER"]
,"Check nominal open value with other categories");
is_deeply($codes{"1353|224525003"},
["1353","224525003","SNOMED-CT","SM:224525003","INTEGER"]
,"Check ontology mapping for open value with other categories");

#check answer with only open value with no ontology extracted correctly (is md5 code correct?)
is_deeply($codes{"UNKNOWN|RiskFactorCigs.AGE_BEGAN_SMOKING.VALUE.VALUE"},
["UNKNOWN","RiskFactorCigs.AGE_BEGAN_SMOKING.VALUE.VALUE","TestQuestionnaire","SM:228488005","INTEGER"]
,"Check nominal open value with no ontology");


#check answer with open value + other categories with no ontology extracted correctly (is md5 code correct?)
is_deeply($codes{"UNKNOWN|RiskFactorTobacco.WHAT_SMOKED.OTHER.TEXT"},
["UNKNOWN","RiskFactorTobacco.WHAT_SMOKED.OTHER.TEXT","TestQuestionnaire","CBO:92dee9ecb7e9335d7342d5bbfae2fffe","TEXT"]
,"Check nominal open value with other categories with no ontology");
rmdir "$FindBin::Bin/output";
1;
