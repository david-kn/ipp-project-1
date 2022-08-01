#!/usr/bin/env perl 
#SYN:xkonar07
#SYN:xkonar07

##### TO DO:
# dokumentace
# negace - práce s "!"
# načítání ze STDIN			==> 90% OK
# prázdný formátovací soubor
# test argumentů     			==> 90% OK
# výpoěda nápovědy při --help 	==> 99% OK
# funkční regulární výrazy :D

use strict;
use warnings;            
use locale;
use utf8;
use Getopt::Long;

### Definition of subroutines

# Print stderr message
sub printError {
	print STDERR "A:".$_[0]."\n";
	exit($_[1])
}

sub printHelp {
	print "Projekt 1 do predmetu IPP\n";
	print "Autor: David Koňař\t Kontakt: xkonar07\@stud.fit.vutbr.cz\n\n";
	print "Program zpracovava formatovaci soubor (volitelny) a na jeho zaklade preformatuje vstupni data na vystupni\n";
	print "Priklady uziti:\n";
	print "\tperl proj1.pl --input=fileToRead.txt --format=formattingFile.txt\n";
	print "\tperl proj1.pl --format=formattingFile.txt --output=file.out\n";
	print "\tperl proj1.pl --input=fileToRead.txt --format=formattingFile.txt --output=file.output --br\n";
}

# trim the string from white characters
sub trim {
	$_[0] =~ s/^\s+//;
	$_[0] =~ s/\s+$//;
	return $_[0];
}

## Global
my $file_in = "";

my $arg_num = @ARGV;
my $help = 0; 
my $input = "";
my $format = "";
my $output = "";
my $input_num = 0;
my $format_num = 0;
my $output_num = 0; 
my $br = 0;

## Arguments' control
# Control whether there is not any mistake in parametres. If so, print error

foreach my $data (@ARGV) {
  	my @val = split('=', $data);
	if($val[0] eq "--input")  {
    		$input_num = $input_num + 1;
  	}
	if($val[0] eq "--format")  {
		$format_num = $format_num + 1;
	}
	if($val[0] eq "--output")  {
		$output_num = $output_num + 1;
	}
	if($val[0] eq "--br")  {
		$br = $br + 1;
	}
	if($val[0] eq "--help")  {
    	$help = $help + 1;
  }
}   

if($input_num > 1 || $format_num > 1 || $output_num > 1 || $br > 1 || $help > 1) {
	if($help > 0) {
	 	printHelp();
	}
  	printError("Spatne (opakujici se) zadana argumenty (0x1)", 1); 
} 

if($help > 0) {
	printHelp();
	exit(0);
}
             
      
# Invalid number of arguments
if (@ARGV > 4) {  
	printError("Spatne pocet argumentu (0x1)", 1);    
}

GetOptions ('help+' => \$help, "input=s" => \$input, "output=s" => \$output, "format=s" => \$format, "br+" => \$br) or printError("Spatne zadane argumenty (0x3)", 1);

### process arguments
# other(s) but --help argument was used; exit
if (($arg_num > 1 && $help == 1)) {
	printHelp();
	printError("Koncim - help + jine argumenty.", 1);
}


###tiskne parametry a jejich zpracovani
#print "$arg_num\n";
#print "help = $help\n";
#print "input = $input\n";
#print "output = $output\n";
#print "format = $format\n";
#print "br = $br\n";

### Handling files
# INPUT file, if it nos defined, use STDIN
if ($input ne "")  {
    if (!(-e $input || -r $input)) {
    	printError("Soubor pro cteni dat neexistuje nebo nelze cist\n", 2);
    }
    open(DATA_IN, "<$input");
    $file_in = join('', <DATA_IN>);
    
} 
else {
	my @userinput = <STDIN>;
	$file_in = join('', @userinput);
}

# FORMAT file - if it is set, open it
if ($format ne "")  {
    if (!(-e $format || -r $format)) {
		printError("Soubor pro format dat neexistuje nebo nelze cist\n", 2);
    }
    open(DATA_FORMAT, "<$format");  
}
if ($output ne "") {
    open(DATA_OUT, ">$output");
    if (!(-e $output || -w $output)) {
        printError("Soubor pro vystup dat nelze otevrit\n", 3);
    }
    #print DATA_OUT "HAHAH\n";
}

## Processing the 'format file'
my @posS = (); 
my @posE = ();
my @tagS = ();
my @tagE = ();     

  
my $file_out = $file_in;
my $line;
my @arr;
my $str;
my $str2 = "";
my $regexp;

### vypise vstupni data
# print "IN:".$file_in."\n\n";   

# FORMAT file - if it is set, parse it! It was opened a few lines above
if ($format ne "") {
	foreach $line (<DATA_FORMAT>) {
	    chomp($line);              # remove end-of-line character
	    
	      # if the line is empty go for another
	      unless($line)  {
			next;
	      }
	       
		 # split the format file into 2 pieces: regexp and formating info 
	      #if($line =~ (m/^(.*[^\t])(\t[^a-zA-Z0-9,])(.*)/g))
	      if($line =~ (m/^([^\t]*)(.*)/))		 {
			my $var1 = defined $1 ? $1 : 0;
			my $var2 = defined $2 ? $2 : 0;
			
			### rozdeli formatovaci soubor na REGEXP na formatovaci prikazy 
#			print "==>$var1:$var2\n";   		
			@arr = split(',', $var2);
			$regexp = $var1;
		} else {
		 	printError("Prazdny prikaz - spatna forma", 4);	
		}
		
		my $tagStart = "";
		my $tagEnd = "";
		
		# substitue format info with valid HTML tags + verification	
		foreach $str (@arr) {
			# erase whitespaces
			trim($str);
			
			## prubezna kontrola - jaky formatovaci prikaz se zpracovava
#			print "\t\t> ".$str."\n";
			
			# if tha tag is empty -> error
			unless($str) {
				printError("Prazdny prikaz - prazdny", 4);
			}
				
			if($str eq "bold") {
				$str =~ s/bold/<b>/;
				$tagEnd =  "</b>" . $tagEnd;
			}
			elsif ($str eq "italic") {
			      $str =~ s/italic/<i>/;
			      $tagEnd = "</i>" . $tagEnd;
			}
			elsif ($str eq "teletype") {
			      $str =~ s/teletype/<tt>/;
			      $tagEnd = "</tt>" . $tagEnd;
			}
			elsif ($str eq "underline") {
			      $str =~ s/underline/<u>/;
			      $tagEnd = "</u>" . $tagEnd;
			}
			elsif ($str =~ /size:([1-7])/) {
				#$str =~ s/size:([1-7]/<u>/;
				my $var1 = defined $1 ? $1 : 0;
				$str =~ s/size:/<font size=/;
			      $str = $str . ">";   
			      $tagEnd =  "</font>" . $tagEnd;
			}
			elsif ($str =~ /color:[0-9A-F]{6}$/) {
				my $var1 = defined $1 ? $1 : 0;
				$str =~ s/color:/<font color=#/;
				$str = $str . ">";
				$tagEnd = "</font>" . $tagEnd;
			}
			# if unknown format word was used => end!
			 else {
				printError("Neplatny prikaz:1", 4);		
			}
			$tagStart = $tagStart . $str;
		}
		
		################
		## transform REGEXP from school definitions to Perl definitios		
		
		# special escape sequences for characters: ".|!*+()"
		$regexp =~ s/\\/\\\\/g;
		
		$regexp =~ s/\[/\\[/g;
		$regexp =~ s/\]/\\]/g;
		$regexp =~ s/\^/\\^/g;
		$regexp =~ s/\{/\\{/g;
		$regexp =~ s/\}/\\}/g;
		$regexp =~ s/\?/\\?/g;
		$regexp =~ s/\$/\\\$/g;
		
		
		$regexp =~ s/\!(%[a|s|d|l|L|w|W|t|n])/\[\^$1\]/g;
		$regexp =~ s/\!(.)/\[\^$1\]/g;
		$regexp =~ s/%\./\\\./g;
		$regexp =~ s/%\!/\\\!/g;
		# $regexp =~ s/%\|/\\\|/g; ## ???
		$regexp =~ s/%\*/\\\*/g;
		$regexp =~ s/%\+/\\\+/g;
		$regexp =~ s/%\|/\\|/g;
		$regexp =~ s/%\(/\\\(/g;
		$regexp =~ s/%\)/\\\)/g;
		
		
		

		
	
		# special escape sequence for "%%" 	
		$regexp =~ s/%%/\[\[__%__\]\]/g;
		
		# delete unnescessary dot '.' - it cannot be part of '\.'
		$regexp =~ s/(.*[^\\])\.(.*)/$1$2/g;
		
		
		#$regexp =~ s/\!(%[sadlLwWtn\!\.\|\*\+\(\)]){1}/\[\^$1\]/g;	
		#$regexp =~ s/\!(\S){1}/\[\^$1\]/g;
		
		 
		

		
		# substitue defined specific expression with the Perl ones
		$regexp =~ s/%s/\\s/g;
		## JEDNO NEBO DRUHE
			$regexp =~ s/%a/\./g;
			#$regexp =~ s/%a/\^.+\$/s;
			#$regexp =~ s/%a/\.\+/sg;	
		
		$regexp =~ s/%d/\\d/g;
		$regexp =~ s/%l/\[a-z]/g;
		$regexp =~ s/%L/\[A-Z]/g;
		$regexp =~ s/%w/\[a-zA-Z]/g;
		$regexp =~ s/%W/\[a-zA-Z0-9]/g;
		$regexp =~ s/%t/\\t/g;
		$regexp =~ s/%n/\\n/g;
		
	######### /// vecerni test
		# zabezpeceni proti neplatnym REGEXP vyrazum..
		if($regexp =~ m/\.\./g) {
			printError("Neplatny prikaz:2", 4);
		}
		
			
	
	
	######### /// vecerni test	
		$regexp =~ s/\[\[__%__\]\]/%/g;
#	      print "REG: ".$regexp."\n\n\n";
			
		### prubezny vypis: regexp , a vygenerovany otviraci a zaviraci tag
#		print "REG: ".$regexp."\nTag:".$tagStart." xxx " .$tagEnd."\n\n";
		
	
		while ($file_out =~ m/$regexp/gs) {
			### vypisuje pozice v textu
#			print "S: $-[0]\n";
#			print "K: $+[0]\n";
			if($+[0]-$-[0] != 0) { 			
				push(@posS, $-[0]); 
				push(@posE, $+[0]);
				push(@tagS, $tagStart);
				push(@tagE, $tagEnd);
			}       		 
	    }    
	}
}  ## parsing FORMAT file - END

my @sortedIndicesS = sort{ $posS[$a] <=> $posS[ $b ]} 0..$#posS;
my @sortedIndicesE = sort{ $posE[$a] <=> $posE[ $b ]} 0..$#posE;

@tagS = @tagS[ @sortedIndicesS ];
@posS = @posS[ @sortedIndicesS ];

@tagE = @tagE[ @sortedIndicesE ];
@posE = @posE[ @sortedIndicesE ];

#print "@posS : @posE\n";


my $arrSizeS = @posS - 1; 
my $arrSizeE = @posE - 1;

my $part1 = 0;
my $part2 = 0;
my $len = 0; 

#######################
### POUZ PRO VYPIS OBSAHU POLI PRO TESTY
#######################
#print "$arrSizeS : $arrSizeE\n\n";
while (0 <= $arrSizeS) {
#      print "$arrSizeS: $tagS[$arrSizeS]\n";
	$arrSizeS = $arrSizeS - 1;
}
$arrSizeS = @posS - 1; 
#print "\n\n";

while (0 <= $arrSizeS) {
#      print "$arrSizeS: $tagE[$arrSizeS]\n";
	$arrSizeS = $arrSizeS - 1;
}
$arrSizeS = @posS - 1;
#######################
##### KONEC - PO SEM SE MUZE SMAZAT
#######################

### mnozsvti vkladu
# print "S: \t $arrSize \n";
# print "\n////////////////////////////////////\n";

# Go from the end to the beginning and include the tags into the text
while (0 <= $arrSizeS) {
	$len = length $file_out;
  
  ### prubezna kontrola pozice a jaky tag tam ma by umisten
  #	print "\n";
  #	print "\t" . $pos[$arrSize] . "\n";
  #	print "\t" . $tag[$arrSize] . "\n";
#  	print "HOD: $posS[$arrSizeS] vs. $posE[$arrSizeE]\n";
#	print "IND: $arrSizeS vs. $arrSizeE\n";
#	print "--------------------------\n";
	if($arrSizeE >= 0) {
		# positions in the END scope are greater, place them in
		if($posS[$arrSizeS] < $posE[$arrSizeE]) {
			## nescessary ONLY for the cases when more END tags should be places at "one position"
			my $tmpLength = length $tagE[$arrSizeE];
			my $prevPos = $posE[$arrSizeE];
#			print "\tzapis E($arrSizeE:$posE[$arrSizeE]) - vetsi\n";
		 	$part1 = substr($file_out, 0, $posE[$arrSizeE]);
			$part2 = substr($file_out, $posE[$arrSizeE] ,$len);     	  
			$file_out = $part1 . $tagE[$arrSizeE] . $part2; 
#			print $file_out . "\n";
			
			$len = length $file_out;
			$arrSizeE = $arrSizeE - 1;
			
			# and keep doing it until the comparation changes or the scope is used 
			while (($posS[$arrSizeS] < $posE[$arrSizeE]) && ($arrSizeE >= 0)) {
#				print "\tzapis E($arrSizeE:$posE[$arrSizeE]) - vetsi pridano: $tmpLength; delka: $len\n";
				## if the positions of tags are different then adding $tmpLength is not nescessary
				if($prevPos != $posE[$arrSizeE]) {
				 	$tmpLength = 0;
				}
				$part1 = substr($file_out, 0, $posE[$arrSizeE]+$tmpLength);
				$part2 = substr($file_out, $posE[$arrSizeE]+$tmpLength ,$len);     	  
				$file_out = $part1 . $tagE[$arrSizeE] . $part2;
#				print $file_out . "\n";
				
				$len = length $file_out;
				$tmpLength = $tmpLength + length $tagE[$arrSizeE];
				$prevPos = $posE[$arrSizeE];				
				$arrSizeE = $arrSizeE - 1;
				#print "Ie:> $arrSizeE\n";
				#print $file_out . "\n";				     		
			}
	 		
		}
#		print "\n\tdosel WHILE: ";

#	  	print "\tHOD: $posS[$arrSizeS] vs. $posE[$arrSizeE]\n";
#		print "\tIND: $arrSizeS vs. $arrSizeE\n";
		
		# same values & and the END scope is still not empty, place 1 from the START
		if ($arrSizeE >= 0) {
#			print "\tzapis S($arrSizeS:$posS[$arrSizeS]) - shoda\n";
			$part1 = substr($file_out, 0, $posS[$arrSizeS]);
			$part2 = substr($file_out, $posS[$arrSizeS] ,$len);     	  
			$file_out = $part1 . $tagS[$arrSizeS] . $part2;
#			print $file_out . "\n";
			
			$len = length $file_out;
			$arrSizeS = $arrSizeS - 1; 		
		} 
		# END scope is used up; place a thing from the START scope
		else {
#			print "\tzapis S($arrSizeS:$posS[$arrSizeS]) - zacina sam\n";
		    	$part1 = substr($file_out, 0, $posS[$arrSizeS]);
			$part2 = substr($file_out, $posS[$arrSizeS] ,$len);     	  
			$file_out = $part1 . $tagS[$arrSizeS] . $part2;	
#			print $file_out . "\n";
			
			$len = length $file_out;
			$arrSizeS = $arrSizeS - 1;	
		}		
	}
	# place stuff from the START scope until the last item is reached
	if ($arrSizeE < 0 && $arrSizeS >= 0) {
#		print "\tzapis S($arrSizeS:$posS[$arrSizeS])-jede sam\n";
		$part1 = substr($file_out, 0, $posS[$arrSizeS]);
		$part2 = substr($file_out, $posS[$arrSizeS] ,$len);     	  
		$file_out = $part1 . $tagS[$arrSizeS] . $part2;	
#		print $file_out . "\n";
		
		$len = length $file_out;
		$arrSizeS = $arrSizeS - 1;
	}	
########################################################################šš
########################################################################šš	

	### prubezny vypis vkladani tagu
	#print $file_out . "\n";

}

# if the --br argument is ON, then add these tags into string
if ($br > 0) {
      $file_out =~ s/\n/<br \/>\n/g;
      #$file_out =~ s/\n$/<br \/>\n/g; # ??????????,	
}


close(DATA_IN);
close(DATA_FORMAT);

## print the output to a FILE  || on STDOUT
if($output_num eq 1) {
	print DATA_OUT $file_out;
	close(DATA_OUT);
}
else {
	print $file_out;
}

##print "\n////////////////////////////////////\n";


  



                     