#! /usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use Time::Local qw( timelocal_posix );
use List::Util qw( 
head tail uniqstr uniqnum uniq pairs any all none notall first max maxstr min minstr product sum sum0 pairs pairkeys pairvalues shuffle 
);

=pod
PREPLISH template file. 
Import and use. Make your own!
=cut



# list args
if (scalar(@ARGV)==0){ say "( ".__LINE__." No command-line args received. )"; }
#handle args that may be quoted
else {
	my $bMkStr=0;
	my @aArgs=();
	my @aTmp=();
	my $bDbg=1;
	say mksqbracks(__LINE__). "$0 argc=". scalar(@ARGV).", args: ". join(" ;; ", @ARGV);
	
	my @aSpltARGV=split(/\s+/,join(' ', @ARGV)); 

	say mksqbracks(__LINE__). "$0 rev argc=". scalar(@aSpltARGV).", args: ". join(" ;; ", @aSpltARGV);

	
	for my $arg (@aSpltARGV){

	 if( $arg =~ /^\"/ && $arg =~ /[^\"]$/) { $bMkStr =1; push @aTmp, $arg;	if($bDbg) { say mksqbracks(__LINE__). "start quoted arg $arg"; } }
	 elsif( $arg =~ /\"$/ && $arg =~ /^[^\"]/   ) { 
		$bMkStr = 0; push @aTmp, $arg; push @aArgs, join(" ", @aTmp); @aTmp=(); 
		if($bDbg) { say mksqbracks(__LINE__). "end quoted arg $arg"; }}
	 elsif( $bMkStr==1 ){ push @aTmp, $arg; if($bDbg) { say mksqbracks(__LINE__). "continue quoted arg $arg"; }}
	 else { push @aArgs, $arg; if($bDbg) { say mksqbracks(__LINE__). "add simple arg $arg"; }}	
		
	}
	
	say mksqbracks(__LINE__). "Received command-line args: ". join(" // ", @aArgs);  
	doArgTest01( @aArgs ) ; 
	doArgTest02( @aArgs );
}

package cZipCols {

	sub new {
	 my ($class,$col1,$col2)=@_;
	 my @cols=();
	 if ( scalar(@$col1)==scalar(@$col2) ) { push @cols, $col1; push @cols, $col2;  }
	 else { say "$class error, arrays of unequal size.";  return 0; } 
	 my $self = {  cols=>\@cols , colsize=> scalar(@$col1) , cTrue=>1, cFalse=>0  };
	 my $obj=bless $self,$class; 
	 return $obj;
	}
	
	
	sub sTrue { my $s=shift; return $s->{cTrue}; }
	sub sFalse { my $s=shift; return $s->{cFalse}; }
	sub getLength { my $s=shift; return $s->{colsize}; }
	sub addColArf { my ($s,$arf)=@_; 
		if (scalar(@$arf) != $s->{colsize}) { 
		say "Array size ". scalar(@$arf)." does not match ". $s->{colsize}; return;
		} 
		else { my $arfCols=$s->{cols}; push @$arfCols, $arf; }
	}
	sub getNthTuple { #human nth, 
	 my ($s, $nth)=@_;
	 my @aRVtuple=();
	 if($nth > 0 && $nth <= $s->{colsize}) {
		$nth -= 1; #adjust to zero-based nth
		my $colArf=$s->{cols};
		for my $COL (@$colArf) { push @aRVtuple, $COL->[$nth]; }		 
	 }
	 return \@aRVtuple; 
	}
	
	sub getArfOfValTuples {    
	 my $s=shift; 
	 my @rvAry=();
	 for my $idx (0..$s->{colsize}-1) { 
		my @aTuple=();
		my $colArf=$s->{cols};
		for my $COL (@$colArf) { push @aTuple, $COL->[$idx]; }
		push @rvAry, \@aTuple; 
	 }
	 return \@rvAry;
	 
	}

};


#package ordered associative array
package cOrdict {
	sub new { 
		my $class=shift; my @aKeys=(); my %dKeysVals=();
		my $self = { uic=>$class."-".__LINE__."-".time , aKeys=>\@aKeys , dKeysVals=>\%dKeysVals , bDbg=>1 };
		return bless $self, $class;
	}
	sub identify { my $self=shift; say "cOrdict ". $self->{uic};}
	sub addKV { my ($self,$key,$value)=@_; 
		if($self->{bDbg}==1){ say $self->{uic}." addKV $key , $value" ; }
		my $arf=$self->{aKeys}; my $pkcount=scalar(@$arf); push @$arf,$key; 
		if($self->{bDbg}==1){ say $self->{uic}." kcount was $pkcount, now ". scalar(@$arf); }
		
		my $hrf=$self->{dKeysVals}; my $phkcount=scalar(keys %$hrf);
		$hrf->{$key}=$value; 
		if($self->{bDbg}==1){ say $self->{uic}." hkcount was $phkcount, now ". scalar(keys %$hrf); }
		
	}
	sub getVofK { my ($self,$key)=@_; my $hrf=$self->{dKeysVals}; return $hrf->{$key}; }
	sub getKeysArf { my $self=shift; return $self->{aKeys};  }
	sub delKey { my ($self,$keydel)=@_; 
		my $hrf=$self->{dKeysVals}; my $arf=$self->{aKeys};
		my @aNew=();
		if (exists $hrf->{$keydel}){
			for my $k (@$arf) { 
				if($k eq $keydel) {   
					delete $hrf->{$keydel}; 
				}
				else { push @aNew, $k; } 
			}
			$self->{aKeys}=\@aNew;
		}
		else { say __LINE__. " ordAssocArry $hrf->{uic} cannot delete key $keydel . No such key."; }
	}
	sub listKeys { my $self=shift; my $arf=$self->{aKeys}; say $self->{uic}." keys: ". join(" ;; ", @$arf); }
	sub getNthColArf { #return Nth value of all columns (key-arfs); adjust Nth for zero-based array
		my ($self,$nth)=@_; my @aRV=(); my $arfKeys=$self->{aKeys}; my $hrfKcols=$self->{dKeysVals};
		if($self->{bDbg}==1){ say $self->{uic}." getNthCol $nth" ; }
		my @abErrors=();
		if($nth==0){ push @abErrors,"Need a column value greater than zero.";}

		if(scalar(@abErrors)==0){
			my $Nth0B=$nth-1;
			
			for my $aK (@$arfKeys){ #check length for all columns
				my $arfCol=$hrfKcols->{$aK};
				if(scalar(@$arfCol)<$nth){ push @abErrors,"Need a column value greater than zero.";} 
				else { push @aRV, $arfCol->[$Nth0B]; }
			}
		}
		
		if(scalar(@abErrors)>0){ @aRV=(); say "Errors: ". join(" ;; ", @abErrors); }

		return \@aRV;
	}
};

#friendly subroutine interfaces
sub help {
 my @aFuncs=("getColFromFile" , "doSummaryCalcs");	
 say "Use the friendly subroutines to perform basic operations with data.";	
 say "@aFuncs";	
}

sub getColFromFile { #params: colnum, filename // colnum is human ordinal; split on space; excludes #cmt and empty lines

	my ($colnum, $fname)=@_;
	say "Open $fname , return column $colnum"; 
	my $arfdata=openFileRetArf( $fname );
	say "@$arfdata";
	
	my @aVals=();
	for my $L (@$arfdata) { chomp($L); say $L; }

	for my $L (@$arfdata) { 
		chomp($L); if($L=~/^#/ || length($L)==0 ) { next; } 
		my @aParts=split(/\s+/,$L); push @aVals,$aParts[$colnum-1];
	}
	say "Column stored: ".join(" ;; ", @aVals);
	return \@aVals;
}

#some subroutines
sub mksqbracks { my $v=shift; return "[ $v ] " ; }
sub mkDivider { my $val=shift; say "\n". 'x' x 80 . "_$val\n"; }
sub getkbinput { my $msg=shift; say $msg; my $kbStr=<STDIN>;chomp($kbStr); return $kbStr; } 
sub doMsgArf { my $arf=shift; my @ary=@$arf; say mksqbracks($ary[0]). join(" , ",@ary[1..$#ary]);} #where ary[0] is caller __LINE__, for example
sub doArgTest01 { my @ary=@_; unshift @ary, mksqbracks(__LINE__); unshift @ary, "doArgTest01"; doMsgArf(\@ary);}
sub doArgTest02 { 
	my @ary=@_; 
	my @acmts=();
	#if looks_like_number perform a calculation
	#elsif str provide statistics
	for my $el (@ary) {
		if (looks_like_number($el)) { 
			if($el%2==0) { push @acmts, "arg{$el} is even number"; }
			else { push @acmts, "arg{$el} is odd number"; }
		}
		
		else {
			my %dChars=();
			map { $dChars{$_}++ } split(//,$el);
			my @aChars=();
			for my $k (sort keys %dChars) { push @aChars, "$k ($dChars{$k})"; }
			unshift @aChars, join('',sort keys %dChars); 
			push @acmts, "arg{$el} L=". length($el) . " UNQ=" . join(" ;; ", @aChars ); 
		}
	}
	push @ary, "\n";
	push @ary, @acmts; 
	unshift @ary, mksqbracks(__LINE__); unshift @ary, "doArgTest02"; doMsgArf(\@ary);
}
sub gettypeinfo { 
	my $var=shift; 
	if(ref($var)) { say "ref $var of type ". ref($var);  }
	elsif(looks_like_number($var)) { say "$var of type number";  }
	else { say Dumper ($var); } 
}	
sub dec2hex { my $d=shift; return sprintf( "%x" , $d ); }
sub padint { my $i=shift; if ($i<10){ return "  ".$i;} elsif ( $i < 100) { return " ".$i} else {return $i;} }

sub getDayOfWeekNumExYMDarf { # return number of day of week from arf YYYY, MM, DD
 my $bDbg=0;
 my $arfYMD=shift;
 my %dRV=(brvgood=>0,rv=>0);
# sec min hours dd mm yyyy
 my @LT=localtime( timelocal_posix(0,0,0,$arfYMD->[2],$arfYMD->[1]-1,$arfYMD->[0]-1900)) ;
 if($bDbg==1) { say join(" ;; ",@LT); }
 my $rv = $LT[6];
 if($bDbg==1) { say "rv=$rv"; }
 $dRV{brvgood}=1; $dRV{rv}=$rv;
 return \%dRV;
}


sub getNumDaysInYear { # return the number of days in year from YYYY
 my $yyyy=shift;
 my %dRV=(brvgood=>0,rv=>0);
 my $rv = (localtime(timelocal_posix(0,0,0,31,11,$yyyy-1900)) )[7];
 $rv++; #increment zeroth day for count
 $dRV{brvgood}=1; $dRV{rv}=$rv;
 return \%dRV;
}


sub roundXtoYdecimals { my ($f , $dp) = @_; return sprintf("%.".$dp."f", $f); }
sub mathround { my ($n, $p) = @_; return sprintf("%.${p}f", $n);} #arg array: float, precision
sub mathfloor { my $n = shift; return mathGetIntegral($n); }
sub mathceiling { my $n = shift;
	if(mathHasDecimal($n)) {
		if(mathGetFractional($n) > 0) { return mathGetIntegral($n) + 1; }
	}
	return $n;
}
sub mathGetIntegral { my $n = shift; if($n=~/\./) { $n =~ s/\.\d*//;} return  $n ; }
sub mathGetFractional { my $n = shift; if($n=~/\./) { $n =~ s/.*\.//;} return  $n ; }
sub mathHasDecimal { my $n = shift; if($n=~/\./){return 1; } else { return 0;} }
sub computeMinMax { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my @arySrt=sort { $a <=> $b }  (@$r); 
	return  ( $arySrt[0],$arySrt[ $#arySrt  ] );
}

sub computeMedian { #arg is a REFERENCE to an array of numbers; to do: test values from POSIX implementation of ceil and floor
	my $r = shift;  my $c =scalar( @$r);
	my @as = sort { $a <=> $b } @$r;
	my $rv = -1;

#	if($c % 2) { my $iv = floor($c/2) + 1 ; return $as[$iv];} #odd range
	#handle case of all values being the same
	my %kvariance=();
	$kvariance{$_}++ for (@as);

	if ( scalar ( keys %kvariance) == 1) { my @arKys= keys %kvariance; $rv = $arKys[0]; }
	elsif($c % 2) { my $iv = mathfloor($c/2) + 1 ; $rv =  $as[$iv];} #odd range
#	else { my $n1 = $as[floor($c/2)] + $as[ceil($c/2)]; return ($n1/2); } #even range
	else { my $n1 = $as[mathfloor($c/2)] + $as[mathceiling($c/2)]; $rv =  ($n1/2); } #even range
	return $rv;
}
sub computeSum { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my $t=0;
	for my $val (@$r){ $t += $val }; #assume valid numbers
	return $t;
}
sub computeMean { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my $t=computeSum($r);
	return $t/scalar(@$r);
}

sub computeStnDev { #arg is a REFERENCE to an array of numbers;
	my $r = shift;
	my $m=computeMean($r);
	my @aSqV=();
	for my $inval (@$r) { my $d=$inval-$m; push @aSqV,$d*$d; }
	$m = computeMean(\@aSqV);
	return sqrt($m);
}

###do integers differ by At Least One Order Of Magnitude
sub isXgtYbyALOOM {
	my ($x,$y)=@_;
	return 0 if ($x <= $y);
	return 1 if ($x/$y >= 10);
	return 0 if ( $x-$y < $y);
	return 1 ;
}
sub FOOMFOI{ #Find Orders Of Magnitude From Ordered Integers
	my $aR = shift;
	my @a = @$aR;
	my @rv=();
	for (my $i=0; $i<= $#a-1; $i++) {
		if ( isXgtYbyALOOM( $a[$i] , $a[$i+1]) ) { push @rv , $i; }
	}
	say "@rv";
	return \@rv;
}

sub computeFrequency {
	my $bDbg=1;
	my $arf = shift;
	my %rvH=();
	my %freqH=();
	for my $i (@$arf) {
		if (exists $freqH{$i}) { $freqH{$i}++; }
		else { $freqH{$i} = 1; }
	}
	say "@$arf";
	#determine output order
	my $orderMode=0; 
	my @minmax=computeMinMax( [ values %freqH ] ); 
	if( $minmax[0] == $minmax[1] ) { $orderMode=1; } #use original order
	
	my @orderedKeys=();
	my @aSrtVals= reverse uniq sort { $a<=>$b } values %freqH; #note uniq sort 
	
	if($bDbg==1){ say "@aSrtVals";}
	
	for my $Val (@aSrtVals){ 
		for my $vorig (uniq @$arf) { #note uniq
		 if ($freqH{$vorig}==$Val) { push @orderedKeys, $vorig; }				
		}
	}
	
	$rvH{akorder}=\@orderedKeys;
	if ($orderMode==1) { $rvH{akorder}=$arf; }
	
	$rvH{hdata}=\%freqH;

	return \%rvH;
}

sub doSummaryCalcs {
	
		my ($arfNums,$taskdesc)=@_;
		mkDivider(mksqbracks(__LINE__));
		say mksqbracks(__LINE__). " begin $taskdesc array size ". scalar(@$arfNums) ;
		my $hResponse = computeFrequency($arfNums);
		my $hData = $hResponse->{hdata};
		for my $k ( @{$hResponse->{akorder}} ){
			say "count $k = freq $hData->{$k}"
		}
		
 		mkDivider(mksqbracks(__LINE__));
 		say "sum _ ". computeSum($arfNums) ." = ". join(" + ",@$arfNums) ;
		my @amnmx=computeMinMax( [  keys %$hData ] );

		say "minmax _ ". join( " ;; ", @amnmx);	
		say "mean _ ". computeMean([ keys %$hData ]);
		say "median _ ". computeMedian([ keys %$hData ]);
		say "standev _ " . computeStnDev([ keys %$hData ]);		

		say mksqbracks(__LINE__) . " end $taskdesc array size ". scalar(@$arfNums);
		mkDivider(mksqbracks(__LINE__));
		return $hResponse;
	
}	


sub openFileRetArf { my $f=shift; my @ary=(); 
	if(! -e $f) { unshift @ary, mksqbracks(__LINE__); unshift @ary, "File $f not found."; doMsgArf(\@ary);}
	else { open( my $SF, "<", $f ); @ary=<$SF>; close($SF); 
	 chomp(@ary);
	 say "Read \"$f\" , line count ". scalar(@ary); 
	 say "Tip: next you might: for my \$L (\@\$arf) { say \$L; }";
	 return \@ary; 
	}
}

sub listDATA {
	my $data_start = tell DATA;
	while (my $inline=<DATA>) { 
		chomp($inline); next if not length $inline;  

		if ($inline =~ /^#/) { say "Comment: $inline" ; }
		else {
			  my @aLwhspc=();
			  @aLwhspc=split(/\s+/,$inline); 
			  my @aLcomma=();
			  @aLcomma=split(/,/,$inline); 			  
#			  say __LINE__." $inline __ has ". scalar(@aLwhspc) ." pieces split on spaces, ". scalar(@aLcomma) ." pieces split on commas.";
			  say "Listing: $inline __ has ". scalar(@aLwhspc) ." pieces split on spaces, ". scalar(@aLcomma) ." pieces split on commas.";

		}
	}
	seek DATA, $data_start, 0;
}
sub readDATA { #param01: split on space "0" or split on comma "1" ;; param02: 2=rv No ARF , 3=rv yield ARF
	my $data_start = tell DATA;
	my @args=@_;

	my $modesplt=0;
	my $moderv=0;
	my @aRV=();
	my %dRVSet=();
	$dRVSet{arf}=\@aRV;
	$dRVSet{arfsz}=0;

	if(scalar(@args)){ say "Args for processing __DATA__ : ". join(" ;; ", @args); }
	for my $arg (@args){
		if ($arg < 2) { if($arg == 1){ $modesplt=$arg; } } 
		elsif($arg==2 || $arg==3){ if($arg == 3){ $moderv=$arg; } }
	}

	
	while (my $inline=<DATA>) { 
		chomp($inline); next if not length $inline;  


		if ($inline =~ /^#/) { say "Comment: $inline" ; }
		else {
			  my @aL=();
			  if($modesplt==0) { @aL=split(/\s+/,$inline); }
			  elsif($modesplt==1) { @aL=split(/,/,$inline); }			  
#			  say __LINE__." $inline __ has ". scalar(@aL) ." pieces, mode=$modesplt";
			  say "Reading: $inline __ has ". scalar(@aL) ." pieces, mode=$modesplt";
			  
			  if( $moderv==3 ){ push @aRV, \@aL; }
			
		}
	}
	seek DATA, $data_start, 0;
	$dRVSet{arfsz}=scalar(@aRV);
	return \%dRVSet;
}


sub sortAsVersInt { #versint is 2020.01.30 or 2020.2021.2022 &c
 my $bDbg=1;
 my ( $lside, $rside ) = @_;
 if($bDbg){ say mksqbracks(__LINE__). " cmp $lside // $rside"; }
 
 my @aryMsgs=();
 my %dData= ( rvint=>0, lspcs=>0, rspcs=>0, arfmsgs=>\@aryMsgs );

 my @lpcs=split(/\./,$lside); 
 my @rpcs=split(/\./,$rside);
 $dData{lspcs}=scalar(@lpcs); $dData{rspcs}=scalar(@rpcs);
 if($bDbg){ say mksqbracks(__LINE__). " cmp $dData{lspcs} // $dData{rspcs}"; }
 
 
 if($bDbg){ 
  say mksqbracks(__LINE__). "dump array values:"; 
  say "L ary = " . $dData{lspcs}; say join(" ;; ", @lpcs); 
  say "R ary = " . $dData{rspcs}; say join(" ;; ", @rpcs); 
  }
 
 
 if( $dData{lspcs} == $dData{rspcs} ) {
  if($bDbg){ say mksqbracks(__LINE__). " cmp equal sizes"; }
  for (my $i=0; $i<=$#lpcs; $i++) {
   if($lpcs[$i] < $rpcs[$i]) { $dData{rvint}=-1; last; }
   elsif($lpcs[$i] > $rpcs[$i]) { $dData{rvint}=1; last; }
  } # close for loop

  if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }
 }# close if test

 elsif ( $dData{lspcs} > $dData{rspcs} ) {
	 if($bDbg){ say mksqbracks(__LINE__). " cmp L > R"; }
  for (my $i=0; $i<=$#rpcs; $i++) { # test up to end of rpcs
   if($lpcs[$i] < $rpcs[$i]) { $dData{rvint}=-1; last; }
   elsif($lpcs[$i] > $rpcs[$i]) { $dData{rvint}=1; last; }
  }#close for loop
 #test remaining values of lpcs IFF rvint==0
  if($dData{rvint}==0) { for(my $i=scalar(@rpcs);$i<=$#lpcs;$i++){ if($lpcs[$i] > 0){$dData{rvint}=1; last;} } }
  if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }
 }#close elsif

 elsif ( $dData{lspcs} < $dData{rspcs} ) {
	 if($bDbg){ say mksqbracks(__LINE__). " cmp L < R"; }
  for (my $i=0; $i<=$#lpcs; $i++) { # test up to end of lpcs
   if($lpcs[$i] < $rpcs[$i]) { $dData{rvint}=-1; last; }
   elsif($lpcs[$i] > $rpcs[$i]) { $dData{rvint}=1; last; }
  }#close for loop
#test remaining values of rpcs IFF rvint==0
 if($dData{rvint}==0) { for(my $i=scalar(@lpcs);$i<=$#rpcs;$i++){ if($rpcs[$i] > 0){$dData{rvint}=1; last;} } }
 if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }

 }#close elsif
 
 if($bDbg){ say mksqbracks(__LINE__). "rv = $dData{rvint} , $lside , $rside"; }
 return $dData{rvint}; #return the int decision required by sort
}##

